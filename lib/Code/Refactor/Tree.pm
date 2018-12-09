package Code::Refactor::Tree;

use Moo;
use v5.16;

use Types::Path::Tiny qw< File Path >;
use Types::Standard qw{ HashRef ArrayRef InstanceOf };

use PPI;

use Code::Refactor::Node;
use Code::Refactor::Util qw< is_interesting >;

=head1 PARAMETERS

=head2 location_factory

Factory to create Location for each node

=cut

has location_factory => (
    is       => 'ro',
    isa      => InstanceOf['Code::Refactor::LocationFactory'],
    required => 1,
    handles  => ['new_location'],
);

=head2 ppi

PPI for this tree, excluding Data, End, and Pod sections

=cut

has ppi => (
    is      => 'lazy',
    isa     => InstanceOf ['PPI::Node'],
    required => 1,
);

=head1 ATTRIBUTES

=head2 root

Root Node of decorated code tree

=cut

has root => (
    is      => 'lazy',
    isa     => InstanceOf ['Code::Refactor::Node'],
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
    my ($self, $ppi, $parent) = @_;

    my $node = Code::Refactor::Node->new(
        location => $self->new_location($ppi),
        ppi      => $ppi,
        parent   => $parent,
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

#   say "Building tree " . $self->file->relative( $self->base_dir );

    return $self->_tree_node($self->ppi);
}

=head2 nodes

All nodes, depth-first, preorder

=cut

has nodes => (
    is      => 'lazy',
    isa     => ArrayRef [ InstanceOf ['Code::Refactor::Node'] ],
    builder => '_build_nodes',
);

sub _build_nodes {
    my $self = shift;

    my @stack = ( $self->root );
    my @nodes;

    while ( my $node = shift @stack ) {
        push @nodes, $node;
        push @stack, $node->children->@*;
    }

    return \@nodes;
}

=head2 node_ppi_hashes

Interesting Nodes, hashed by node type and ppi_hash

=cut

has node_ppi_hashes => (
    is      => 'lazy',
    isa     => HashRef [ HashRef [ ArrayRef [ InstanceOf['Code::Refactor::Node'] ] ] ],
    builder => '_build_node_ppi_hashes',
);

sub _build_node_ppi_hashes {
    my $self = shift;

    my %hashes;

    for my $node ( $self->nodes->@* ) {
        next unless is_interesting( $node->raw_ppi );
        push $hashes{ $node->type }->{ $node->ppi_hash }->@*, $node;
    }

    return \%hashes;
}

1;
