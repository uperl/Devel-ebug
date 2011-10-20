package Devel::ebug::Backend::Plugin::Codelines;
use strict;
use warnings;

sub register_commands {
    return ( codelines   => { sub => \&codelines } );

}

sub codelines {
  my($req, $context) = @_;
  my $filename = $req->{filename};
  my @lines    = @{$req->{lines}};

  return { codelines => [ DB::fetch_codelines($filename, @lines)] };

}
1;
