package TestsFor::Vitruvius::Core::Tree;

use FindBin::libs;
use Vitruvius::Test;

use Path::Tiny;
use PPI;

use Vitruvius::Core::LocationFactory;
use Vitruvius::Util qw< ppi_type >;

sub test_basics : Test {
    my $test = shift;

    my $file = __FILE__;

    my $base_dir = path('./t/lib')->absolute;

    my $factory = Vitruvius::Core::LocationFactory->new( base_dir => $base_dir, file => $file );

    my $ppi_document = PPI::Document->new($file);

    my $tree;

    ok( lives { $tree = $CLASS->new( location_factory => $factory, ppi => $ppi_document ) }, '->new should succeed' );

    isa_ok( $tree, [$CLASS], '->new should return correct class' );

    ok( lives { $tree->root }, '->root should succeed' );

    isa_ok( $tree->root, ['Vitruvius::Core::Node'], '->root should return a Core::Node' );

    is( $tree->root->location, 'TestsFor/Vitruvius/Core/Tree.pm, no sub, L1', '->root->location should be correct' );

    ok( lives { $tree->nodes }, '->nodes should succeed' );

    ref_ok( $tree->nodes, 'ARRAY', '->nodes should return an arrayref' );
}

1;
