package Devel::ebug::Backend;

use strict;
use warnings;

# VERSION

package DB;

use IO::Socket::INET;
use String::Koremutake;
use YAML;
use Module::Pluggable
  search_path => 'Devel::ebug::Backend::Plugin',
  require     => 1;

use vars qw(@dbline %dbline);

# VERSION

# Let's catch INT signals and set a flag when they occur
$SIG{INT} = sub {
  $DB::signal = 1;
  return;
};

my $context = {
  finished     => 0,
  initialise   => 1,
  mode         => "step",
  stack        => [],
  watch_points => [],
};


# Commands that the back end can respond to
# Set record if the command changes start and should thus be recorded
# in order for undo to work properly
my %commands = ();

sub DB {
  my ($package, $filename, $line) = caller;
  ($context->{package}, $context->{filename}, $context->{line}) =
    ($package, $filename, $line);

  initialise() if $context->{initialise};

  # we're here because of a signal, reset the flag
  if ($DB::signal) {
    $DB::signal = 0;
  }

  # single step
  my $old_single = $DB::single;
  $DB::single = 1;

  if (@{ $context->{watch_points} }) {
    my %delete;
    foreach my $watch_point (@{ $context->{watch_points} }) {
      local $SIG{__WARN__} = sub { };
      my $v = eval "package $package; $watch_point";  ## no critic (BuiltinFunctions::ProhibitStringyEval)
      if ($v) {
        $context->{watch_single} = 1;
        $delete{$watch_point} = 1;
      }
    }
    if ($context->{watch_single} == 0) {
      return;
    } else {
      @{ $context->{watch_points} } =
        grep { !$delete{$_} } @{ $context->{watch_points} };
    }
  }

  # we're here because of a break point, test the condition
  if ($old_single == 0) {
    my $condition = break_point_condition($filename, $line);
    if ($condition) {
      local $SIG{__WARN__} = sub { };
      my $v = eval "package $package; $condition";  ## no critic (BuiltinFunctions::ProhibitStringyEval)
      unless ($v) {
        # condition not true, go back to running
        $DB::single = 0;
        return;
      }
    }
  }

  $context->{watch_single} = 1;
  $context->{codeline} = (fetch_codelines($filename, $line - 1))[0];
  chomp $context->{codeline};

  while (1) {
    my $req     = get();
    my $command = $req->{command};

    my $sub = $commands{$command}->{sub};
    if (defined $sub) {
      put($sub->($req, $context));

      if ($context->{last}) {
        delete $context->{last};
        last;
      }
    } else {
      die "unknown command $command";
    }
  }
}

sub initialise {
  my $k      = String::Koremutake->new;
  my $int    = $k->koremutake_to_integer($ENV{SECRET});
  my $port   = 3141 + ($int % 1024);
  my $server = IO::Socket::INET->new(
    Listen    => 5,
    LocalAddr => 'localhost',
    LocalPort => $port,
    Proto     => 'tcp',
    ReuseAddr => 1,
    Reuse     => 1,
    )
    || die $!;
  $context->{socket} = $server->accept;

  foreach my $plugin (__PACKAGE__->plugins) {
    my $sub = $plugin->can("register_commands");
    next unless $sub;
    my %new = &$sub;
    foreach my $command (keys %new) {
      $commands{$command} = $new{$command};
    }
  }

  $context->{initialise} = 0;
}

sub put {
  my ($res) = @_;
  my $data = unpack("h*", Dump($res));
  local $\; # if we run under perl -l the following line would get mangled
  $context->{socket}->print($data . "\n");
}

sub get {
  exit unless $context->{socket};
  local $/= "\n";
  my $data = $context->{socket}->getline;
  my $req = do {
    local $YAML::LoadBlessed = 1;
    Load(pack("h*", $data));
  };
  push @{ $context->{history} }, $req
    if exists $commands{ $req->{command} }->{record};
  return $req;
}

