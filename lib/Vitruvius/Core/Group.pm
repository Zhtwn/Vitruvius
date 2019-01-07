package Vitruvius::Core::Group;

use Vitruvius::Skel::Moo;

use Vitruvius::Types qw< Str Int Num HashRef ArrayRef VtvDiff VtvNode >;

use List::Util;

use Vitruvius::Core::Diff;
use Vitruvius::Core::Node;

=head1 NAME

Vitruvius::Core::Group - group of diffs from a base node

=head1 SYNOPSIS

    my $group = Vitruvius::Core::Group->new( base_node => $node, diffs => \@diffs );

    # location of base node
    my $location = $group->location;

    # type of base node
    my $type = $group->type;

    # mean of levenshtein distance of PPI hashes from base_node to all diffs
    my $mean = $group->mean;

    # report group
    say for $group->report_lines;

=head1 DESCRIPTION

A C<Core::Group> contains a base node and the diffs from that node to one or more
other nodes, represented as L<Vitruvius::Core::Diff> instances.

It summarizes the differences by using the C<ppi_levenshtein_similarity> calculated
in each C<Core::Diff>, and provides a mean of that similarity over all diffs.

=head1 PARAMETERS

=head2 base_node

Base node used for all diffs

=cut

has base_node => (
    is       => 'ro',
    isa      => VtvNode,
    required => 1,
    handles  => [
        qw<
          type
          location
          >
    ],
);

=head2 diffs

C<Core::Diff> instances for all diffs from base_node

=cut

has diffs => (
    is       => 'ro',
    isa      => ArrayRef [VtvDiff],
    required => 1,
);

=head1 ATTRIBUTES

=head2 count

Number of diffs in group

=cut

has count => (
    is      => 'ro',
    lazy    => 1,
    isa     => Int,
    default => sub { scalar @{ shift->diffs } },
);

=head2 sum

Sum of C<ppi_levenshtein_similarity> for all diffs

=cut

has sum => (
    is      => 'ro',
    lazy    => 1,
    isa     => Int,
    default => sub {
        List::Util::sum( map { $_->ppi_levenshtein_similarity } shift->diffs->@* );
    },
);

=head2 mean

Mean of C<ppi_levenshtein_similarity> for all diffs

=cut

has mean => (
    is      => 'ro',
    lazy    => 1,
    isa     => Num,
    builder => '_build_mean',
);

sub _build_mean {
    my $self = shift;

    return 0 unless $self->count;

    return $self->sum / $self->count;
}

=head1 METHODS

=head2 report_lines

Report of group, as array of lines

=cut

sub report_lines {
    my $self = shift;

    my $type      = $self->type;
    my $ppi_size  = $self->base_node->ppi_size;
    my $base_node = $self->base_node;

    my @report_lines = (
        "SIMILAR: $type (PPI Size: $ppi_size)",
        "  Base Node: " . $base_node->location,
    );

    my $i;
    my @diffs = sort { $b->ppi_levenshtein_similarity <=> $a->ppi_levenshtein_similarity || ($a->node->location . '') cmp ($b->node->location . '')} $self->diffs->@*;
    for my $diff (@diffs) {
        ++$i;
        push @report_lines, "  Node $i:", $diff->report_lines;
    }

    return @report_lines;
}

1;
