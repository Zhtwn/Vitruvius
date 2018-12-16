package Vitruvius::Group;

use Moo;

use MooX::TypeTiny;

use Types::Standard qw< Str Int Num HashRef ArrayRef InstanceOf >;

use List::Util;

has base_node => (
    is       => 'ro',
    isa      => InstanceOf ['Vitruvius::Node'],
    required => 1,
    handles  => [qw< type >],
);

has diffs => (
    is       => 'ro',
    isa      => ArrayRef [ InstanceOf ['Vitruvius::Diff'] ],
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

    my $type        = $self->type;
    my $hash_length = $self->base_node->ppi_hash_length;
    my $base_node   = $self->base_node;

    my @report_lines = (
        "SIMILAR: $type (hash length: $hash_length)",
        "  Base Node: " . $base_node->location,
    );

    my $i;
    for my $diff ($self->diffs->@*) {
        ++$i;
        push @report_lines, "  Node $i:", $diff->report_lines;
    }

    return @report_lines;
}

1;
