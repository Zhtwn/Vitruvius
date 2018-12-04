package Code::Refactor::Tree;

use Moo;
use v5.16;

use Types::Path::Tiny qw< File Path >;
use Types::Standard qw{ HashRef ArrayRef InstanceOf };

use PPI;

use Code::Refactor::Snippet;
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
    is => 'lazy',
    isa => InstanceOf['Code::Refactor::Node'],
    builder => '_build_root',
    handles => ['ppi_hashes'],
);

sub _tree_node {
    my ($self, $ppi) = @_;

    my $children = [];
    if ($ppi->can('children') && $ppi->children) {
        $children = map { $self->_tree_node($_) } $ppi->children;
    }

    return Code::Refactor::Node->new(
        location => $self->new_location($ppi),
        ppi      => $ppi,
        children => $children,
    );
}


sub _build_root {
    my $self = shift;

    say "Building tree " . $self->file->relative( $self->base_dir );

    return $self->_tree_node($self->ppi);
}

1;
