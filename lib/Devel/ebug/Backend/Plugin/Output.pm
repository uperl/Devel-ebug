package Devel::ebug::Backend::Plugin::Output;

use strict;
use warnings;

# VERSION

my $stdout = "";
my $stderr = "";

if ($ENV{PERL_DEBUG_DONT_RELAY_IO}) {
  # TODO: can we change these to non-bareword file handles
  open NULL, '>', '/dev/null';  ## no critic
  open NULL, '>', \$stdout;     ## no critic
  open NULL, '>', \$stderr;     ## no critic
}
else {
  close STDOUT;
  open STDOUT, '>', \$stdout or die "Can't open STDOUT: $!";
  close STDERR;
  open STDERR, '>', \$stderr or die "Can't open STDOUT: $!";
}

sub register_commands {
  return (output => { sub => \&output });
}

sub output {
  my($req, $context) = @_;
  return {
    stdout => $stdout,
    stderr => $stderr,
  };
}

1;
