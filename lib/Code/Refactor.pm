package Code::Refactor;

use Moo;
use v5.16;

use feature 'state';

use Types::Path::Tiny qw< Path >;
use Types::Standard qw< Str Int HashRef ArrayRef InstanceOf >;

use Cwd;
use Hash::Merge;
use List::MoreUtils 'part';
use List::Util 'reduce';
use Parallel::ForkManager;
use Path::Tiny;

use Code::Refactor::File;
use Code::Refactor::SnippetGroup;

=head1 PARAMETERS

=head2 jobs

Number of jobs to use to parse files

Default: 1

=cut

has jobs => (
    is      => 'ro',
    isa     => Int,
    default => 1,
);

=head2 base_dir

Base directory for all files

Default: C<cwd>

=cut

has base_dir => (
    is      => 'ro',
    isa     => Path,
    default => sub { path( cwd() ) },
);

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

    my $base_dir = $self->base_dir;

    my $jobs = $self->jobs;

    if ( $jobs == 1 ) {
        return [ map { Code::Refactor::File->new( base_dir => $base_dir, file => $_ ) } $self->filenames->@* ];
    }
    else {
        # partition files across jobs
        my $i = 0;
        my @filename_batches = part { $i++ % $jobs } $self->filenames->@*;

        my @files;

        my $pm = Parallel::ForkManager->new($jobs);

        $pm->run_on_finish(
            sub {
                my ( $pid, $exit_code, $ident, $exit_signal, $core_dump, $job_files ) = @_;
                if ($job_files) {
                    push @files, @$job_files;
                }
            }
        );

      JOB:
        for my $job_num ( 0 .. $jobs - 1 ) {
            $pm->start and next JOB;

            my $job_files = [];
            for my $filename ( $filename_batches[$job_num]->@* ) {
                my $file = Code::Refactor::File->new(
                    base_dir => $base_dir,
                    file     => $filename,
                );
                $file->snippet_hashes;    # force all building to be done in parallel
                push @$job_files, $file;
            }

            $pm->finish( 0, $job_files );
        }

        $pm->wait_all_children;

        return \@files;
    }
}

=head2 snippet_hashes

All snippets from all files, grouped by class and all hash types

=cut

has snippet_hashes => (
    is      => 'lazy',
    isa     => HashRef [ HashRef [ HashRef [ ArrayRef [ InstanceOf ['Code::Refactor::Snippet'] ] ] ] ],
    builder => '_build_snippet_hashes',
);

sub _build_snippet_hashes {
    my $self = shift;

    my @files = $self->files->@*;
    my @snippet_hashes = map { $_->snippet_hashes } @files;

    state $merger = do {
        my $m = Hash::Merge->new('LEFT_PRECEDENT');
        $m->set_clone_behavior(0);  # do not clone internally (preserves PPI objects)
        $m;
    };

    my $hashes = reduce { $merger->merge($a, $b) } @snippet_hashes;

    return $hashes;
}

=head2 snippet_groups

Snippets grouped by class

=cut

has snippet_groups => (
    is      => 'lazy',
    isa     => HashRef [ InstanceOf ['Code::Refactor::SnippetGroup'] ],
    builder => '_build_snippet_groups',
);

sub _build_snippet_groups {
    my $self = shift;

    my %snippet_groups;

    for my $file ( $self->files->@* ) {
        for my $snippet ( $file->snippets->@* ) {
            my $class = $snippet->class;
            my $group = $snippet_groups{$class} //= Code::Refactor::SnippetGroup->new( class => $class );
            $group->add_snippet($snippet);
        }
    }

    return \%snippet_groups;
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
