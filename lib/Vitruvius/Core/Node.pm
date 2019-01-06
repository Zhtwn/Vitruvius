package Vitruvius::Core::Node;

use Vitruvius::Skel::Moo;

use Vitruvius::Types qw< Int Str ArrayRef Maybe VtvNode VtvCode VtvLocation >;

use Digest::CRC qw< crc32 >;
use Perl::Tidy;

use Vitruvius::Core::Code;
use Vitruvius::Util qw< ppi_type >;

=head1 NAME

Vitruvius::Core::Node - a Code snippet within a Tree

=head1 SYNOPSIS

    # build Node from PPI, location, and child Nodes
    my $node = Vitruvius::Core::Node->new(
        ppi      => $ppi,
        location => $location_factory->new_location($ppi),
        children => \@child_nodes,
    );

    # set parent for all child nodes
    $_->parent($node) for $node->children->@*;

=head1 DESCRIPTION

A C<Core::Node> represents one Code snippet, in the context of a PPI parse
tree. It contains the location in the file through a C<Location> object,
and its parent and children (if any).

A hashed representation of the PPI code structure of the Code snippet is
provided in C<ppi_hash>. This allows easy detection of common code structures,
even though they may use different variable or subroutine names.

=head1 PARAMETERS

=head2 location

Human-readable location for snippet

=cut

has location => (
    is       => 'ro',
    isa      => VtvLocation,
    required => 1,
);

=head2 code

L<Vitruvius::Core::Code> for this Node

=cut

has code => (
    is       => 'ro',
    isa      => VtvCode,
    required => 1,
    handles  => [
        qw<
          ppi
          type
          content
          raw_ppi
          raw_content
          crc_hash
          ppi_element_hash
          >
    ],
);

=head2 parent

Parent of this node, if any (undefined for top-level node)

Can be set after construction, to allow Tree to be built reasonably
=cut

has parent => (
    is       => 'rw',
    isa      => VtvNode,
    weak_ref => 1,
);

=head2 children

Children of this node

=cut

has children => (
    is      => 'ro',
    isa     => ArrayRef [VtvNode],
    default => sub { return []; },
);

=head2 ppi_hash

Hashed representation of code structure of this Node and all of its
children.

Represents the code structure, excluding all pod and comments.
(Uses C<raw_content> from L<Vitruvius::Core::Code> to ignore pod and comments).

=cut

has ppi_hash => (
    is      => 'ro',
    lazy    => 1,
    isa     => Str,
    builder => '_build_ppi_hash',
);

sub _build_ppi_hash {
    my $self = shift;

    my $hash = $self->ppi_element_hash;

    my $children = $self->children;

    $hash .= '[' . join( '', map { $_->ppi_hash } @$children ) . ']'
      if @$children;

    return $hash;
}

=head2 ppi_size

Length of PPI hash

=cut

has ppi_size => (
    is      => 'ro',
    lazy    => 1,
    isa     => Int,
    builder => '_build_ppi_size',
);

sub _build_ppi_size {
    my $self = shift;

    return length $self->ppi_hash;
}

=head1 INTERNAL METHODS

=head2 around BUILDARGS

If passed a C<ppi>, use it to create a C<Core::Code>

=cut

around BUILDARGS => sub {
    my ( $orig, $self, @args ) = @_;

    my $args = $self->$orig(@args);

    if ( my $ppi = delete $args->{ppi} ) {
        $args->{code} = Vitruvius::Core::Code->new( ppi => $ppi );
    }

    return $args;
};

1;
__END__

=head1 AUTHOR

Noel Maddy E<lt>zhtwnpanta@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2019- Noel Maddy

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
