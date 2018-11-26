package Code::Refactor::SnippetGroup;

use Moose;

use Types::Standard qw< Str ArrayRef HashRef InstanceOf >;

use Code::Refactor::Diff;

=head1 PARAMETERS

=head2 class

Class of snippets

=cut

has class => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

=head1 ATTRIBUTES

=head2 snippets

Snippets

=cut

has snippets => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => ArrayRef [ InstanceOf ['Code::Refactor::Snippet'] ],
    default => sub { [] },
    handles => {
        add_snippet => 'push',
    },
);

=head2 diffs

All possible pairs of snippets, as diffs

FIXME - O(n^2)

=cut

has diffs => (
    is      => 'ro',
    isa     => ArrayRef [ InstanceOf ['Code::Refactor::Diff'] ],
    lazy    => 1,
    builder => '_build_diffs',
);

sub _build_diffs {
    my $self = shift;

    my $snippets = $self->snippets;

    my @diffs;

    for my $i ( 0 .. $#$snippets ) {
        for my $j ( $i .. $#$snippets ) {
            next if $i == $j;

            my $first  = $snippets->[$i];
            my $second = $snippets->[$j];

            # HACK - only look at different files
            next if $first->file eq $second->file;
            push @diffs, Code::Refactor::Diff->new( snippets => [ $first, $second ] );
        }
    }

    return \@diffs;
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
