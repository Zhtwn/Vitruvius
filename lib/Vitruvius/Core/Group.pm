package Vitruvius::Core::Group;

use Moo;

use namespace::autoclean;

use MooX::TypeTiny;

use Types::Standard qw< Str Int Num HashRef ArrayRef InstanceOf >;

use List::Util;

has base_node => (
    is       => 'ro',
    isa      => InstanceOf ['Vitruvius::Core::Node'],
    required => 1,
    handles  => [qw< type >],
);

has diffs => (
    is       => 'ro',
    isa      => ArrayRef [ InstanceOf ['Vitruvius::Core::Diff'] ],
    required => 1,
);

has location => (
    is      => 'ro',
    lazy    => 1,
    isa     => Str,
    default => sub { shift->base_node->location . '' },
);

has count => (
    is      => 'ro',
    lazy    => 1,
    isa     => Int,
    default => sub { scalar @{ shift->diffs } },
);

has sum => (
    is      => 'ro',
    lazy    => 1,
    isa     => Int,
    default => sub {
        List::Util::sum( map { $_->ppi_levenshtein_similarity } shift->diffs->@* );
    },
);

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
