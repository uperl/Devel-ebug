# Devel::ebug ![linux](https://github.com/uperl/Devel-ebug/workflows/linux/badge.svg) ![macos](https://github.com/uperl/Devel-ebug/workflows/macos/badge.svg)

A simple, extensible Perl debugger

# SYNOPSIS

```perl
 use Devel::ebug;
 my $ebug = Devel::ebug->new;
 $ebug->program("calc.pl");
 $ebug->load;

 print "At line: "       . $ebug->line       . "\n";
 print "In subroutine: " . $ebug->subroutine . "\n";
 print "In package: "    . $ebug->package    . "\n";
 print "In filename: "   . $ebug->filename   . "\n";
 print "Code: "          . $ebug->codeline   . "\n";
 $ebug->step;
 $ebug->step;
 $ebug->next;
 my($stdout, $stderr) = $ebug->output;
 my $actual_line = $ebug->break_point(6);
 $ebug->break_point(6, '$e == 4');
 $ebug->break_point("t/Calc.pm", 29);
 $ebug->break_point("t/Calc.pm", 29, '$i == 2');
 $ebug->break_on_load("t/Calc.pm");
 my $actual_line = $ebug->break_point_subroutine("main::add");
 $ebug->break_point_delete(29);
 $ebug->break_point_delete("t/Calc.pm", 29);
 my @filenames    = $ebug->filenames();
 my @break_points = $ebug->break_points();
 my @break_points = $ebug->break_points("t/Calc.pm");
 my @break_points = $ebug->break_points_with_condition();
 my @break_points = $ebug->break_points_with_condition("t/Calc.pm");
 my @break_points = $ebug->all_break_points_with_condition();
 $ebug->watch_point('$x > 100');
 my $codelines = $ebug->codelines(@span);
 $ebug->run;
 my $pad  = $ebug->pad;
 foreach my $k (sort keys %$pad) {
   my $v = $pad->{$k};
   print "Variable: $k = $v\n";
 }
 my $v = $ebug->eval('2 ** $exp');
 my( $v, $is_exception ) = $ebug->eval('die 123');
 my $y = $ebug->yaml('$z');
 my @frames = $ebug->stack_trace;
 my @frames2 = $ebug->stack_trace_human;
 $ebug->undo;
 $ebug->return;
 print "Finished!\n" if $ebug->finished;
```

# DESCRIPTION

