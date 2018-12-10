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
use Code::Refactor::Group;

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

=head2 min_similarity

Minimum "similarity" - defaults to 95

=cut

has min_similarity => (
    is      => 'ro',
    isa     => Int,
    default => 95,
);

=head2 min_ppi_hash_length

Minimum PPI hash length - defaults to 100

=cut

has min_ppi_hash_length => (
    is      => 'ro',
    isa     => Int,
    default => 400,
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
                $file->node_ppi_hashes;    # force all building to be done in parallel
                push @$job_files, $file;
            }

            $pm->finish( 0, $job_files );
        }

        $pm->wait_all_children;

        return \@files;
    }
}

=head2 nodes

All nodes from all files

=cut

has nodes => (
    is      => 'lazy',
    isa     => ArrayRef [ InstanceOf ['Code::Refactor::Node'] ],
    builder => '_build_nodes',
);

sub _build_nodes {
    my $self = shift;

    say "Building nodes...";

    my $min_ppi_hash_length = $self->min_ppi_hash_length;

    return [ grep { $_->ppi_hash_length >= $min_ppi_hash_length } map { $_->nodes->@* } $self->files->@* ];
}

=head2 node_diffs

Diff instance for all pairs of nodes

=cut

has node_diffs => (
    is      => 'lazy',
    isa     => ArrayRef [ InstanceOf ['Code::Refactor::Diff'] ],
    builder => '_build_node_diffs',
);

sub _build_node_diffs {
    my $self = shift;

    my $nodes = $self->nodes;

    say "Building node_diffs for " . $#$nodes . " nodes...";

    my @node_diffs;

    for my $i ( 0 .. $#$nodes - 1 ) {
        for my $j ( $i + 1 .. $#$nodes ) {
            push @node_diffs, Code::Refactor::Diff->new( nodes => [ $nodes->[$i], $nodes->[$j] ] );
        }
    }

    return \@node_diffs;
}

=head2 node_hashes

All nodes from all files, grouped by node type and hash value

=cut

has node_hashes => (
    is      => 'lazy',
    isa     => HashRef [ HashRef [ ArrayRef [ InstanceOf ['Code::Refactor::Node'] ] ] ] ,
    builder => '_build_node_hashes',
);

sub _build_node_hashes {
    my $self = shift;

    say "Merging nodes";
    state $merger = do {
        my $m = Hash::Merge->new('LEFT_PRECEDENT');
        $m->set_clone_behavior(0);  # do not clone internally (preserves PPI objects)
        $m;
    };

    my $hashes = reduce { $merger->merge($a, $b) } map { $_->node_ppi_hashes } $self->files->@*;

    return $hashes;
}

=head2 similar_diffs

FIXME: similar Diffs, hashed by type and base Node

=cut

has similar_diffs => (
    is      => 'lazy',
    isa     => HashRef [ HashRef [ ArrayRef [ InstanceOf ['Code::Refactor::Diff'] ] ] ],
    builder => '_build_similar_diffs',
);

sub _build_similar_diffs {
    my $self = shift;

    my $node_diffs = $self->node_diffs;

    say "Building similar_diffs for " . $#$node_diffs . " node_diffs...";

    # find all Diffs with the same base Node that are "similar"
    my $min_similarity = $self->min_similarity;

    my $cnt;

    my %similar_diffs;

    for my $node_diff (@$node_diffs) {
        say "$cnt processed..." unless ++$cnt % 10;
        my $similarity = $node_diff->ppi_levenshtein_similarity;
        next if $similarity < $min_similarity;

        my $type = $node_diff->type;

        push $similar_diffs{$type}->{ $node_diff->nodes->[0] }->@*, $node_diff;
    }

    return \%similar_diffs;
}

=head2 groups

FIXME: this is where the magic is supposed to happen: find similar Nodes

=cut

has groups => (
    is      => 'lazy',
    isa     => ArrayRef [ InstanceOf ['Code::Refactor::Group'] ],
    builder => '_build_groups',
);

sub _build_groups {
    my $self = shift;

    my $similar_diffs = $self->similar_diffs;

    say "Building groups...";

    my @groups;

    for my $type ( keys %$similar_diffs ) {
        my $diffs_by_node = $similar_diffs->{$type};

        for my $diffs ( values %$diffs_by_node ) {
            push @groups, Code::Refactor::Group->new(diffs => $diffs);
        }
    }

    # FIXME - how should groups be sorted?
#   @groups = sort { $b->base_node->ppi_hash_length <=> $a->base_node->ppi_hash_length } @groups;
    return \@groups;
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
