#!perl
use strict;
use warnings;
use lib 'lib';
use Devel::ebug;
use Test::More;

eval "use Test::Expect";
plan skip_all => "Test::Expect required for testing ebug: $@" if $@;
eval "use Expect::Simple";
plan skip_all => "Expect::Simple required for testing ebug: $@" if $@;
plan tests => 15;

expect_run(
  command => "PERL_RL=\"o=0\" $^X ebug t/calc.pl",
  prompt  => 'ebug: ',
  quit    => 'q',
);

my $version = $Devel::ebug::VERSION;

expect_like(qr/Welcome to Devel::ebug $version/);
expect_like(qr{main\(t/calc.pl#3\):\nmy \$q = 1;});
expect("h", 'Commands:

      b Set break point at a line number (eg: b 6, b code.pl 6, b code.pl 6 $x > 7,
      b Calc::fib)
      d Delete a break point (d 6, d code.pl 6)
      e Eval Perl code and print the result (eg: e $x+$y)
      f Show all the filenames loaded
      l List codelines or set number of codelines to list (eg: l, l 20)
      L List codelines always (toggle)
      n Next (steps over subroutine calls)
      o Output (show STDOUT, STDERR)
      p Show pad
      r Run until next break point or watch point
    ret Return from subroutine  (eg: ret, ret 3.141)
restart Restart the program
      s Step (steps into subroutine calls)
      T Show a stack trace
      u Undo (eg: u, u 4)
      w Set a watchpoint (eg: w $t > 10)
      x Dump a variable using YAML (eg: x $object)
      q Quit
main(t/calc.pl#3):
my $q = 1;');

expect("b 9", "main(t/calc.pl#3):\nmy \$q = 1;");
expect("s", "main(t/calc.pl#4):\nmy \$w = 2;");
expect("", "main(t/calc.pl#5):\nmy \$e = add(\$q, \$w);");
expect("n", "main(t/calc.pl#6):\n\$e++;");
expect("r", qq{main(t/calc.pl#9):\nprint "\$e\\n";});

