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

=head2 hashes

RENAMEME - hashes of all elements within syntax tree, hashed by stringified element

=head2 elements

RENAMEME - arrayrefs of all elements, hashed by element hash

=cut

has _hash_data => (
    is      => 'lazy',
    isa     => Dict [ hashes => HashRef, elements => HashRef [ ArrayRef [ InstanceOf ['PPI::Element'] ] ] ],
    builder => '_build__hash_data',
);

sub elements { shift->_hash_data->{elements} }

sub hashes { shift->_hash_data->{hashes} }

sub __make_hash {
    return crc32( join( '||', @_ ) );
}

sub __make_hash_data {
    my ( $elt, $hash_data, $seen ) = @_;
    $seen //= {};

    my $elt_id = do {
        no overloading; # disable PPI stringification, to get class and refaddr
        $elt . '';
    };

    # skip already-seen nodes (JIC)
    return if $seen->{$elt_id}++;

    # skip non-code elements
    return
         if $elt->isa('PPI::Token::Comment')
      || $elt->isa('PPI::Token::Data')
      || $elt->isa('PPI::Token::End')
      || $elt->isa('PPI::Token::Pod')
      || $elt->isa('PPI::Token::Whitespace');

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

    $hash_data->{hashes}->{$elt_id} = $hash;
    push @{ $hash_data->{elements}->{$hash} }, $elt;
}

sub _build_hash_data {
    my $self = shift;

    my $ast = $self->ast;

    my $hash_data = { hashes => {}, elements => {} };
    __make_hash_data( $ast, $hash_data );

    return $hash_data;
}

1;
