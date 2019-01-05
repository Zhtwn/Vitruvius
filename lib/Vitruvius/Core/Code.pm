package Vitruvius::Core::Code;

use Vitruvius::Skel::Moo;

extends 'Vitruvius::Core::Base';

use Vitruvius::Types qw< Int Str ArrayRef InstanceOf Maybe VtvNode >;

use Digest::CRC qw< crc32 >;
use Perl::Tidy;

use Vitruvius::Core::Node;
use Vitruvius::Util qw< ppi_type >;

=head1 NAME

Vitruvius::Core::Code - Data on a code snippet, including PPI

=head1 SYNOPSIS

    # build from PPI
    my $code = Vitruvius::Core::Code->new( ppi => $ppi );

    # get type of code
    my $type = $code->type;

    # get original Perl content
    my $content = $code->content;

    # PPI with comments removed
    my $raw_ppi = $code->raw_ppi;

    # Perl content with comments removed
    my $raw_content = $code->raw_content;

    # get CRC hash of raw content
    my $crc_hash = $code->crc_hash;

    # get encoding of PPI node type (2-char hex)
    my $ppi_element_hash = $code->crc_element_hash

=head1 DESCRIPTION

A C<Vitruvius::Core::Code> instance contains one snippet Perl code, as
represented by a C<PPI> element.

The C<raw_ppi> and C<raw_content> attributes contain the original snippet
with all comments removed, for easier examination and comparision of
Perl code.

=head1 PARAMETERS

=head2 ppi

PPI for this node

Handles C<class> and C<content>

=cut

has ppi => (
    is       => 'ro',
    isa      => InstanceOf ['PPI::Element'],
    required => 1,
    handles  => [qw< class content >],
);

=head1 ATTRIBUTES

=head2 class

Class of C<PPI>. Delegated to C<ppi>.

=head2 content

Content of original C<PPI>. Delegated to C<ppi>.

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

    my ( $tidy_content, $stderr );

    my $perltidy_error =
      Perl::Tidy::perltidy( argv => '-se -nst', stderr => \$stderr, source => \$raw_content, destination => \$tidy_content );

    $raw_content = $tidy_content
      unless $perltidy_error;

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
__END__

=head1 AUTHOR

Noel Maddy E<lt>zhtwnpanta@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2018- Noel Maddy

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
