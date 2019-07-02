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

    # run from the command line:
    % vitruvius similarity --min_similarity 80 --min_ppi_size 100 --jobs 8 lib/Vitruvius/Core/*.pm

    # in code
    use Vitruvius::Analysis::Similarity;

    my $similarity = Vitruvius::Analysis::Similarity( config => $config, nodeset => $nodeset );

    # process Core::Group instances with similarity
    for my $group ( $similarity->groups->@* ) {
        my $base_node = $group->base_node;
        my $location = $base_node->location;    # human-readable location of code

        my $mean_similarity = $group->mean

        # get Core::Diff instances for all similar nodes
        for my $diff ( $group->diffs->@*) {
            my $similarity = $diff->ppi_levenshtein_similarity;
            my $diff = $diff->xdiff;
        }
    }

    # write default report
    say for $simlarity->report_lines

=head1 DESCRIPTION

C<Vitruvius::Analysis::Similarity> analyzes and reports on the code similarity
between the specified files.

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

=head2 Output

The report lists all groups of nodes (C<Core::Group>s) that are similar, sorted
by descending mean similarity. Here is some of the output from comparing the
files in C<lib/Vitruvius/Core>.

First, the base Node of the Group is listed:

  SIMILAR: PPI::Statement::Sub (PPI Size: 114)
    Base Node: lib/Vitruvius/Core/SourceFile.pm, sub _build_location_factory, L37

Then, each similar Node is listed, with its location, similarity, and the
diff between the base Node and the similar node. In this example, you can
see that the similarity is 100, because the code structure is identical:
a function that calls a class method passing two arguments, each of which
has a value that is provided by a method call. The only differences here
are the names: the function name, the class name, the argument names, and
the method names.

Note: To suppress detection of these possible false positives, set the
the C<min-ppi-size> option above its default of 50 when running the
tool (C<vitruvius similarity --min-ppi-size 200 FILE ...>).

    Node 1:
      Location: lib/Vitruvius/Core/SourceFile.pm, sub _build_tree, L89
      Similarity: 100
      @@ -1,8 +1,8 @@
      -sub _build_location_factory {
      +sub _build_tree {
           my $self = shift;

      -    return Vitruvius::Core::LocationFactory->new(
      -        base_dir => $self->base_dir,
      -        file     => $self->file,
      +    return Vitruvius::Core::Tree->new(
      +        location_factory => $self->location_factory,
      +        ppi              => $self->ppi,
           );
       }

The second similar Node in this report is also likely a false positive:

    Node 2:
      Location: lib/Vitruvius/Core/Diff.pm, sub _build_xdiff, L109
      Similarity: 82
      @@ -1,8 +1,5 @@
      -sub _build_location_factory {
      +sub _build_xdiff {
           my $self = shift;

      -    return Vitruvius::Core::LocationFactory->new(
      -        base_dir => $self->base_dir,
      -        file     => $self->file,
      -    );
      +    return Diff::LibXDiff->diff( map { $_->raw_content } $self->nodes->@* );
       }

=head1 RATIONALE

Large or legacy code bases often have many cases where one block of code that works
has been copied and perhaps slightly changed. This code similarity can make
maintenance work a lot harder if something in that block of code needs to be
changed or fixed.

The C<Analysis::Similarity> tool tries to find such similarity across the code
base, allowing the needed changes to be made in each place it occurs, or allowing
the code to be refactored to remove the code duplication.

=head1 TODO

=head2 Provide better examples of useful detection

The current examples in this documentation only show similarities that should
be considered false positives. Replace them with examples that show useful
detected similarities.

=head2 Allow comparison of non-sub code

Currently, C<Analysis::Similarity> only compares subroutines between the files.
This filtering happens in L<Vitruvius::Core::Tree>, where the Nodes to be included
are filtered using C<Util::is_interesting>, which only includes C<PPI::Statement::Sub>
nodes. This needs to be parameterized so that similarity of other structures
such as C<PPI::Structure::Block> can also be detected.

=head2 Allow specification of a desired code snippet

Instead of finding all similarities across the specified files, it would be
useful to be able to specify a base code snippet (e.g., a subroutine or a
block of code) and be able to find all similar instances in the code base.
This would involve having a way to specify the base snippet (perhaps by
file name, type, and line number) and use that as the base Node when building
the Diffs and Groups.

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

    # only include Diffs that are at or above minimum similarity
    return if $similarity < $self->min_similarity;

    # use for_node() to ensure that the base node is the first one in the Diff
    push $diffs->{$_}->@*, $diff->for_node($_) for $diff->locations->@*;
}

sub _build_diffs {
    my $self = shift;

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

            for my $node_pair ( @$node_pairs ) {
                $self->_process_node_pair( $node_pair, $job_diffs );

                # FIXME - Code->ppi->content does not survive fork, so prebuild content and raw_content
                $_->raw_content for @$node_pair;
                $_->content for @$node_pair
            }

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
        $nodes_seen{$_}++ for map { $_->locations->@* } @$diffs;
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
