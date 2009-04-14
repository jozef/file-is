use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'File::is',
    license             => 'perl',
    dist_author         => 'Jozef Kutej <jkutej@cpan.org>',
    dist_version_from   => 'lib/File/is.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'File-is-*' ],
    create_makefile_pl => 'traditional',
    create_readme       => 1,
    sign                => 1,
);

$builder->create_build_script();
