package Code::Refactor::Diff;

use Moo;

use Types::Standard qw< Int Str Bool InstanceOf Tuple >;

use Diff::LibXDiff;
use Text::Levenshtein;

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

=head2 identical

Are the two snippets identical?

=cut

has identical => (
    is      => 'lazy',
    isa     => Bool,
    builder => '_build_identical',
);

sub _build_identical {
    my $self = shift;

    my ( $first, $second ) = $self->snippets->@*;

    return $first->crc_hash == $second->crc_hash;
}

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

    my ( $first, $second ) = map { $_->tlsh } $self->snippets->@*;

    return $first->total_diff($second);
}

=head2 levenshtein_distance

Levenshtein distance between uncommented versions of snippets

=cut

has levenshtein_distance => (
    is      => 'lazy',
    isa     => Int,
    builder => '_build_levenshtein_distance',
);

sub _build_levenshtein_distance {
    my $self = shift;

    $DB::single = 1;
    return Text::Levenshtein::distance( map { $_->raw_content } $self->snippets->@* );
}

=head2 xdiff

Diff from libxdiff

=cut

has xdiff => (
    is      => 'lazy',
    isa     => Str,
    builder => '_build_xdiff',
);

sub _build_xdiff {
    my $self = shift;

    return Diff::LibXDiff->diff( map { $_->raw_content } $self->snippets->@* );
}

1;
