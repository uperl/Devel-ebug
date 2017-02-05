package Devel::ebug::Server;

use strict;
use warnings;
use base qw(Devel::ebug);

__PACKAGE__->mk_accessors(qw(port key));

use IO::Socket::INET;

sub load {
  my $self    = shift;
  my $program = $self->program;

  $self->load_plugins;

  # listen on the given port
  my $server = IO::Socket::INET->new(
    Listen    => 5,
    LocalAddr => 'localhost',
    LocalPort => $self->port,
    Proto     => 'tcp',
    ReuseAddr => 1,
    Reuse     => 1,
    )
    || die $!;
  $self->socket(scalar $server->accept);
  $self->post_connect($self->key);
}

1;
