package Vitruvius::Core::Node;

use Vitruvius::Skel::Moo;

extends 'Vitruvius::Core::Base';

use Vitruvius::Types qw< Int Str ArrayRef InstanceOf Maybe VtvNode >;

use Digest::CRC qw< crc32 >;
use Perl::Tidy;

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

=head2 ppi

PPI for this node

=cut

has ppi => (
    is       => 'ro',
    isa      => InstanceOf ['PPI::Element'],
    required => 1,
    handles  => ['class'],
);

=head2 parent

Parent of this node (undef for top-level node)

=cut

has parent => (
    is       => 'ro',
    isa      => Maybe [VtvNode],
    weak_ref => 1,
    required => 1,
);

=head2 children

Children of this node

Can be set after construction, to allow Tree to be built reasonably

=cut

has children => (
    is      => 'rw',
    isa     => ArrayRef [VtvNode],
    default => sub { return []; },
);

=head1 ATTRIBUTES

=head2 type

Type of Node -- for now, just the reftype of the PPI node

=cut

has type => (
    is      => 'ro',
    lazy    => 1,
    isa     => Str,
    default => sub { shift->ppi->class },
);

=head2 raw_ppi

PPI for this Node, excluding comments

=cut

has raw_ppi => (
    is      => 'ro',
    lazy    => 1,
    isa     => InstanceOf ['PPI::Element'],
    builder => '_build_raw_ppi',
);

sub _build_raw_ppi {
    my $self = shift;

    my $raw_ppi = $self->ppi;

    return $raw_ppi
      unless $raw_ppi->can('prune');

    $raw_ppi = $raw_ppi->clone;

    $raw_ppi->prune('PPI::Token::Comment');

    return $raw_ppi;
}

=head2 raw_content

Code content of C<raw_ppi>, run through L<Perl::Tidy> for whitespace standardization

=cut

has raw_content => (
    is      => 'ro',
    lazy    => 1,
    isa     => Str,
    builder => '_build_raw_content',
);

sub _build_raw_content {
    my $self = shift;

    my $raw_content = $self->raw_ppi->content;

    if ( $self->class eq 'PPI::Statement::Sub' ) {
        my ( $tidy_content, $stderr );

        my $perltidy_error =
          Perl::Tidy::perltidy( argv => '-se -nst', stderr => \$stderr, source => \$raw_content, destination => \$tidy_content );

        $raw_content = $tidy_content
          unless $perltidy_error;
    }

    return $raw_content;
}

=head1 ATTRIBUTES

=head2 crc_hash

CRC32 hash for raw code snippet

=cut

has crc_hash => (
    is      => 'ro',
    lazy    => 1,
    isa     => Int,
    builder => '_build_crc_hash',
);

sub _build_crc_hash {
    my $self = shift;

    return crc32( $self->raw_content );
}

=head2 ppi_element_hash

PPI structure hash for just this Node

=cut

has ppi_element_hash => (
    is      => 'ro',
    lazy    => 1,
    isa     => Str,
    builder => '_build_ppi_element_hash',
);

sub _build_ppi_element_hash {
    my $self = shift;

    return ppi_type( $self->type );
}

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

1;
