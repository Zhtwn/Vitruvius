package Code::Refactor::Group;

use Moo;

use Types::Standard qw< Str ArrayRef HashRef InstanceOf >;

use Code::Refactor::Diff;

=head1 PARAMETERS

=head2 diffs

All Diffs in group

=cut

has diffs => (
    is       => 'ro',
    isa      => ArrayRef [ InstanceOf ['Code::Refactor::Diff'] ],
    required => 1,
);

=head1 ATTRIBUTES

=head2 base_node

Node that was used as base for comparision: first Node in each Diff

=head2 type

Type of Nodes - derived from first (base) node

=cut

has base_node => (
    is      => 'lazy',
    isa     => InstanceOf ['Code::Refactor::Node'],
    builder => '_build_base_node',
    handles => [ qw< type ppi_hash_length > ],
);

sub _build_base_node {
    my $self = shift;

    return $self->diffs->[0]->nodes->[0];
}

=head2 nodes

All other nodes in group, sorted by similarity to base node

=cut

has nodes => (
    is      => 'lazy',
    isa     => ArrayRef [ InstanceOf ['Code::Refactor::Node'] ],
    builder => '_build_nodes',
);

sub _build_nodes {
    my $self = shift;

    my @diffs = sort { $a->ppi_levenshtein_similarity <=> $b->ppi_levenshtein_similarity } $self->diffs->@*;

    return [ map { $_->node } @diffs ];
}

1;
