#!perl
use strict;
use warnings;
use lib 'lib';
use Test::More tests => 29;
use Devel::ebug;

my $ebug = Devel::ebug->new;
$ebug->program("t/calc.pl");
$ebug->load;

my @trace = $ebug->stack_trace;
is(scalar(@trace), 0);
$ebug->break_point(12);

$ebug->run;
@trace = $ebug->stack_trace;
is(scalar(@trace), 1);

# use YAML; warn Dump \@trace;

my $trace = $trace[0];
is($trace->package   , "main");
is($trace->filename  , "t/calc.pl");
is($trace->subroutine, "main::add");
is($trace->wantarray , 0);
is($trace->line      , 5);
is_deeply([$trace->args], [1, 2]);

@trace = $ebug->stack_trace_human;
is(scalar(@trace), 1);
is($trace[0], 'add(1, 2)');

$ebug = Devel::ebug->new;
$ebug->program("t/calc_oo.pl");
$ebug->load;
$ebug->break_point("t/Calc.pm", 19);

$ebug->run;
@trace = $ebug->stack_trace_human;
is(scalar(@trace), 1);
is($trace[0], '$calc->fib1(15)');

$ebug->run;
@trace = $ebug->stack_trace_human;
is(scalar(@trace), 2);
is($trace[1], '$calc->fib1(15)');
is($trace[0], '$self->fib1(14)');

$ebug = Devel::ebug->new;
$ebug->program("t/koremutake.pl");
$ebug->load;

$ebug->step;
@trace = $ebug->stack_trace_human;
is(scalar(@trace), 1);
is($trace[0], 'String::Koremutake->new()');

$ebug = Devel::ebug->new;
$ebug->program("t/koremutake.pl");
$ebug->load;
$ebug->break_point_subroutine("String::Koremutake::integer_to_koremutake");

$ebug->run;
@trace = $ebug->stack_trace_human;
is(scalar(@trace), 1);
is($trace[0], '$koremutake->integer_to_koremutake(65535)');

$ebug = Devel::ebug->new;
$ebug->program("t/stack.pl");
$ebug->load;
$ebug->break_point_subroutine("main::show");

$ebug->run;
@trace = $ebug->stack_trace_human;
is(scalar(@trace), 1);
is($trace[0], 'show()');

$ebug->run;
@trace = $ebug->stack_trace_human;
is($trace[0], 'show(1, undef, 2)');

$ebug->run;
@trace = $ebug->stack_trace_human;
is($trace[0], 'show(123)');

$ebug->run;
@trace = $ebug->stack_trace_human;
is($trace[0], 'show(-0.3)');

$ebug->run;
@trace = $ebug->stack_trace_human;
is($trace[0], "show('a')");

$ebug->run;
@trace = $ebug->stack_trace_human;
is($trace[0], 'show("orange o rama")');

$ebug->run;
@trace = $ebug->stack_trace_human;
is($trace[0], 'show([...])');

$ebug->run;
@trace = $ebug->stack_trace_human;
is($trace[0], 'show({...})');

$ebug->run;
@trace = $ebug->stack_trace_human;
is($trace[0], 'show($koremutake)');

# use YAML; warn Dump \@trace;


