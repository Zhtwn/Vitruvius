package Code::Refactor;

use Moo;

use Types::Standard qw< Str HashRef ArrayRef InstanceOf >;

use Code::Refactor::File;

=head1 PARAMETERS

=head2 filenames

File names to be scanned

=cut

has filenames => (
    is       => 'ro',
    isa      => ArrayRef,
    required => 1,
);

=head1 ATTRIBUTES

=head2 files

Code::Refactor::File instances for all files

=cut

has files => (
    is      => 'lazy',
    isa     => ArrayRef [ InstanceOf ['Code::Refactor::File'] ],
    builder => '_build_files',
);

sub _build_files {
    my $self = shift;

    return [ map { Code::Refactor::File->new( file => $_ ) } $self->filenames->@* ];
}

=head2 distances

FIXME - O(n^2)

=cut

has distances => (
    is      => 'lazy',
    isa     => HashRef [ArrayRef],
    builder => '_build_distances',
);

sub _build_distances {
    my $self = shift;

    # get all snippets from all files
    my @snippets = map { $_->snippets->@* } $self->files->@*;

    my %distances;

    for my $i ( 0 .. $#snippets ) {
        my $first = $snippets[$i];
        for my $j ( $i .. $#snippets ) {
            next if $i == $j;
            my $second   = $snippets[$j];
            my $distance = $first->tlsh->total_diff($second->tlsh);
            push $distances{$distance}->@*, [ $first, $second ];
        }
    }

    return \%distances;
}

1;
