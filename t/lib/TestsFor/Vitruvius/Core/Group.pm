package TestsFor::Vitruvius::Core::Group;

use FindBin::libs;
use Vitruvius::Test;

use List::Util qw< sum >;
use Path::Tiny;
use PPI;

use Vitruvius::Core::Tree;
use Vitruvius::Core::LocationFactory;

sub basic_tests : Test {
    my $test = shift;

    my $base_dir = path('./lib')->absolute;

    my $core_dir = path('./lib/Vitruvius/Core');

    my @files = $core_dir->children;

    my @nodes;
    for my $file (@files) {
        my $factory = Vitruvius::Core::LocationFactory->new( base_dir => $base_dir, file => $file );
        my $ppi     = PPI::Document->new($file);
        my $tree    = Vitruvius::Core::Tree->new( location_factory => $factory, ppi => $ppi );

        push @nodes, $tree->root;
    }

    my $base_node = shift @nodes;

    my @diffs = map { Vitruvius::Core::Diff->new( nodes => [ $base_node, $_ ] ) } @nodes;

    my $group;

    ok( lives { $group = $CLASS->new( base_node => $base_node, diffs => \@diffs ) }, '->new should succeed', $@ );

    isa_ok( $group, [$CLASS], '->new should return correct class' );

    is( $group->location . '', $base_node->location . '', '->location should be location of base node' );

    is( $group->count, scalar @diffs, '->count should be correct' );

    is( $group->sum, sum( map { $_->ppi_levenshtein_similarity } @diffs ), '->sum should be correct' );

    is( $group->mean, $group->sum / $group->count, '->mean should be correct' );

    my @ordered_diffs =
      sort {
        $b->ppi_levenshtein_similarity <=> $a->ppi_levenshtein_similarity
          || ( $a->node->location . '' ) cmp( $b->node->location . '' )
      } @diffs;

    my $i = 1;
    my @expected_lines = (
        'SIMILAR: ' . $group->type . ' (PPI Size: ' . $group->base_node->ppi_size . ')',
        '  Base Node: ' . $group->base_node->location,
        map { '  Node ' . $i++ . ':',  $_->report_lines } @ordered_diffs,
    );

    is( [ $group->report_lines ], \@expected_lines, '->report_lines should be correct' );
}

1;
