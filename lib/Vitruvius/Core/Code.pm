package Vitruvius::Core::Code;

use Vitruvius::Skel::Moo;

extends 'Vitruvius::Core::Base';

use Vitruvius::Types qw< Int Str ArrayRef InstanceOf Maybe VtvNode >;

use Digest::CRC qw< crc32 >;
use Perl::Tidy;

use Vitruvius::Util qw< ppi_type >;

=head1 PARAMETERS

=head2 ppi

PPI for this node

=cut

has ppi => (
    is       => 'ro',
    isa      => InstanceOf ['PPI::Element'],
    required => 1,
    handles  => ['class'],
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

1;
