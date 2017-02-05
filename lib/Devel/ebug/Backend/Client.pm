package Devel::ebug::Backend::Client;

use strict;
use warnings;

use IO::Socket::INET;

my $global_context;

package DB;

# to detach the attached debugger
sub Devel::ebug::Backend::Client::close {
  $global_context->{mode} = 'unattached';
  $global_context->{finished} = 1;
  close $global_context->{socket};
  delete $global_context->{socket};
  $DB::single = 0;
}

# start running in unattached mode
sub Devel::ebug::Backend::Client::start {
  $global_context->{mode} = 'unattached';
  $global_context->{finished} = 0;
  $DB::single = 0;
}

# connect to the debugger adn go to step mode
sub Devel::ebug::Backend::Client::trap {
  if( !$global_context->{socket} ) {
    # try and connect to the server
    my $k      = String::Koremutake->new;
    my $int    = $k->koremutake_to_integer($ENV{SECRET});
    my $port   = 3141 + ($int % 1024);
    my $socket = IO::Socket::INET->new(
      PeerAddr => "localhost",
      PeerPort => $port,
      Proto    => 'tcp',
      Reuse      => 1,
      ReuserAddr => 1,
    );
    die unless $socket;
    $global_context->{socket} = $socket;
  }
  $global_context->{mode} = 'step';
  $DB::single = 1;
  $_->{single} = 1 foreach @{$global_context->{stack}};
}

use Devel::ebug::Backend;

package DB;

use strict;
use warnings;

# bad hack, but debugging is a dirty work
sub Devel::ebug::Backend::Client::initialise {
  my ($context) = @_;

  $global_context = $context;
  load_plugins();

  $context->{mode} = "unattached";
  $context->{initialise} = 0;
}

no warnings 'redefine';
*DB::initialise = \&Devel::ebug::Backend::Client::initialise;

1;
