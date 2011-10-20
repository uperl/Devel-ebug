#!perl
use strict;
use warnings;
use lib 'lib';
use Test::More tests => 11;
use Devel::ebug;

my $ebug = Devel::ebug->new;
$ebug->program("t/calc.pl");
$ebug->load;

# Let's get some lines of code

my @codelines = $ebug->codelines();
is_deeply(\@codelines, [
  '#!perl',
  '',
  'my $q = 1;',
  'my $w = 2;',
  'my $e = add($q, $w);',
  '$e++;',
  '$e++;',
  '',
  'print "$e\\n";',
  '',
  'sub add {',
  '  my($z, $x) = @_;',
  '  my $c = $z + $x;',
  '  return $c;',
  '}',
  '',
  '# unbreakable line',
  'my $breakable_line = 1;',
  '# other unbreakable line',
]);

@codelines = $ebug->codelines(1, 3, 4, 5);
is_deeply(\@codelines, [
  '#!perl',
  'my $q = 1;',
  'my $w = 2;',
  'my $e = add($q, $w);',
]);

$ebug = Devel::ebug->new;
$ebug->program("t/calc_oo.pl");
$ebug->load;
@codelines = $ebug->codelines("t/calc_oo.pl", 7, 8);
is_deeply(\@codelines, [
  'my $calc = Calc->new;',
  'my $r = $calc->add(5, 10); # 15',
]);

@codelines = $ebug->codelines("t/Calc.pm", 5, 6);
is_deeply(\@codelines, [
  'use base qw(Class::Accessor::Chained::Fast);',
  'our $VERSION = "0.29";',
]);

@codelines = $ebug->codelines("t/Calc.pm");
is(scalar(@codelines), 34);

$ebug->program("t/pod.pl");
$ebug->load;
@codelines = $ebug->codelines();
is($codelines[0], '#!perl');
is($codelines[8], 'print "Result is $zz!\n";');
is($codelines[9], '');
is($codelines[10], '');
is($codelines[11], '');
is($codelines[31], 'sub add {');
