package TestsFor::Vitruvius::Core::NodeSet;

use FindBin::libs;
use Vitruvius::Test;

use Path::Tiny;
use PPI;

use Vitruvius::App::Similarity; # used as configuration
use Vitruvius::Core::FileSet;

sub single_job : Test {
    my $test = shift;

    my $base_dir = path('./lib')->absolute;

    my $core_dir = path('./lib/Vitruvius/Core');

    my @files = $core_dir->children;

    my $config = Vitruvius::App::Similarity->new(
        verbose   => 1,
        jobs      => 1,
        base_dir  => $base_dir,
        filenames => \@files,
    );

    my $fileset = Vitruvius::Core::FileSet->new( config => $config );

    my $nodeset;

    ok( lives { $nodeset = $CLASS->new( config => $config, fileset => $fileset ) }, '->new should succeed', $@ );

    isa_ok( $nodeset, [$CLASS], '->new should return correct class' );

    ok( lives { $nodeset->nodes }, '->nodes should succeed', $@ . '' );
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

    my $fileset = Vitruvius::Core::FileSet->new( config => $config );

    my $nodeset;

    ok( lives { $nodeset = $CLASS->new( config => $config, fileset => $fileset ) }, '->new should succeed', $@ );

    isa_ok( $nodeset, [$CLASS], '->new should return correct class' );

    ok( lives { $nodeset->nodes }, '->nodes should succeed', $@ . '' );
}

1;
