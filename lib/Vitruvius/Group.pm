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

1;
