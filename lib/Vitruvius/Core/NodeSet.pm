package Vitruvius::Core::NodeSet;

use Vitruvius::Skel::Moo;

use Vitruvius::Types qw< ArrayRef HashRef InstanceOf HasMethods VtvNode VtvFileSet >;

use Vitruvius::Core::Node;

=head1 NAME

Vitruvius::Core::NodeSet - collection of files to be processed

=head1 SYNOPSIS

    my $node_set = Vitruvius::Core::NodeSet->new( config => $config, file_set => $file_set );

    # get all nodes from all files
    my $nodes = $node_set->nodes;

=head1 DESCRIPTION

A C<Core::NodeSet> is a collection of all Nodes for a FileSet.

=head1 PARAMETERS

=head2 config

Configuration object: must provide C<min_ppi_size>

=cut

has config => (
    is       => 'ro',
    isa      => HasMethods [qw< min_ppi_size >],
    required => 1,
);

=head2 file_set

L<Vitruvius::Core::FileSet> to extract nodes from

=cut

has file_set => (
    is       => 'ro',
    isa      => VtvFileSet,
    required => 1,
);

=head1 ATTRIBUTES

=head2 nodes

All nodes from all files, hashed by type

=cut

has nodes => (
    is      => 'ro',
    lazy    => 1,
    isa     => HashRef [ ArrayRef [VtvNode] ],
    builder => '_build_nodes',
);

sub _build_nodes {
    my $self = shift;

    $self->log->info("Building nodes...");

    my $min_ppi_size = $self->config->min_ppi_size;

    my %nodes;
    my $cnt = 0;

    for my $file ( $self->file_set->files->@* ) {
        for my $node ( $file->tree->nodes->@* ) {
            next if $node->ppi_size < $min_ppi_size;
            push $nodes{ $node->type }->@*, $node;
            ++$cnt;
        }
    }

    $self->log->info("...found $cnt nodes.");
    return \%nodes;
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
