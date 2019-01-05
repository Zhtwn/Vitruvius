package Vitruvius::Core::Node;

use Vitruvius::Skel::Moo;

extends 'Vitruvius::Core::Base';

use Vitruvius::Types qw< Int Str ArrayRef InstanceOf Maybe VtvNode VtvCode >;

use Digest::CRC qw< crc32 >;
use Perl::Tidy;

use Vitruvius::Core::Code;
use Vitruvius::Util qw< ppi_type >;

=head1 PARAMETERS

=head2 location

Human-readable location for snippet

=cut

has location => (
    is       => 'ro',
    isa      => InstanceOf ['Vitruvius::Location'],
    required => 1,
);

=head2 code

C<Core::Content> for this Node

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

PPI structure hash for "raw" code (without pod and comments)

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

If passed a C<ppi>, use it to create a C<Core::Content>

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
