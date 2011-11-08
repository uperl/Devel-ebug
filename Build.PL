use strict;
use lib 'lib';
use lib '../lib';
use Module::Build;

my $requires = {
  'Carp'                 => '0',
  'Class::Accessor::Chained::Fast' => '0',
  'Devel::StackTrace'    => '0',
  'IO::Socket::INET'     => '0',
  'File::Find'           => '0',
  'Module::Pluggable'    => '0',
  'PadWalker'            => '0',
  'Proc::Background'     => '0',
  'Scalar::Util'         => '0',
  'String::Koremutake'   => '0',
  'Test::More'           => '0',
  'YAML::Syck'           => '0.85',
};

my $build_requires = {
  'YAML' => '0',
};


# Test::Expect doesn't run under Windows atm
if ($^O !~ /mswin32/i) {
  $requires->{'Test::Expect'} = '0';
}

my $build = Module::Build->new(
  create_makefile_pl => 'small',
  license            => 'perl',
  module_name        => 'Devel::ebug',
  requires           => $requires,
  build_requires     => $build_requires,
  script_files       => ['bin/ebug', 'bin/ebug_client', 'bin/ebug_server'],
);
$build->create_build_script;

