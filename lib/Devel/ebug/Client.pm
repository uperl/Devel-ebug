package Devel::ebug::Client;

use strict;
use warnings;
use base qw(Devel::ebug);

__PACKAGE__->mk_accessors(qw(port key));

use IO::Socket::INET;

sub load {
  my $self    = shift;
  my $program = $self->program;

  $self->load_plugins;

  # try and connect to the server
  my $socket;
  foreach ( 1 .. 10 ) {
    $socket = IO::Socket::INET->new(
      PeerAddr   => "localhost",
      PeerPort   => $self->port,
      Proto      => 'tcp',
      Reuse      => 1,
      ReuserAddr => 1,
    );
    last if $socket;
    sleep 1;
  }
  die "Could not connect: $!" unless $socket;
  $self->socket($socket);

  $self->post_connect($self->key);
}

1;
