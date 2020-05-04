package Devel::ebug::Plugin::Eval;

use strict;
use warnings;
use base qw(Exporter);
our @EXPORT = qw(eval yaml);

# VERSION

# eval
sub eval {
  my($self, $eval) = @_;
  my $response = $self->talk({
    command => "eval",
    eval    => $eval,
  });
  return wantarray ? ( $response->{eval}, $response->{exception} ) :  ##  no critic (Freenode::Wantarray)
                     $response->{eval};
}

# yaml
sub yaml {
  my($self, $yaml) = @_;
  my $response = $self->talk({
    command => "yaml",
    yaml    => $yaml,
  });
  return $response->{yaml};
}

1;
