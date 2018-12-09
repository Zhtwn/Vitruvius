package Code::Refactor::Node;

use Moo;

use Types::Path::Tiny qw< File Path >;
use Types::Standard qw< Int Str Bool HashRef ArrayRef InstanceOf Tuple Dict Maybe >;

use Digest::CRC qw< crc32 >;
use Hash::Merge;
use List::Util qw< reduce >;
use Perl::Tidy;
use Scalar::Util qw< refaddr >;

use Code::Refactor::Location;
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

=head2 parent

Parent of this node (undef for top-level node)

=cut

has parent => (
    is       => 'ro',
    isa      => Maybe [ InstanceOf ['Code::Refactor::Node'] ],
    weakref  => 1,
    required => 1,
);

=head2 children

Children of this node

=cut

has children => (
    is      => 'rw',
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

=head2 type

Type of Node -- for now, just the reftype of the PPI node

=cut

has type => (
    is      => 'lazy',
    isa     => Str,
    builder => '_build_type',
);

sub _build_type {
    my $self = shift;

    return ref $self->raw_ppi;
}

=head2 ppi_element_hash

PPI structure hash for just this Node

=cut

has ppi_element_hash => (
    is      => 'lazy',
    isa     => Str,
    builder => '_build_ppi_element_hash',
);

sub _build_ppi_element_hash {
    my $self = shift;

    return ppi_type( $self->raw_ppi );
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

    my $hash = $self->ppi_element_hash;

    my $children = $self->children;

    $hash .= '[' . join( '', map { $_->ppi_hash } @$children ) . ']'
      if @$children;

    return $hash;
}

=head2 ppi_hash_length

Length of PPI hash

=cut

has ppi_hash_length => (
    is      => 'lazy',
    isa     => Int,
    builder => '_build_ppi_hash_length',
);

sub _build_ppi_hash_length {
    my $self = shift;

    return length $self->ppi_hash;
}

=head2 sibling_ppi_hashes

PPI hash to the left and right of this node

=cut

has sibling_ppi_hashes => (
    is      => 'lazy',
    isa     => Dict [ left => Str, right => Str ],
    builder => '_build_left_ppi_hash',
);

sub _build_left_ppi_hash {
    my $self = shift;

    my %hashes = ( left => '', right => '' );

    if ( my $parent = $self->parent ) {

        my $siblings = $parent->children;

        my $is_right;
        for my $sibling (@$siblings) {
            if ( refaddr $sibling == refaddr $self) {
                $is_right = 1;
            }
            elsif ($is_right) {
                $hashes{right} .= $sibling->ppi_hash;
            }
            else {
                $hashes{left} .= $sibling->ppi_hash;
            }
        }

        $hashes{left} = $parent->ppi_element_hash . '[' . $hashes{left};
        $hashes{right} .= ']';
    }

    return \%hashes;
}

sub left_ppi_hash { return shift->sibling_ppi_hashes->{left} }

sub right_ppi_hash { return shift->sibling_ppi_hashes->{right} }

has ppi_hashes => (
    is      => 'lazy',
    isa     => HashRef [ ArrayRef [ InstanceOf ['Code::Refactor::Node'] ] ],
    builder => '_build_ppi_hashes',
);

my $merger = Hash::Merge->new('LEFT_PRECEDENT');
$merger->set_clone_behavior(0);

sub _build_ppi_hashes {
    my $self = shift;

    # start with own hash
    my $hashes = { $self->ppi_hash => [ $self ] };

    # merge in hashes of all children
    $hashes = reduce { $merger->merge( $a, $b ) }
    ( $hashes, map { $_->ppi_hashes } $self->children->@* );

    return $hashes;
}

1;
