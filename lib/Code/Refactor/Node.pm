package Code::Refactor::Node;

use Moo;

use Types::Path::Tiny qw< File Path >;
use Types::Standard qw< Int Str Bool HashRef ArrayRef InstanceOf Tuple >;

use Digest::CRC qw< crc32 >;
use Hash::Merge;
use List::Util qw< reduce >;
use Perl::Tidy;

use Code::Refactor::Location;
use Code::Refactor::Tlsh;
use Code::Refactor::Util qw< ppi_type hash_ppi >;

=head1 PARAMETERS

=head2 location

Human-readable location for snippet

=cut

has location => (
    is       => 'ro',
    isa      => InstanceOf ['Code::Refactor::Location'],
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

=head2 children

Children of this node

=cut

has children => (
    is      => 'ro',
    isa     => ArrayRef [ InstanceOf ['Code::Refactor::Node'] ],
    default => sub { return []; },
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

    return length( $self->raw_content ) >= $self->min_content_length;
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

    return {
        CRC  => $self->crc_hash,
        PPI  => $self->ppi_hash,
        TLSH => $self->tlsh_hash,
    };
}

=head2 crc_hash

CRC32 hash for raw code snippet

=cut

has crc_hash => (
    is      => 'lazy',
    isa     => Int,
    builder => '_build_crc_hash',
);

sub _build_crc_hash {
    my $self = shift;

    return crc32( $self->raw_content );
}

=head2 ppi_hash

PPI structure hash for "raw" code (without pod and comments)

=cut

has ppi_hash => (
    is      => 'lazy',
    isa     => Str,
    builder => '_build_ppi_hash',
);

sub _build_ppi_hash {
    my $self = shift;

    my $hash = ppi_type( $self->raw_ppi );

    my $children = $self->children;

    $hash .= '[' . join( '', map { $_->ppi_hash } @$children ) . ']'
      if @$children;

    return $hash;
}

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
    $tlsh->final( $self->raw_content, 1 );

    return $tlsh;
}

=head2 tlsh_hash

TLSH hash for code snippet

=cut

has tlsh_hash => (
    is      => 'lazy',
    isa     => Str,
    builder => '_build_tlsh_hash',
);

sub _build_tlsh_hash {
    my $self = shift;

    my $full_hash = $self->tlsh->get_hash;

    # HACK - strip off the length/Q ratios from the hash (first 6 chars)
    my $tlsh_hash = substr $full_hash, 6;

    return $tlsh_hash;
}

has ppi_hashes => (
    is      => 'lazy',
    isa     => HashRef [ ArrayRef [ InstanceOf ['Code::Refactor::Node'] ] ],
    builder => '_build_ppi_hashes',
);

my $merger = Hash::Merge->new('LEFT_PRECEDENT');

sub _build_ppi_hashes {
    my $self = shift;

    # start with own hash
    my $hashes = { $self->ppi_hash => $self };

    # merge in hashes of all children
    $hashes = reduce { $merger->merge( $a, $b ) }
    ( $hashes, map { $_->ppi_hashes } $self->children->@* );

    return $hashes;
}

1;
