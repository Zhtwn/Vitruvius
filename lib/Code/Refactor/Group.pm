package Code::Refactor::Group;

use Moo;

use Types::Standard qw< Str ArrayRef HashRef InstanceOf >;

use Code::Refactor::Diff;

=head1 PARAMETERS

=head2 nodes

All nodes in group

=cut

has nodes => (
    is       => 'ro',
    isa      => ArrayRef [ InstanceOf ['Code::Refactor::Node'] ],
    required => 1,
);

=head1 ATTRIBUTES

=head2 base_node

Node to be used as base for comparision

=head2 type

Type of Nodes - derived from first (base) node

=cut

has base_node => (
    is      => 'lazy',
    isa     => InstanceOf ['Code::Refactor::Node'],
    builder => '_build_base_node',
    handles => [ qw< type ppi_hash_length > ],  # FIXME - assumes identical ppi_hash
);

sub _build_base_node {
    my $self = shift;

    return $self->nodes->[0];
}

=head2 diffs

Diffs from base node to all other nodes

=cut

has diffs => (
    is      => 'ro',
    isa     => ArrayRef [ InstanceOf ['Code::Refactor::Diff'] ],
    lazy    => 1,
    builder => '_build_diffs',
);

sub _build_diffs {
    my $self = shift;

    my $base_node = $self->base_node;

    return [ map { Code::Refactor::Diff->new( nodes => [ $base_node, $_ ] ) } $self->nodes->@* ];
}

=head2 distances

Distances between each snippet in a Diff

=cut

has distances => (
    is      => 'ro',
    isa     => HashRef [ ArrayRef [ InstanceOf ['Code::Refactor::Diff'] ] ],
    lazy    => 1,
    builder => '_build_distances',
);

sub _build_distances {
    my $self = shift;

    my %distances;

    for my $diff ( $self->diffs->@* ) {
        my $distance = $diff->identical ? -1 : $diff->distance;
        push $distances{$distance}->@*, $diff;
    }

    return \%distances;
}

1;
