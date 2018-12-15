package Code::Refactor;

use Moo;
use v5.16;

use feature 'state';

use Types::Path::Tiny qw< Path >;
use Types::Standard qw< Str Int HashRef ArrayRef InstanceOf >;

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Indent   = 1;

use Cwd;
use Hash::Merge;
use List::MoreUtils 'part';
use List::Util 'min';
use Parallel::ForkManager;
use Path::Tiny;

use Code::Refactor::Diff;
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

    my $filenames = $self->filenames;

    my $files;

    if ( $jobs == 1 ) {
        say "Reading " . scalar(@$filenames) . " files...";
        $files = [ map { Code::Refactor::File->new( base_dir => $base_dir, file => $_ ) } @$filenames ];
    }
    else {
        $self->_parallelize(
            message   => "Reading " . scalar(@$filenames) . " files",
            input     => $self->filenames,
            child_sub => sub {
                my $filenames = shift;

                my $job_files = [];

                for my $filename (@$filenames) {
                    my $file = Code::Refactor::File->new(
                        base_dir => $base_dir,
                        file     => $filename,
                    );
                    $file->nodes;    # force all parsing and building to be done in parallel
                    push @$job_files, $file;
                }

                return $job_files;
            },
            finish_sub => sub {
                my $return = shift;
                push @$files, @$return;
            },
        );
    }
    return $files;
}

=head2 nodes

All nodes from all files, hashed by type

=cut

has nodes => (
    is      => 'lazy',
    isa     => HashRef [ ArrayRef [ InstanceOf ['Code::Refactor::Node'] ] ],
    builder => '_build_nodes',
);

sub _build_nodes {
    my $self = shift;

    say "Building nodes...";

    my $min_ppi_hash_length = $self->min_ppi_hash_length;

    my %nodes;
    my $cnt = 0;

    for my $file ( $self->files->@* ) {
        for my $node ( $file->nodes->@* ) {
            next if $node->ppi_hash_length < $min_ppi_hash_length;
            push $nodes{ $node->type }->@*, $node;
            ++$cnt;
        }
    }

    say "...found $cnt nodes.";
    return \%nodes;
}

=head2 diffs

Diff instance for all pairs of nodes, hashed by type

=cut

has diffs => (
    is      => 'lazy',
    isa     => ArrayRef [ ArrayRef [ InstanceOf ['Code::Refactor::Diff'] ] ],
    builder => '_build_diffs',
);

sub _process_node_pair {
    my ( $self, $node_pair, $diffs ) = @_;

    my @nodes      = @$node_pair;                                     # see, a copy
    my $diff       = Code::Refactor::Diff->new( nodes => \@nodes );
    my $similarity = $diff->ppi_levenshtein_similarity;
    return if $similarity < $self->min_similarity;

    # use for_node() to ensure that the base node is the first one in the Diff
    push $diffs->{$_}->@*, $diff->for_node($_) for $diff->indexes->@*;
}

sub _build_diffs {
    my $self = shift;

    my $min_similarity = $self->min_similarity;

    # build pairs of nodes first, and then paralellize the Diff creation/calculation
    my @node_pairs = $self->_node_pairs;

    my $jobs = $self->jobs;

    my $diffs = {};

    if ( $jobs == 1 ) {
        say "Building " . scalar(@node_pairs) . " diffs...";

        $self->_process_node_pair( $_, $diffs ) for @node_pairs;
    }
    else {
        $self->_parallelize(
            message   => "Building " . scalar(@node_pairs) . " diffs",
            input     => \@node_pairs,
            child_sub => sub {
                my $node_pairs = shift;

                my $job_diffs = {};
                $self->_process_node_pair( $_, $job_diffs ) for @$node_pairs;

                return $job_diffs;
            },
            finish_sub => sub {
                my $return = shift;
                for my $index ( keys %$return ) {
                    push $diffs->{$index}->@*, $return->{$index}->@*;
                }
            },
        );
    }

    return [ values %$diffs ];
}

=head2 groups

Groups, ordered by something reasonable

=cut

has groups => (
    is      => 'lazy',
    isa     => ArrayRef [ InstanceOf ['Code::Refactor::Group'] ],
    builder => '_build_groups',
);

sub _build_groups {
    my $self = shift;

    my $all_diffs = $self->diffs;

    say "Building groups...";

    my %nodes_seen;
    my @groups;

    for my $diffs (@$all_diffs) {
        my $base_node = $diffs->[0]->base_node;
        next if $nodes_seen{ $base_node->location };
        push @groups, Code::Refactor::Group->new( base_node => $base_node, diffs => $diffs );
        $nodes_seen{$_}++ for map { $_->indexes->@* } @$diffs;
    }

    # sort by descending mean similarity
    return [ sort { $b->mean <=> $a->mean } @groups ];
}

=head1 PRIVATE METHODS

=head2 _node_pairs

Build pairs of nodes

=cut

sub _node_pairs {
    my $self = shift;

    my $all_nodes = $self->nodes;

    my @node_pairs;
    for my $type ( keys %$all_nodes ) {
        say "Building $type diffs";
        my @nodes = sort { $a->location . '' cmp $b->location . '' } $all_nodes->{$type}->@*;
        for my $i ( 0 .. $#nodes - 1 ) {
            for my $j ( $i + 1 .. $#nodes ) {
                push @node_pairs, [ $nodes[$i], $nodes[$j] ];
            }
        }
    }

    return @node_pairs;
}

=head2 _parallelize

Run in parallel jobs

=cut

sub _parallelize {
    my ( $self, %args ) = @_;

    my $message    = $args{message};
    my $input      = $args{input};
    my $child_sub  = $args{child_sub};
    my $finish_sub = $args{finish_sub};

    # never use more jobs than we have inputs
    my $jobs = min $self->jobs, scalar @$input;

    say "$message using $jobs jobs...";
    my $i = 0;
    my @input_batches = part { $i++ % $jobs } @$input;

    my $pm = Parallel::ForkManager->new($jobs);

    $pm->run_on_finish(
        sub {
            my ( $pid, $exit_code, $ident, $exit_signal, $core_dump, $return ) = @_;
            if ($return) {
                $finish_sub->($return);
            }
        }
    );

  JOB:
    for my $job_num ( 0 .. $jobs - 1 ) {
        $pm->start and next JOB;

        my $output = $child_sub->( $input_batches[$job_num] );

        $pm->finish( 0, $output );
    }

    $pm->wait_all_children;
}

1;
