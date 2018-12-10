package Code::Refactor::Diff;

use Moo;

use Types::Standard qw< Int Str Num Bool InstanceOf Tuple >;

use Diff::LibXDiff;
use List::Util qw< max min >;
use Text::Levenshtein;

=head1 PARAMETERS

=head2 nodes

ArrayRef of two nodes to be compared

=cut

has nodes => (
    is       => 'ro',
    isa      => Tuple [ InstanceOf ['Code::Refactor::Node'], InstanceOf ['Code::Refactor::Node'] ],
    required => 1,
);

=head1 ATTRIBUTES

=head2 base_node

Base node

=cut

has base_node => (
    is      => 'lazy',
    isa     => InstanceOf ['Code::Refactor::Node'],
    builder => '_build_base_node',
    handles => ['type'],
);

sub _build_base_node {
    my $self = shift;

    return $self->nodes->[0];
}

=head2 node

Other node

=cut

sub node { shift->nodes->[1] }

=head2 identical

Are the two nodes identical?

=cut

has identical => (
    is      => 'lazy',
    isa     => Bool,
    builder => '_build_identical',
);

sub _build_identical {
    my $self = shift;

    my ( $first, $second ) = $self->nodes->@*;

    return $first->crc_hash == $second->crc_hash;
}

=head2 tree_distance

Distance between trees: ratio of common substring length to total
length

=cut

has tree_distance => (
    is      => 'lazy',
    isa     => Num,
    builder => '_build_tree_distance',
);

sub _build_tree_distance {
    my $self = shift;

    my ( $first, $second ) = $self->nodes->@*;
    my $first_hashes  = $first->ppi_hashes;
    my $second_hashes = $second->ppi_hashes;

    my $total_length = max length($first->ppi_hash), length($second->ppi_hash);
    my $match_length = 0;

    for my $hash ( sort { length $a <=> length $b } keys %$first_hashes ) {
        if ( my $matches = $second_hashes->{$hash} ) {
            $match_length += length $hash;

            # arbitrarily choose the first exact match for partitioning
            my $partition = $matches->[0];

            my $left

            # TODO - extract "before" and "after" subtrees from both trees, and run tree_distance on those
        }
    }

    return $match_length / $total_length;
}



=head2 distance

Edit distance between nodes

=cut

has distance => (
    is => 'lazy',
    isa => Int,
    builder => '_build_distance',
);

sub _build_distance {
    my $self = shift;

    my ( $first, $second ) = map { $_->tlsh } $self->nodes->@*;

    return $first->total_diff($second);
}

=head2 ppi_levenshtein_similarity

Similarity of PPI hashes of the two nodes, as percent

Ranges from 0 (completely different) to 100 (completely identical)

=cut

has ppi_levenshtein_similarity => (
    is      => 'lazy',
    isa     => Int,
    builder => '_build_ppi_levenshtein_similarity',
);

sub _build_ppi_levenshtein_similarity {
    my $self = shift;

    my $nodes = $self->nodes;

    my $distance = Text::Levenshtein::distance( map { $_->ppi_hash } @$nodes );

    my $max_length = max map { $_->ppi_hash_length } @$nodes;

    return int( 100 * ( $max_length - $distance ) / $max_length );
}

=head2 levenshtein_distance

Levenshtein distance between uncommented versions of nodes

=cut

has levenshtein_distance => (
    is      => 'lazy',
    isa     => Int,
    builder => '_build_levenshtein_distance',
);

sub _build_levenshtein_distance {
    my $self = shift;

    return Text::Levenshtein::distance( map { $_->raw_content } $self->nodes->@* );
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

    return Diff::LibXDiff->diff( map { $_->raw_content } $self->nodes->@* );
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

    my @content = map { $_->ppi->content } $self->nodes->@*;

    my @lines = map { [ split /\n/, $_ ] } @content;

    my @line_counts = map { scalar @$_ } @lines;

    my $tot_lines = min @line_counts;

#   my $tot_lines = max map { @$_ } map { [ split /\n/, $_ ] } map { $_->ppi->content } $self->nodes->@*;

    return $line_count / $tot_lines;
}

1;
