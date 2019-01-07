package Vitruvius::Analysis::Similarity;

use Vitruvius::Skel::Moo;

use Vitruvius::Types qw< Str Int HashRef ArrayRef HasMethods Path VtvNodeSet VtvDiff VtvGroup >;

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Indent   = 1;

use Cwd;
use Hash::Merge;
use List::Util 'min';
use Path::Tiny;

use Vitruvius::Core::Diff;
use Vitruvius::Core::Group;
use Vitruvius::Util qw< parallelize >;

=encoding utf-8

=head1 NAME

Vitruvius::Analysis::Similarity - find code similarity

=head1 SYNOPSIS

    use Vitruvius::Analysis::Similarity;

    my $similarity = Vitruvius::Analysis::Similarity( config => $config, nodeset => $nodeset );

    # write report
    say for $simlarity->report_lines

=head1 DESCRIPTION

C<Vitruvius::Analysis::Similarity> analyzes and reports on the code similarity
between the configured files.

The code similarity is determined by creating a hash of the elements in the PPI
of the code, using only the element type and ignoring the content. In other words,
code with the same structure but different variable or subroutine names is considered
similar.

The similarity is represented as a percentage, from 0 to 100. The minimum interesting
simliarity can be set using the C<min_similarity> option.

For now, the similarity is only calculated for subroutines. All subroutines in
all of the source code files are compared with all other subroutines, and the most
similar subroutines are included in the report.

The similar code snippets are grouped so that each snippet is only in one group,
and the snippets are grouped to maximize the simliarity.

In the report, groups with the highest mean similarity across all snippets are
listed first.

=cut

=head1 PARAMETERS

=head2 config

Configuration for Similarity (a L<Vitruvius::App::Similarity> instance)

Typically injected by L<Vitruvius::Container>

=cut

has config => (
    is       => 'ro',
    isa      => HasMethods [qw< jobs base_dir filenames min_similarity min_ppi_size >],
    required => 1,
    handles  => [qw< jobs base_dir filenames min_similarity min_ppi_size >],
);

=head2 nodeset

Vitruvius::Core::NodeSet with all nodes to be analyzed

Typically injected by L<Vitruvius::Container>

=cut

has nodeset => (
    is       => 'ro',
    isa      => VtvNodeSet,
    required => 1,
    handles  => [qw< nodes >],
);

=head1 ATTRIBUTES

=head2 diffs

Diff instances for all pairs of nodes, hashed by type

=cut

has diffs => (
    is      => 'ro',
    lazy    => 1,
    isa     => ArrayRef [ ArrayRef [VtvDiff] ],
    builder => '_build_diffs',
);

sub _process_node_pair {
    my ( $self, $node_pair, $diffs ) = @_;

    my @nodes      = @$node_pair;                                     # see, a copy
    my $diff       = Vitruvius::Core::Diff->new( nodes => \@nodes );
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

    parallelize(
        log        => $self->log,
        jobs       => $self->jobs,
        message    => "Building " . scalar(@node_pairs) . " diffs",
        input      => \@node_pairs,
        single_sub => sub { $self->_process_node_pair( $_, $diffs ) for @node_pairs },
        child_sub  => sub {
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

    return [ values %$diffs ];
}

=head2 groups

Groups, ordered by something reasonable

=cut

has groups => (
    is      => 'ro',
    lazy    => 1,
    isa     => ArrayRef [VtvGroup],
    builder => '_build_groups',
);

sub _build_groups {
    my $self = shift;

    my $all_diffs = $self->diffs;

    $self->log->info("Building groups...");

    my %nodes_seen;
    my @groups;

    for my $diffs (@$all_diffs) {
        my $base_node = $diffs->[0]->base_node;
        next if $nodes_seen{ $base_node->location };
        push @groups, Vitruvius::Core::Group->new( base_node => $base_node, diffs => $diffs );
        $nodes_seen{$_}++ for map { $_->indexes->@* } @$diffs;
    }

    # sort by descending mean similarity
    return [ sort { $b->mean <=> $a->mean } @groups ];
}

=head2 report_lines

Report of simlar groups found

=cut

has report_lines => (
    is      => 'ro',
    lazy    => 1,
    isa     => ArrayRef [Str],
    builder => '_build_report_lines',
);

sub _build_report_lines {
    my $self = shift;
    return [ map { $_->report_lines } $self->groups->@* ];
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
        $self->log->info("Building $type diffs");
        my @nodes = sort { $a->location . '' cmp $b->location . '' } $all_nodes->{$type}->@*;
        for my $i ( 0 .. $#nodes - 1 ) {
            for my $j ( $i + 1 .. $#nodes ) {
                push @node_pairs, [ $nodes[$i], $nodes[$j] ];
            }
        }
    }

    return @node_pairs;
}

1;
__END__

=head1 AUTHOR

Noel Maddy E<lt>zhtwnpanta@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2018-2019 Noel Maddy

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
