package Devel::ebug::Backend::Plugin::Run;

use strict;
use warnings;

sub register_commands {
    return (
      next        => { sub => \&next, record => 1 },
      prev        => { sub => \&prev, record => 1 },
      return      => { sub => \&return, record => 1 },
      run         => { sub => \&run, record => 1 },
      step        => { sub => \&step, record => 1 },
    );
}

sub dlog {
  open my $log, '>>', 'debugger.log';
  print $log time() . " " . join("\n", @_) . "\n";
}

my @previous_pid;
sub next {
  my($req, $context) = @_;
  dlog("ME $$: Here we are in next.");
  # if($previous_pid) {
    # dlog("ME $$: I found a previous pid $previous_pid! Killing.");
    # kill 9, $previous_pid;
  # }
  dlog("ME $$: FORK TIME");
  my $pid = fork();
  if($pid) {
    # we are parent
    dlog("PARENT $$: saving child pid $pid");
    push @previous_pid, $pid;
    $context->{mode} = "next"; # single step (but over subroutines)
    $context->{last} = 1;      # and out of the loop
  } else {
    # we are child
    dlog("CHILD $$: suspending");
    kill 19, $$;
    dlog("CHILD $$: resumed!");
    # undef $previous_pid;
  }

  return {};
}

sub prev {
  my($req, $context) = @_;
  dlog("ME $$: Thinking about time travel...");
  if(@previous_pid) {
    my $previous_pid = pop @previous_pid;
    dlog("ME $$: I found a previous pid $previous_pid! TIME TRAVEL TIME");
    kill 18, $previous_pid;
    dlog("ME $$: If you meet your previous self, kill yourself.");
    kill 9, $$;
  }
  dlog("ME $$: I was unable to time travel (no previous_pid)");
  return {};
}

sub return {
  my($req, $context) = @_;
  if ($req->{values}) {
    $context->{stack}->[0]->{return} = $req->{values};
  }
  $context->{mode} = "return"; # run until returned from subroutine
  $DB::single = 0; # run
  if ($context->{stack}->[-1]) {
    $context->{stack}->[-1]->{single} = 1; # single step higher up
  }
  $context->{last} = 1;      # and out of the loop
  return {};
}

sub run {
  my($req, $context) = @_;
  $context->{mode} = "run"; # run until break point
  if (@{$context->{watch_points}}) {
    # watch points, let's go slow
    $context->{watch_single} = 0;
  } else {
    # no watch points? let's go fast!
    $DB::single = 0; # run until next break point
  }
  $context->{last} = 1;      # and out of the loop
  return {};
}


sub step {
  my($req, $context) = @_;
  $DB::single = 1;           # single step
  $context->{mode} = "step"; # single step (into subroutines)
  $context->{last} = 1;      # and out of the loop, onto the next command
  return {};
}


1;
