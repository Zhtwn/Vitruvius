package Code::Refactor::Tree;

use Moo;

use Types::Standard qw{ InstanceOf };

use Code::Refactor::TreeData;

=head1 PARAMETERS

=head2 ppi

PPI::Node for this abstract syntax tree

=cut

has ppi => (
    is       => 'ro',
    isa      => InstanceOf ['PPI::Node'],
    required => 1,
);

=head1 ATTRIBUTES

=head2 hashes

RENAMEME - hashes of all elements within syntax tree, hashed by stringified element

=head2 elements

RENAMEME - arrayrefs of all elements, hashed by element hash

=cut

has _tree_data => (
    is      => 'lazy',
    isa     => InstanceOf['Code::Refactor::TreeData'],
    builder => '_build__tree_data',
    handles => [ qw{ hashes elements } ],
);

sub _build__tree_data {
    my $self = shift;

    return Code::Refactor::TreeData->new( ppi => $self->ppi );
}

1;
