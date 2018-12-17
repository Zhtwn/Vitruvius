package Vitruvius::Analysis::Similarity;

use Moo;
use 5.010;
our $VERSION = '0.01';

use namespace::autoclean;

use MooX::TypeTiny;

use feature 'state';

use Types::Path::Tiny qw< Path >;
use Types::Standard qw< Str Int HashRef ArrayRef InstanceOf HasMethods >;

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Indent   = 1;

use Cwd;
use Hash::Merge;
use List::Util 'min';
use Path::Tiny;

use Vitruvius::Diff;
use Vitruvius::File;
use Vitruvius::FileSet;
use Vitruvius::Group;
use Vitruvius::NodeSet;
use Vitruvius::Util qw< parallelize >;

=encoding utf-8

=head1 NAME

Vitruvius::Analysis::Similarity - find code similarity

=head1 SYNOPSIS

  use Vitruvius::Analysis::Similarity;

=head1 DESCRIPTION

Vitruvius::Analysis::Similarity is fun and incomplete

=cut

=head1 PARAMETERS

=head2 config

Configuration for Similarity

=cut

has config => (
    is       => 'ro',
    isa      => HasMethods [qw< jobs base_dir filenames min_similarity min_ppi_size >],
    required => 1,
    handles  => [qw< jobs base_dir filenames min_similarity min_ppi_size >],
);

=head1 ATTRIBUTES

=head2 fileset

Vitruvius::FileSet with all files to be analyzed

=cut

has fileset => (
    is      => 'ro',
    lazy    => 1,
    isa     => InstanceOf ['Vitruvius::FileSet'],
    builder => '_build_fileset',
);

sub _build_fileset {
    my $self = shift;

    return Vitruvius::FileSet->new( config => $self->config );
}

=head2 nodeset

Vitruvius::NodeSet with all nodes to be analyzed

=cut

has nodeset => (
    is      => 'ro',
    lazy    => 1,
    isa     => InstanceOf ['Vitruvius::NodeSet'],
    builder => '_build_nodeset',
    handles => [qw< nodes >],
);

sub _build_nodeset {
    my $self = shift;

    return Vitruvius::NodeSet->new( config => $self->config, fileset => $self->fileset );
}

=head2 diffs

Diff instance for all pairs of nodes, hashed by type

=cut

has diffs => (
    is      => 'ro',
    lazy    => 1,
    isa     => ArrayRef [ ArrayRef [ InstanceOf ['Vitruvius::Diff'] ] ],
    builder => '_build_diffs',
);

sub _process_node_pair {
    my ( $self, $node_pair, $diffs ) = @_;

    my @nodes      = @$node_pair;                                     # see, a copy
    my $diff       = Vitruvius::Diff->new( nodes => \@nodes );
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
        parallelize(
            jobs      => $self->jobs,
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
    is      => 'ro',
    lazy    => 1,
    isa     => ArrayRef [ InstanceOf ['Vitruvius::Group'] ],
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
        push @groups, Vitruvius::Group->new( base_node => $base_node, diffs => $diffs );
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

1;
__END__

=head1 AUTHOR

Noel Maddy E<lt>zhtwnpanta@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2018- Noel Maddy

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
