package Vitruvius::Core::Tree;

use Vitruvius::Skel::Moo;

use Vitruvius::Types qw{ HashRef ArrayRef InstanceOf VtvNode };

use Perl::Tidy;
use PPI;

use Vitruvius::Core::Node;
use Vitruvius::Util qw< is_interesting >;

=head1 NAME

Vitruvius::Core::Tree - tree of Nodes

=head1 SYNOPSIS

    my $ppi = PPI::Document->new($file);
    my $location_factory = Vitruvius::LocationFactory->new(file => $file, base_dir => $base_dir);

    # Constructor
    my $tree = Vitruvius::Core::Tree->new( location_factory => $location_factory, ppi => $ppi );

    # build Tree of decorated Nodes
    my $root = $tree->root;

    # do something for every Node in the tree
    for my $node ( $tree->nodes->@* ) {
        ...
    }

=head1 DESCRIPTION

A C<Vitruvius::Tree> contains a tree of C<Node> instances, created by decorating the PPI
nodes of the parsed code.

It provides the root Node of the tree as C<root>, and an arrayref of all nodes as C<nodes>

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
    my ( $self, $ppi ) = @_;

    my $children = [];
    if ( $ppi->can('children') && $ppi->children ) {
        $children = [ map { $self->_tree_node($_) } $ppi->children ];
    }

    my $node = Vitruvius::Core::Node->new(
        ppi         => $ppi,
        location    => $self->new_location($ppi),
        children    => $children,
    );

    $_->parent($node) for @$children;

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
