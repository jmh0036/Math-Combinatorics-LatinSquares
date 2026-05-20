use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Math::Combinatorics::LatinSquares',
    AUTHOR           => 'James Hammer <jmh0036@example.com>',
    VERSION_FROM     => 'lib/Math/Combinatorics/LatinSquares.pm',
    ABSTRACT_FROM    => 'lib/Math/Combinatorics/LatinSquares.pm',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.010',
    PREREQ_PM        => {
        'Algorithm::DLX' => '0.02',
        'List::Util'     => '1.33',
        'Getopt::Long'   => '2.45',
        'Pod::Usage'     => '1.69',
        'Carp'           => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => '0.98',
    },
    EXE_FILES => ['bin/latin-squares'],
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/jmh0036/Math-Combinatorics-LatinSquares.git',
                web  => 'https://github.com/jmh0036/Math-Combinatorics-LatinSquares',
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean => { FILES    => 'Math-Combinatorics-LatinSquares-*' },
);
