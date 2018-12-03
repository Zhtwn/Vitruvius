package Code::Refactor::Diff;

use Moo;

use Types::Standard qw< Int Str Num Bool InstanceOf Tuple >;

use Diff::LibXDiff;
use List::Util qw< max min >;
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

=head2 diff_lines

Number of line differences

=cut

has diff_lines => (
    is => 'lazy',
    isa => Num,
    builder => '_build_diff_lines',
);

sub _build_diff_lines {
    my $self = shift;

    my $xdiff = $self->xdiff;

    my %counts;
    $counts{$_}++ for map { substr( $_, 0, 1 ) } split /\n/, $xdiff;

    my $line_count = max( $counts{'+'}, $counts{'-'} );

    my @content = map { $_->ppi->content } $self->snippets->@*;

    my @lines = map { [ split /\n/, $_ ] } @content;

    my @line_counts = map { scalar @$_ } @lines;

    my $tot_lines = min @line_counts;

#   my $tot_lines = max map { @$_ } map { [ split /\n/, $_ ] } map { $_->ppi->content } $self->snippets->@*;

    return $line_count / $tot_lines;
}

1;
