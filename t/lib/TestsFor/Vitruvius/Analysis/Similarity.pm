package TestsFor::Vitruvius::Analysis::Similarity;

use FindBin::libs;
use Vitruvius::Test;

use Path::Tiny;
use PPI;

use Vitruvius::App::Similarity; # used as configuration
use Vitruvius::Core::FileSet;
use Vitruvius::Core::NodeSet;

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

    my $file_set = Vitruvius::Core::FileSet->new( config => $config );

    my $node_set = Vitruvius::Core::NodeSet->new( config => $config, file_set => $file_set );

    my $similarity;

    ok( lives { $similarity = $CLASS->new( config => $config, node_set => $node_set ) }, '->new should succeed', $@ );

    isa_ok( $similarity, [$CLASS], '->new should return correct class' );

    ok( lives { $similarity->diffs }, '->diffs should succeed' );

    ok( lives { $similarity->groups }, '->groups should succeed' );

    ok( lives { $similarity->report_lines }, '->report_lines should succeed' );
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

    my $file_set = Vitruvius::Core::FileSet->new( config => $config );

    my $node_set = Vitruvius::Core::NodeSet->new( config => $config, file_set => $file_set );

    my $similarity;

    ok( lives { $similarity = $CLASS->new( config => $config, node_set => $node_set ) }, '->new should succeed', $@ );

    isa_ok( $similarity, [$CLASS], '->new should return correct class' );

    ok( lives { $similarity->diffs }, '->diffs should succeed' );

    ok( lives { $similarity->groups }, '->groups should succeed' );

    ok( lives { $similarity->report_lines }, '->report_lines should succeed' );
}

1;
