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

=head2 snippet_pairs

All possible pairs of snippets

FIXME - O(n^2)

=cut

has snippet_pairs => (
    is      => 'ro',
    isa     => ArrayRef [ InstanceOf ['Code::Refactor::Diff'] ],
    lazy    => 1,
    builder => '_build_snippet_pairs',
);

sub _build_snippet_pairs {
    my $self = shift;

    my $snippets = $self->snippets;

    my @snippet_pairs;

    for my $i ( 0 .. $#$snippets ) {
        for my $j ( $i .. $#$snippets ) {
            next if $i == $j;
            push @snippet_pairs, Code::Refactor::Diff->new( snippets => [ $snippets->[$i], $snippets->[$j] ] );
        }
    }

    return \@snippet_pairs;
}

=head2 distances

Distances between each snippet pair

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

    for my $pair ( $self->snippet_pairs->@* ) {
        push $distances{ $pair->distance }->@*, $pair;
    }

    return \%distances;
}

1;
