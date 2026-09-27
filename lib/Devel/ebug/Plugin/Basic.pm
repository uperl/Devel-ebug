package Devel::ebug::Plugin::Basic;

use strict;
use warnings;
use base qw(Exporter);
our @EXPORT = qw(basic);

# VERSION

# get basic debugging information
sub basic {
  my ($self) = @_;
  _basic_response($self, $self->talk({ command => "basic" }));
}

# record where the debuggee is, from the answer to a basic request
sub _basic_response {
  my ($self, $response) = @_;
  $self->codeline($response->{codeline});
  $self->filename($response->{filename});
  $self->finished($response->{finished});
  $self->line($response->{line});
  $self->package($response->{package});
  $self->subroutine($response->{subroutine});
}

1;
