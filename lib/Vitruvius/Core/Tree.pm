package Vitruvius::Core::Tree;

use Vitruvius::Skel::Moo;

extends 'Vitruvius::Core::Base';

use Vitruvius::Types qw{ HashRef ArrayRef InstanceOf VtvNode };

use Perl::Tidy;
use PPI;

use Vitruvius::Core::Node;
use Vitruvius::Util qw< is_interesting >;

=head1 PARAMETERS

=head2 location_factory

Factory to create Location for each node

=cut

has location_factory => (
    is       => 'ro',
    isa      => InstanceOf ['Vitruvius::LocationFactory'],
    required => 1,
    handles  => ['new_location'],
);

=head2 ppi

PPI for this tree, excluding Data, End, and Pod sections

=cut

has ppi => (
    is       => 'ro',
    isa      => InstanceOf ['PPI::Node'],
    required => 1,
);

=head1 ATTRIBUTES

=head2 root

Root Node of decorated code tree

=cut

has root => (
    is      => 'ro',
    lazy    => 1,
    isa     => InstanceOf [VtvNode],
    builder => '_build_root',
    handles => [
        qw<
          class
          content
          crc_hash
          ppi_hash
          ppi_hashes
          tlsh_hash
          >
    ],
);

sub _tree_node {
    my ( $self, $ppi, $parent ) = @_;

    my $node = Vitruvius::Core::Node->new(
        ppi         => $ppi,
        location    => $self->new_location($ppi),
        parent      => $parent,
    );

    my $children = [];
    if ( $ppi->can('children') && $ppi->children ) {
        $children = [ map { $self->_tree_node( $_, $node ) } $ppi->children ];
    }

    $node->children($children);

    return $node;
}

sub _build_root {
    my $self = shift;

    return $self->_tree_node( $self->ppi );
}

=head2 nodes

All nodes, depth-first, preorder

=cut

has nodes => (
    is      => 'ro',
    lazy    => 1,
    isa     => ArrayRef [VtvNode],
    builder => '_build_nodes',
);

sub _build_nodes {
    my $self = shift;

    my @stack = ( $self->root );
    my @nodes;

    while ( my $node = shift @stack ) {
        push @nodes, $node if is_interesting( $node->type );
        push @stack, $node->children->@*;
    }

    return \@nodes;
}

1;
