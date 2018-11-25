package Code::Refactor::SnippetPair;

use Moo;

use Types::Standard qw< Int InstanceOf Tuple >;

=head1 PARAMETERS

=head2 snippets

ArrayRef of two snippets to be compared

=cut

has snippets => (
    is       => 'ro',
    isa      => Tuple [ InstanceOf ['Code::Refactor::Snippet'], InstanceOf ['Code::Refactor::Snippet'] ],
    required => 1,
);

=head1 ATTRIBUTES

=head2 distance

Edit distance between snippets

=cut

has distance => (
    is => 'lazy',
    isa => Int,
    builder => '_build_distance',
);

sub _build_distance {
    my $self = shift;

    my ( $first, $second ) = $self->snippets->@*;

    return $first->distance($second);
}

1;
