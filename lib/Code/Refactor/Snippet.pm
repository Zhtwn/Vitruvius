package Code::Refactor::Snippet;

use Moo;

use Types::Path::Tiny qw< File >;
use Types::Standard qw< Int Str Bool InstanceOf >;

use Code::Refactor::Tlsh;

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

=head2 raw_ppi

PPI for comparison: excludes comments

=cut

has raw_ppi => (
    is      => 'lazy',
    isa     => InstanceOf ['PPI::Element'],
    builder => '_build_raw_ppi',
    handles => {
        raw_content => 'content',
    },
);

sub _build_raw_ppi {
    my $self = shift;

    my $ppi = $self->ppi->clone;

    if ( $ppi->can('prune') ) {
        $ppi->prune('PPI::Token::Comment');
    }

    return $ppi;
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

=head2 tlsh

Code::Refactor::Tlsh instance

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
    return substr $full_hash, 6;
}

1;
