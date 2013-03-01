#!perl
use strict;
use warnings;
use lib 'lib';
use Test::More tests => 3;
use Devel::ebug;

my $ebug = Devel::ebug->new;
$ebug->program("t/load_calc.pl");
$ebug->backend("$^X bin/ebug_backend_perl");
$ebug->load;

$ebug->break_on_load("t/Calc.pm");

$ebug->run;
is($ebug->line, 6);
is($ebug->filename, "t/Calc.pm");

$ebug->run;
is($ebug->finished, 1);

