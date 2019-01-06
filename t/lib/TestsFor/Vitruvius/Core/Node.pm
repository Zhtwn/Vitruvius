package TestsFor::Vitruvius::Core::Node;

use FindBin::libs;
use Vitruvius::Test;

use Perl::Tidy;
use PPI;

use Vitruvius::Core::Location;
use Vitruvius::Util qw< ppi_type >;

sub test_basics : Test {
    my $test = shift;

    my $perl_code = <<'EOF';
    # comment
    sub foo {
        my @bar = ( 9);
        # another comment
        for my $baz (@bar ) {
            print "$baz\n";     # yet another comment
        }
    }
EOF

    my $ppi_document = PPI::Document->new( \$perl_code );

    # use the location of this file
    my $location = Vitruvius::Core::Location->new( ppi => $ppi_document );

    my $node;
    ok( lives { $node = $CLASS->new( ppi => $ppi_document, location => $location ) }, '->new should succeed' );

    isa_ok( $node, [$CLASS], '->new should return correct class' );

    isa_ok( $node->code, ['Vitruvius::Core::Code'], '->code should return a Core::Code instance' );

    is( $node->code->content, $perl_code, '->code->content should have original content' );

    is( $node->children, [], '->children should be empty by default' );

    is( $node->parent, undef, '->parent should be undefined by default' );

    # Note: with no children, Node hash is simply Code's hash
    is( $node->ppi_hash, $node->code->ppi_element_hash, '->ppi_hash should match code->ppi_element_hash' );

    is( $node->ppi_size, length $node->ppi_hash, '->ppi_size should be length of ppi_hash' );
}

1;