A debugger is a computer program that is used to debug other
programs. [Devel::ebug](https://metacpan.org/pod/Devel::ebug) is a simple, extensible Perl debugger with a
clean API. Using this module, you may easily write a Perl debugger to
debug your programs. Alternatively, it comes with an interactive
debugger, [ebug](https://metacpan.org/pod/ebug).

perl5db.pl, Perl's current debugger is currently 2,600 lines of magic
and special cases. The code is nearly unreadable: fixing bugs and
adding new features is fraught with difficulties. The debugger has no
test suite which has caused breakage with changes that couldn't be
properly tested. It will also not debug regexes. [Devel::ebug](https://metacpan.org/pod/Devel::ebug) is
aimed at fixing these problems and delivering a replacement debugger
which provides a well-tested simple programmatic interface to
debugging programs. This makes it easier to build debuggers on top of
[Devel::ebug](https://metacpan.org/pod/Devel::ebug), be they console-, curses-, GUI- or Ajax-based.

There are currently two user interfaces to [Devel::debug](https://metacpan.org/pod/Devel::debug), [ebug](https://metacpan.org/pod/ebug)
and [ebug\_http](https://metacpan.org/pod/ebug_http). [ebug](https://metacpan.org/pod/ebug) is a console-based interface to debugging
programs, much like perl5db.pl. [ebug\_http](https://metacpan.org/pod/ebug_http) is an innovative
web-based interface to debugging programs.

Note that if you're debugging a program, you can invoke the debugger
in the program itself by using the INT signal:

```
kill 2, $$ if $square > 100;
```

[Devel::ebug](https://metacpan.org/pod/Devel::ebug) is a work in progress.

Internally, [Devel::ebug](https://metacpan.org/pod/Devel::ebug) consists of two parts. The frontend is
[Devel::ebug](https://metacpan.org/pod/Devel::ebug), which you interact with. The frontend starts the code
you are debugging in the background under the backend (running it
under perl -d:ebug code.pl). The backend starts a TCP server, which
the frontend then connects to, and uses this to drive the
backend. This adds some flexibility in the debugger. There is some
minor security in the client/server startup (a secret word), and a
random port is used from 3141-4165 so that multiple debugging sessions
can happen concurrently.

# CONSTRUCTOR

## new

The constructor creats a [Devel::ebug](https://metacpan.org/pod/Devel::ebug) object:

```perl
my $ebug = Devel::ebug->new;
```

## program

The program method selects which program to load:

```
$ebug->program("calc.pl");
```

## load

The load method loads the program and gets ready to debug it:

```
$ebug->load;
```

# METHODS

## break\_point

The break\_point method sets a break point in a program. If you are
running through a program, the execution will stop at a break point.
Break points can be set in a few ways.

A break point can be set at a line number in the current file:

```perl
my $actual_line = $ebug->break_point(6);
```

A break point can be set at a line number in the current file with a
condition that must be true for execution to stop at the break point:

```perl
my $actual_line = $ebug->break_point(6, '$e = 4');
```

A break point can be set at a line number in a file:

```perl
my $actual_line = $ebug->break_point("t/Calc.pm", 29);
```

A break point can be set at a line number in a file with a condition
that must be true for execution to stop at the break point:

```perl
my $actual_line = $ebug->break_point("t/Calc.pm", 29, '$i == 2');
```

Breakpoints can not be set on some lines (for example comments); in
this case a breakpoint will be set at the next breakable line, and the
line number will be returned. If no such line exists, no breakpoint is
set and the function returns `undef`.

## break\_on\_load

Set a breakpoint on file loading, the file name can be relative or absolute.

## break\_point\_delete

The break\_point\_delete method deletes an existing break point. A break
point at a line number in the current file can be deleted:

```
$ebug->break_point_delete(29);
```

A break point at a line number in a file can be deleted:

```
$ebug->break_point_delete("t/Calc.pm", 29);
```

## break\_point\_subroutine

The break\_point\_subroutine method sets a break point in a program
right at the beginning of the subroutine. The subroutine is specified
with the full package name:

```perl
my $line = $ebug->break_point_subroutine("main::add");
$ebug->break_point_subroutine("Calc::fib");
```

The return value is the line at which the break point is set.

## break\_points

The break\_points method returns a list of all the line numbers in a
given file that have a break point set.

Return the list of breakpoints in the current file:

```perl
my @break_points = $ebug->break_points();
```

Return the list of breakpoints in a given file:

```perl
my @break_points = $ebug->break_points("t/Calc.pm");
```

## break\_points\_with\_condition

The break\_points method returns a list of break points for a given file.

Return the list of breakpoints in the current file:

```perl
my @break_points = $ebug->break_points_with_condition();
```

Return the list of breakpoints in a given file:

```perl
my @break_points = $ebug->break_points_with_condition("t/Calc.pm");
```

Each element of the list has the form

```perl
{ filename  => "t/Calc.pm",
  line      => 29,
  condition => "$foo > 12",
  }
```

where `condition` might not be present.

## all\_break\_points\_with\_condition

Like `break_points_with_condition` but returns a list of break points
for the whole program.

## codeline

The codeline method returns the line of code that is just about to be
executed:

```
print "Code: "          . $ebug->codeline   . "\n";
```

## codelines

The codelines method returns lines of code.

It can return all the code lines in the current file:

```perl
my @codelines = $ebug->codelines();
```

It can return a span of code lines from the current file:

```perl
my @codelines = $ebug->codelines(1, 3, 4, 5);
```

It can return all the code lines in a file:

```perl
my @codelines = $ebug->codelines("t/Calc.pm");
```

It can return a span of code lines in a file:

```perl
my @codelines = $ebug->codelines("t/Calc.pm", 5, 6);
```

## eval

The eval method evaluates Perl code in the current program and returns
the result. If the evaluation results in an exception, `$@` is
returned.

```perl
my $v = $ebug->eval('2 ** $exp');
```

In list context, eval also returns a flag indicating if the evaluation
resulted in an exception.

```perl
my( $v, $is_exception ) = $ebug->eval('die 123');
```

## filename

The filename method returns the filename of the currently running code:

```
print "In filename: "   . $ebug->filename   . "\n";
```

## filenames

The filenames method returns a list of the filenames of all the files
currently loaded:

```perl
my @filenames = $ebug->filenames();
```

## finished

The finished method returns whether the program has finished running:

```
print "Finished!\n" if $ebug->finished;
```

## line

The line method returns the line number of the statement about to be
executed:

```
print "At line: "       . $ebug->line       . "\n";
```

## next

The next method steps onto the next line in the program. It executes
any subroutine calls but does not step through them.

```
$ebug->next;
```

## output

The output method returns any content the program has output to either
standard output or standard error:

```perl
my($stdout, $stderr) = $ebug->output;
```

## package

The package method returns the package of the currently running code:

```
print "In package: "    . $ebug->package    . "\n";
```

## pad

```perl
my $pad  = $ebug->pad;
foreach my $k (sort keys %$pad) {
  my $v = $pad->{$k};
  print "Variable: $k = $v\n";
}
```

## return

The return subroutine returns from a subroutine. It continues running
the subroutine, then single steps when the program flow has exited the
subroutine:

```
$ebug->return;
```

It can also return your own values from a subroutine, for testing
purposes:

```
$ebug->return(3.141);
```

## run

The run subroutine starts executing the code. It will only stop on a
break point or watch point.

```
$ebug->run;
```

## step

The step method steps onto the next line in the program. It steps
through into any subroutine calls.

```
$ebug->step;
```

## subroutine

The subroutine method returns the subroutine of the currently working
code:

```perl
print "In subroutine: " . $ebug->subroutine . "\n";
```

## stack\_trace

The stack\_trace method returns the current stack trace, using
[Devel::StackTrace](https://metacpan.org/pod/Devel::StackTrace). It returns a list of [Devel::StackTraceFrame](https://metacpan.org/pod/Devel::StackTraceFrame)
methods:

```perl
my @traces = $ebug->stack_trace;
foreach my $trace (@traces) {
  print $trace->package, "->",$trace->subroutine,
  "(", $trace->filename, "#", $trace->line, ")\n";
}
```

## stack\_trace\_human

The stack\_trace\_human method returns the current stack trace in a human-readable format:

```perl
my @traces = $ebug->stack_trace_human;
foreach my $trace (@traces) {
  print "$trace\n";
}
```

## undo

The undo method undoes the last action. It accomplishes this by
restarting the process and passing (almost) all the previous commands
to it. Note that commands which do not change state are
ignored. Commands that change state are: break\_point, break\_point\_delete,
break\_point\_subroutine, eval, next, step, return, run and watch\_point.

```
$ebug->undo;
```

It can also undo multiple commands:

```
$ebug->undo(3);
```

## watch\_point

The watch point method sets a watch point. A watch point has a
condition, and the debugger will stop running as soon as this
condition is true:

```
$ebug->watch_point('$x > 100');
```

## yaml

The eval method evaluates Perl code in the current program and returns
the result of YAML's Dump() method:

```perl
my $y = $ebug->yaml('$z');
```

# SEE ALSO

- [perldebguts](https://metacpan.org/pod/perldebguts)

    The guts of debugging Perl

- [Devel::Chitin](https://metacpan.org/pod/Devel::Chitin)

    A class that exposes the Perl debugging facilities as an API, with
    some functional overlap with [Devel::ebug](https://metacpan.org/pod/Devel::ebug).

- [ebug](https://metacpan.org/pod/ebug)

    Command-line interface to [Devel::ebug](https://metacpan.org/pod/Devel::ebug)

- [ebug\_http](https://metacpan.org/pod/ebug_http)

    Web based interface to [Devel::ebug](https://metacpan.org/pod/Devel::ebug)

# CAVEATS

[Devel::ebug](https://metacpan.org/pod/Devel::ebug) does not support Perls prior to 5.10.1.

[Devel::ebug](https://metacpan.org/pod/Devel::ebug) does not handle signals under Windows.

# AUTHOR

Original author: Leon Brocard <acme@astray.com>

Current maintainer: Graham Ollis <plicease@cpan.org>

Contributors:

Brock Wilcox <awwaiid@thelackthereof.org>

Taisuke Yamada

# COPYRIGHT AND LICENSE

This software is copyright (c) 2005-2024 by Leon Brocard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
