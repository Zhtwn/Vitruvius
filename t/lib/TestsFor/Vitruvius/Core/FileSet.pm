package TestsFor::Vitruvius::Core::FileSet;

use FindBin::libs;
use Vitruvius::Test;

use Path::Tiny;
use PPI;

use Vitruvius::App::Similarity; # used as configuration

sub single_job : Test {
    my $test = shift;

    my $base_dir = path('./lib')->absolute;

    my $core_dir = path('./lib/Vitruvius/Core');

    my @files = $core_dir->children;

    my $config = Vitruvius::App::Similarity->new(
        jobs      => 1,
        base_dir  => $base_dir,
        filenames => \@files,
    );

    my $fileset;

    ok( lives { $fileset = $CLASS->new( config => $config ) }, '->new should succeed', $@ );

    isa_ok( $fileset, [$CLASS], '->new should return correct class' );

    ok( lives { $fileset->files }, '->files should succeed' );
}

sub multiple_jobs : Test {
    my $test = shift;

    my $base_dir = path('./lib')->absolute;

    my $core_dir = path('./lib/Vitruvius/Core');

    my @files = $core_dir->children;

    my $config = Vitruvius::App::Similarity->new(
        jobs      => 2,
        base_dir  => $base_dir,
        filenames => \@files,
    );

    my $fileset;

    ok( lives { $fileset = $CLASS->new( config => $config ) }, '->new should succeed', $@ );

    isa_ok( $fileset, [$CLASS], '->new should return correct class' );

    ok( lives { $fileset->files }, '->files should succeed' );
}

1;
