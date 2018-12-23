package Vitruvius::Core::NodeSet;

use Moo;
use 5.010;

use namespace::autoclean;

use MooX::TypeTiny;

use Types::Standard qw< ArrayRef HashRef InstanceOf HasMethods >;

use Vitruvius::Core::Node;

=head1 NAME

Vitruvius::Core::NodeSet - collection of files to be processed

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 PARAMETERS

=head2 config

Configuration object: must provide C<min_ppi_size>

=cut

has config => (
    is       => 'ro',
    isa      => HasMethods [qw< min_ppi_size >],
    required => 1,
    handles  => [qw< min_ppi_size >],
);

=head2 fileset

L<Vitruvius::FileSet> to extract nodes from

=cut

has fileset => (
    is      => 'ro',
    isa     => InstanceOf ['Vitruvius::FileSet'],
    handles => [qw< files >],
);

=head1 ATTRIBUTES

=head2 nodes

All nodes from all files, hashed by type

=cut

has nodes => (
    is      => 'ro',
    lazy    => 1,
    isa     => HashRef [ ArrayRef [ InstanceOf ['Vitruvius::Core::Node'] ] ],
    builder => '_build_nodes',
);

sub _build_nodes {
    my $self = shift;

    say "Building nodes...";

    my $min_ppi_size = $self->min_ppi_size;

    my %nodes;
    my $cnt = 0;

    for my $file ( $self->files->@* ) {
        for my $node ( $file->nodes->@* ) {
            next if $node->ppi_size < $min_ppi_size;
            push $nodes{ $node->type }->@*, $node;
            ++$cnt;
        }
    }

    say "...found $cnt nodes.";
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
