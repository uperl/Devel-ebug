package Devel::ebug::Plugin::Run;

use strict;
use warnings;
use base qw(Exporter);
our @EXPORT = qw(undo run run_nowait wait_for_stop interrupt return step next);

use Carp qw(croak);
use Devel::ebug::Plugin::Basic ();

# VERSION

# undo
sub undo {
  my($self, $levels) = @_;
  $levels ||= 1;
  my $response = $self->talk({ command => "commands" });
  my @commands = @{$response->{commands}};
  pop @commands foreach 1..$levels;
#  use YAML; warn Dump \@commands;
  my $proc = $self->proc;
  $proc->die;
  $self->load;
  $self->talk($_) foreach @commands;
  $self->basic;
}



# run until a breakpoint
sub run {
  my($self) = @_;
  $self->run_nowait;
  $self->wait_for_stop;
}

# start running, without waiting for the program to stop
sub run_nowait {
  my($self) = @_;
  $self->talk({ command => "run" });
  # The backend reads this once it stops again, so the socket becomes
  # readable exactly when the program has stopped.
  $self->_send({ command => "basic" });
  $self->running(1);
  return $self;
}

# wait for a program started with run_nowait to stop
sub wait_for_stop {
  my($self) = @_;
  return $self unless $self->running;
  my $response = $self->_receive;
  $self->running(0);
  Devel::ebug::Plugin::Basic::_basic_response($self, $response);
  return $self;
}

# ask a running program to stop at the next statement
sub interrupt {
  my($self) = @_;
  return 0 unless $self->running;
  croak "interrupt is not supported on $^O" if $^O eq 'MSWin32';
  croak "interrupt is only supported for programs started with load()"
    unless $self->proc;
  croak "the debugger did not report the program's process id"
    unless $self->pid;
  return kill(INT => $self->pid) ? 1 : 0;
}


# return from a subroutine
sub return {
  my($self, @values) = @_;
  my $values;
  $values = \@values if @values;
  my $response = $self->talk({
    command => "return",
    values  => $values,
 });
  $self->basic; # get basic information for the new line
}



# step onto the next line (going into subroutines)
sub step {
  my($self) = @_;
  my $response = $self->talk({ command => "step" });
  $self->basic; # get basic information for the new line
}

# step onto the next line (going over subroutines)
sub next {
  my($self) = @_;
  my $response = $self->talk({ command => "next" });
  $self->basic; # get basic information for the new line
}

1;
