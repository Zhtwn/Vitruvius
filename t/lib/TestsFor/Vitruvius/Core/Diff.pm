package TestsFor::Vitruvius::Core::Diff;

use FindBin::libs;
use Vitruvius::Test;

use Path::Tiny;
use PPI;

use Vitruvius::Core::Tree;
use Vitruvius::Core::LocationFactory;

sub identical_nodes : Test {
    my $test = shift;

    my $file = __FILE__;

    my $base_dir = path('./t/lib')->absolute;

    my $factory = Vitruvius::Core::LocationFactory->new( base_dir => $base_dir, file => $file );

    my $ppi = PPI::Document->new($file);

    my $location = $factory->new_location($ppi);

    # create two identical nodes, with full tree context
    my @nodes = map { $_->root } map { Vitruvius::Core::Tree->new( location_factory => $factory, ppi => $ppi ) } ( 0 .. 1 );

    my $diff;

    ok( lives { $diff = $CLASS->new( nodes => \@nodes ) }, '->new should succeed' );

    isa_ok( $diff, [$CLASS], '->new should return correct class' );

    is( $diff->type, $nodes[0]->type, 'diff should have same type as nodes' );

    ok( $diff->identical, '->identical should be true for identical nodes' );

    is( $diff->ppi_levenshtein_similarity, 100, '->ppi_levenshtein_simliarity should be 100%' );

    is( $diff->xdiff, '', '->xdiff should show no differences' );

    is( $diff->diff_lines, 0, '->diff_lines should show zero lines of difference' );

    my @expected_report_lines = (
        '    Location: ' . $diff->node->location,
        '    Similarity: ' . $diff->ppi_levenshtein_similarity,
    );

    is( [$diff->report_lines], \@expected_report_lines, '->report_lines should be correct' );
}

sub different_nodes : Test {
    my $test = shift;

    my $base_dir = path('./t/lib')->absolute;

    my $base_file = __FILE__;
    (my $other_file = $base_file ) =~ s/Diff/Node/;

    my @nodes;
    for my $file ( $base_file, $other_file ) {
        my $factory = Vitruvius::Core::LocationFactory->new( base_dir => $base_dir, file => $file );
        my $ppi = PPI::Document->new($file);
        my $tree = Vitruvius::Core::Tree->new( location_factory => $factory, ppi => $ppi );
        push @nodes, $tree->root;
    }

    my $diff;

    ok( lives { $diff = $CLASS->new( nodes => \@nodes ) }, '->new should succeed' );

    isa_ok( $diff, [$CLASS], '->new should return correct class' );

    ok( !$diff->identical, '->identical should be false for different nodes' );

    isnt( $diff->ppi_levenshtein_similarity, 100, '->ppi_levenshtein_simliarity should not be 100%', $diff->ppi_levenshtein_similarity );

    isnt( $diff->xdiff, '', '->xdiff should show differences' );

    isnt( $diff->diff_lines, 0, '->diff_lines should show some lines of difference' );

    my @expected_report_lines = (
        '    Location: ' . $diff->node->location,
        '    Similarity: ' . $diff->ppi_levenshtein_similarity,
    );

    isnt( [$diff->report_lines], \@expected_report_lines, '->report_lines should show file differences' );
}

sub swapping_nodes : Test {
    my $test = shift;

    my $base_dir = path('./t/lib')->absolute;

    my $base_file = __FILE__;
    (my $other_file = $base_file ) =~ s/Diff/Node/;

    my @nodes;
    for my $file ( $base_file, $other_file ) {
        my $factory = Vitruvius::Core::LocationFactory->new( base_dir => $base_dir, file => $file );
        my $ppi = PPI::Document->new($file);
        my $tree = Vitruvius::Core::Tree->new( location_factory => $factory, ppi => $ppi );
        push @nodes, $tree->root;
    }

    my $diff;

    ok( lives { $diff = $CLASS->new( nodes => \@nodes ) }, '->new should succeed', $@ );

    isa_ok( $diff, [$CLASS], '->new should return correct class' );

    is( $diff->base_node->location . '', $nodes[0]->location . '', 'base node should be the first node' );

    my $same_diff;

    ok( lives { $same_diff = $diff->for_node( $nodes[0]->location ) }, '->for_node should succeed', $@ );

    isa_ok( $same_diff, [$CLASS], '->new should return correct class' );

    is( $same_diff->base_node->location . '', $nodes[0]->location . '', 'base node of same diff should be the first node' );

    my $swapped_diff;

    ok( lives { $swapped_diff = $diff->for_node( $nodes[1]->location ) }, '->for_node should succeed', $@ );

    isa_ok( $swapped_diff, [$CLASS], '->new should return correct class' );

    is( $swapped_diff->base_node->location . '', $nodes[1]->location . '', 'base node of swapped diff should be the second node' );
};

1;