sub sub {
  my $sub = $DB::sub;
  my $frame = { single => $DB::single, sub => $sub };
  push @{ $context->{stack} }, $frame;

  my $wantarray = wantarray; ## no critic (Community::Wantarray)
  my(@ret, $ret);
  no strict 'refs';
  if (defined $context->{mode} && $context->{mode} eq 'next') {
    # If we are in 'next' mode, skip all the lines in the sub - but
    # guarantee $DB::single is put back no matter how &$sub exits,
    # including via an exception that gets caught further up the
    # debuggee's own call stack (eg. Tk widgets routinely wrap
    # internal calls in eval {} blocks for feature detection). Without
    # this, such an exception would skip the explicit restore below,
    # leaving $DB::single stuck at 0 and next/step permanently unable
    # to regain control of the debuggee (it just runs to completion,
    # or hangs forever if that includes something like Tk's MainLoop).
    #
    # This can't be done by wrapping &$sub in eval {} (that confuses
    # perl's own sub-call tracing and breaks single-stepping outright)
    # or with a DESTROY-based guard object (constructing the guard is
    # itself a traced sub call, which recurses infinitely). `local` is
    # a builtin, so neither pitfall applies - and it cleanly falls
    # back to $frame->{single} in the exception case above, rather
    # than leaving next/step stuck.
    local $DB::single = 0;
    if ($wantarray) { @ret = &$sub; } else { $ret = &$sub; }
  } else {
    if ($wantarray) { @ret = &$sub; } else { $ret = &$sub; }
  }

  # Only reached if &$sub returned normally. In the 'next' branch
  # above, $DB::single has already been restored to $frame->{single}
  # by `local`, but other modes (eg. 'return') still rely on this
  # explicit restore.
  #
  # We restore from $frame (our own lexical) rather than whatever pop
  # returns, and check $frame->{'return'} the same way. $frame is the
  # exact object that was pushed, so this is correct even if
  # $context->{stack} has become misaligned by an earlier exception
  # elsewhere skipping its own cleanup (see above) - a stray pop here
  # would otherwise read a stale, unrelated frame and corrupt
  # $DB::single for callers further up the stack too.
  pop @{ $context->{stack} };
  $DB::single = $frame->{single};
  $DB::single = 0 if defined $context->{mode} && $context->{mode} eq 'run' && !@{$context->{watch_points}};

  if ($wantarray) {
    return $frame->{'return'} ? @{ $frame->{'return'} } : @ret;
  } else {
    return $frame->{'return'} ? $frame->{'return'}->[0] : $ret;
  }
}

sub DB::postponed {
    # If this is a subroutine, let postponed_sub() deal with it.
    goto &postponed_sub unless ref \$_[0] eq 'GLOB';

    my ($filePath) = @_;
    $filePath =~ s/^.*_<//;

    my ($volume,$directories,$fileName) = File::Spec->splitpath( $filePath );

    #test if the file name match with relative path/absolute path/single file name
    if (exists $DB::break_on_load{$filePath}
        || exists $DB::break_on_load{File::Spec->rel2abs( $filePath)}
        || exists $DB::break_on_load{$fileName}){
        $DB::single = 1;
    }

}


sub fetch_codelines {
  my ($filename, @lines) = @_;

  #use vars qw(@dbline %dbline);
  *dbline = $main::{ '_<' . $filename };
  my @codelines = @dbline;

  # for modules, not sure why
  shift @codelines if not defined $codelines[0];

  # defined!
  @codelines = map { defined($_) ? $_ : "" } @codelines;

  # remove newlines
  s/\s+$// for @codelines;

  # we run it with -d:ebug::Backend, so remove this extra line
  @codelines = grep { $_ ne 'use Devel::ebug::Backend;' } @codelines;

  # for some reasons, the perl internals leave the opening POD line
  # around but strip the rest. so let's strip the opening POD line
  @codelines =
    map { /^=(head|over|item|back|over|cut|pod|begin|end|for)/ ? "" : $_ }
    @codelines;

  if (@lines) {
    @codelines = @codelines[@lines];
  }
  return @codelines;
}

sub break_point_condition {
  my ($filename, $line) = @_;
  *dbline = $main::{ '_<' . $filename };
  return $dbline{$line};
}

sub END {
  $context->{finished} = 1;
  $DB::single = 1;
  DB::fake::at_exit();
}

package
  DB::fake;

sub at_exit {
  1;
}

package DB;    # Do not trace this 1; below!

1;

