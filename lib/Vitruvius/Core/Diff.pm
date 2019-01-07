package Vitruvius::Core::Diff;

use Vitruvius::Skel::Moo;

use Vitruvius::Types qw< Int Str Num Bool ArrayRef Tuple VtvNode >;

use Diff::LibXDiff;
use List::Util qw< max min >;
use Text::Levenshtein::XS;

use Vitruvius::Core::Node;

=head1 NAME

Vitruvius::Core::Diff - differences between two Nodes

=head1 SYNOPSIS

    my $diff = Vitruvius::Core::Diff->new( nodes => [ $node1, $node2 ] );

    # Type of node (nodes should be of same type)
    my $type = $diff->type;

    # are the nodes completely identical (including comments)?
    if ($diff->identical) { ... }

    # PPI similarity
    my $similarity = $diff->ppi_levenshtein_similarity

    # xdiff between original code of the nodes (as string)
    my $xdiff = $diff->xdiff;

    # number of line differences in xdiff
    my $diff_lines = $diff->diff_lines

    # report on node similarity and differences
    say for $diff->report_lines->@*;

=head1 DESCRIPTION

A C<Core::Diff> represents the differences between two Nodes.

Two different methods of diff are provided: a typical code diff,
and the similarity between the hashes of the PPI structure.

=head1 PARAMETERS

=head2 nodes

ArrayRef of two nodes to be compared

=cut

has nodes => (
    is       => 'ro',
    isa      => Tuple [ VtvNode, VtvNode ],
    required => 1,
);

=head1 ATTRIBUTES

=head2 locations

Locations of the two nodes

=cut

has locations => (
    is      => 'ro',
    lazy    => 1,
    isa     => ArrayRef [Str],
    builder => '_build_locations',
);

sub _build_locations {
    my $self = shift;

    my @locations = map { $_->location . '' } $self->nodes->@*;

    return \@locations;
}

=head2 base_node

Base node

=cut

sub base_node { shift->nodes->[0] }

=head2 type

Type of nodes (taken from base_node)

=cut

sub type { shift->nodes->[0]->type }

=head2 node

Other node

=cut

sub node { shift->nodes->[1] }

=head2 for_node( $location )

Return Diff that has node at given location first. Creates a new Diff
with the nodes swapped, if needed.

=cut

sub for_node {
    my ( $self, $location ) = @_;
    return $self if $self->locations->[0] eq $location . '';

    my $class = ref $self;

    my %args = ( nodes => [ reverse $self->nodes->@* ] );    # shallow copy: same Nodes

    # copy similarity if it exists, to avoid recalculation
    $args{ppi_levenshtein_similarity} = $self->ppi_levenshtein_similarity
      if $self->has_ppi_levenshtein_similarity;

    return $class->new(%args);
}

=head2 identical

Are the two nodes identical?

=cut

has identical => (
    is      => 'ro',
    lazy    => 1,
    isa     => Bool,
    builder => '_build_identical',
);

sub _build_identical {
    my $self = shift;

    my ( $first, $second ) = $self->nodes->@*;

    return $first->crc_hash == $second->crc_hash;
}

=head2 ppi_levenshtein_similarity

Similarity of PPI hashes of the two nodes, as percent

Ranges from 0 (completely different) to 100 (completely identical)

=cut

has ppi_levenshtein_similarity => (
    is        => 'ro',
    lazy      => 1,
    isa       => Int,
    predicate => 'has_ppi_levenshtein_similarity',
    builder   => '_build_ppi_levenshtein_similarity',
);

sub _build_ppi_levenshtein_similarity {
    my $self = shift;

    my $nodes = $self->nodes;

    my $distance = Text::Levenshtein::XS::distance( map { $_->ppi_hash } @$nodes );

    my $max_length = max map { $_->ppi_size } @$nodes;

    return int( 100 * ( $max_length - $distance ) / $max_length );
}

=head2 xdiff

Diff from libxdiff

=cut

has xdiff => (
    is      => 'ro',
    lazy    => 1,
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
    is      => 'ro',
    lazy    => 1,
    isa     => Num,
    builder => '_build_diff_lines',
);

sub _build_diff_lines {
    my $self = shift;

    my $xdiff = $self->xdiff;

    my %counts;
    $counts{$_}++ for map { substr( $_, 0, 1 ) } split /\n/, $xdiff;

    my $line_count = max( $counts{'+'} // 0, $counts{'-'} // 0 );

    my @content = map { $_->ppi->content } $self->nodes->@*;

    my @lines = map { [ split /\n/, $_ ] } @content;

    my @line_counts = map { scalar @$_ } @lines;

    my $tot_lines = min @line_counts;

    return $line_count / $tot_lines;
}

=head1 METHODS

=head2 report_lines

Returns a report of the nodes, their location, and their similarity,
as a list of lines

=cut

sub report_lines {
    my $self = shift;

    my @report_lines = (
        "    Location: " . $self->node->location,
        "    Similarity: " . $self->ppi_levenshtein_similarity,
        map { '    ' . $_ }
          split( /\n/, $self->xdiff ),
    );

    return @report_lines;
}

1;
