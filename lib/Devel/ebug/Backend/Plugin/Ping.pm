package Devel::ebug::Backend::Plugin::Ping;
use strict;
use warnings;


sub register_commands {
    return ( ping => { sub => \&ping } );

}

sub ping {
  my($req, $context) = @_;
  my $secret = $ENV{SECRET};
  die "Did not pass secret" unless $req->{secret} eq $secret;
  $ENV{SECRET} = "";
  return {
    version => $DB::VERSION,
  }
}

1;
