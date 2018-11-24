package Code::Refactor::Tree;

use Moo;

use Types::Standard qw{ ArrayRef HashRef InstanceOf Dict };

use Digest::CRC qw{ crc32 };

=head1 PARAMETERS

=head2 ast

PPI::Node for this abstract syntax tree

=cut

has ast => (
    is       => 'ro',
    isa      => InstanceOf ['PPI::Node'],
    required => 1,
);

=head1 ATTRIBUTES

=head2 bare

RENAMEME - syntax tree without only the code content

=cut

has bare => (
    is      => 'lazy',
    isa     => InstanceOf ['PPI::Node'],
    builder => '_build_bare',
);

sub _build_bare {
    my $self = shift;

    my $bare = $self->ast->clone;

    $bare->prune(
        sub {
            my ( $top, $elt ) = @_;
            return
                 $elt->isa('PPI::Token::Comment')
              || $elt->isa('PPI::Token::Data')
              || $elt->isa('PPI::Token::End')
              || $elt->isa('PPI::Token::Pod');
        }
    );

    return $bare;
}

=head2 raw

RENAMEME - bare syntax tree without whitespace

=cut

has raw => (
    is      => 'lazy',
    isa     => InstanceOf ['PPI::Node'],
    builder => '_build_raw',
);

sub _build_raw {
    my $self = shift;

    my $raw = $self->ast->clone;
    $raw->prune('PPI::Token::Whitespace');

    return $raw;
}

=head2 hashes

RENAMEME - hashes of all elements within raw syntax tree, by stringified element

=head2 elements

RENAMEME - arrayrefs of all elements, by hash

=cut

has _hash_data => (
    is      => 'lazy',
    isa     => Dict [ hashes => HashRef, elements => HashRef [ ArrayRef ['PPI::Element'] ] ],
    builder => '_build__hash_data',
);

sub elements { shift->_hashes->{elements} }

sub hashes { shift->_hashes->{hashes} }

sub __make_hash {
    return crc32( join( '||', @_ ) );
}

sub __make_hash_data {
    my ( $elt, $hash_data, $seen ) = @_;
    $seen //= {};
    return if $seen->{$elt}++;
    my $hash;
    if ( $elt->isa('PPI::Node') ) {
        my @children = $elt->children;

        for my $child (@children) {
            __make_hash_data( $child, $hash_data, $seen );
        }

        # build hash from hashes of all children
        $hash = __make_hash( map { $hash_data->{hashes}->{$_} } @children );
    }
    else {
        $hash = __make_hash( $elt->content );
    }

    $hash_data->{hashes}->{$elt} = $hash;
    push @{ $hash_data->{elements}->{$hash} }, $elt;
}

sub _build_hash_data {
    my $self = shift;

    my $raw = $self->raw;

    my $hash_data = { hashes => {}, elements => {} };
    __make_hash_data( $raw, $hash_data );

    return $hash_data;
}

1;
