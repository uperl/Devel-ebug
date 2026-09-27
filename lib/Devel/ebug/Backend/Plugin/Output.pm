package Devel::ebug::Backend::Plugin::Output;

use strict;
use warnings;

# VERSION

my $stdout = "";
my $stderr = "";

# Capture the program's output so the frontend can show it.  Under
# PERL_DEBUG_DONT_RELAY_IO (ebug_server -keepio) STDOUT and STDERR are
# deliberately left going wherever they were going, so that a program
# which prompts can still be used interactively; output then has nothing
# to report.
unless ($ENV{PERL_DEBUG_DONT_RELAY_IO}) {
  close STDOUT;
  open STDOUT, '>', \$stdout or die "Can't open STDOUT: $!";
  close STDERR;
  open STDERR, '>', \$stderr or die "Can't open STDERR: $!";
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
