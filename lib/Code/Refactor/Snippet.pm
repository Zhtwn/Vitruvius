package Code::Refactor::Snippet;

use Moo;

use Types::Path::Tiny qw< File >;
use Types::Standard qw< Int Str Bool HashRef ArrayRef InstanceOf Tuple >;

use Digest::CRC qw< crc32 >;
use Perl::Tidy;

use Code::Refactor::Location;
use Code::Refactor::Tlsh;
use Code::Refactor::Util qw< hash_ppi >;

=head1 PARAMETERS

=head2 file

File

=cut

has file => (
    is       => 'ro',
    isa      => File,
    required => 1,
);

=head2 ppi

PPI for this snippet

=cut

has ppi => (
    is       => 'ro',
    isa      => InstanceOf ['PPI::Element'],
    required => 1,
    handles  => [qw< content class >],
);

=head2 min_content_length

Minimum content length for a snippet, in characters

Defaults to 200

Must be >= 50, since TLSH is not valid below that

=cut

has min_content_length => (
    is      => 'ro',
    isa     => Int,
    default => 200,
);

=head1 ATTRIBUTES

=head2 location

Human-readable location for snippet

=cut

has location => (
    is      => 'lazy',
    isa     => InstanceOf['Code::Refactor::Location'],
    builder => '_build_location',
);

sub _build_location {
    my $self = shift;

    return Code::Refactor::Location->new( file => $self->file, ppi => $self->ppi );
}

=head2 raw_ppi

PPI for comparison: excludes comments

=cut

has raw_ppi => (
    is      => 'lazy',
    isa     => InstanceOf ['PPI::Element'],
    builder => '_build_raw_ppi',
);

sub _build_raw_ppi {
    my $self = shift;

    my $ppi = $self->ppi->clone;

    if ( $ppi->can('prune') ) {
        $ppi->prune('PPI::Token::Comment');
    }

    return $ppi;
}

=head2 raw_content

Code content of C<raw_ppi>, run through L<Perl::Tidy> for whitespace standardization

=cut

has raw_content => (
    is      => 'lazy',
    isa     => Str,
    builder => '_build_raw_content',
);

sub _build_raw_content {
    my $self = shift;

    my $ppi_content = $self->raw_ppi->content;

    my $raw_content;

    my $perltidy_error = Perl::Tidy::perltidy( source => \$ppi_content, destination => \$raw_content );

    return $perltidy_error ? $ppi_content : $raw_content;
}

=head2 is_valid

Is this snippet valid (i.e., is it long enough to compare?)

=cut

has is_valid => (
    is      => 'lazy',
    isa     => Bool,
    builder => '_build_is_valid',
);

sub _build_is_valid {
    my $self = shift;

    return length( $self->raw_ppi->content ) >= $self->min_content_length;
}

=head2 hashes

Hashes of raw PPI structure, excluding comments and whitespace, using different hash methods:

=over

=item * CRC - crc32 hash of raw code content

=item * PPI - hash of PPI structure

=item * TLSH - TLSH hash of raw code content

=back

=cut

has hashes => (
    is      => 'lazy',
    isa     => HashRef [Str],
    builder => '_build_hashes',
);

sub _build_hashes {
    my $self = shift;

    my $raw_ppi = $self->raw_ppi;

#   my $full_hash = $self->tlsh->get_hash;

    # HACK - strip off the length/Q ratios from the hash (first 6 chars)
#   my $tlsh_hash = substr $full_hash, 6;

    return {
#       CRC  => crc32( $raw_ppi->content ),
        PPI  => hash_ppi($raw_ppi),
#       TLSH => $tlsh_hash,
    };
}

# my kingdom for a Moo::Meta::Attribute::Native::Trait::Hash ...

=head2 crc_hash

CRC32 hash for raw code snippet

=cut

sub crc_hash { shift->hashes->{CRC} }

=head2 ppi_hash

PPI structure hash for raw code snippet

=cut

sub ppi_hash   { shift->hashes->{PPI} }

=head2 tlsh_hash

TLSH hash for code snippet

=cut

sub tlsh_hash  { shift->hashes->{TLSH} }

=head2 tlsh

Code::Refactor::Tlsh instance - used to build TLSH hash

=cut

has tlsh => (
    is      => 'lazy',
    isa     => InstanceOf['Code::Refactor::Tlsh'],
    builder => '_build_tlsh',
);

sub _build_tlsh {
    my $self = shift;

    my $tlsh = Code::Refactor::Tlsh->new;
    $tlsh->final( $self->raw_ppi->content, 1 );

    return $tlsh;
}

1;
