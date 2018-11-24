package Code::Refactor::TreeData;

use Moo;

use Types::Standard qw{ ArrayRef HashRef InstanceOf Dict };

use Digest::CRC qw{ crc32 };

=head1 PARAMETERS

=head2 ppi

PPI::Node for this abstract syntax tree

=cut

has ppi => (
    is       => 'ro',
    isa      => InstanceOf ['PPI::Node'],
    required => 1,
);

=head1 ATTRIBUTES

=head2 hashes

RENAMEME - hashes of all elements within syntax tree, hashed by stringified element

=cut

has hashes => (
    is       => 'ro',
    isa      => HashRef,
    required => 1,
);

=head2 elements

RENAMEME - arrayrefs of all elements, hashed by element hash

=cut

has elements => (
    is       => 'ro',
    isa      => HashRef [ HashRef [ ArrayRef [ InstanceOf ['PPI::Element'] ] ] ],
    required => 1,
);

sub __make_hash {
    return crc32( join( '||', @_ ) );
}

sub __make_hash_data {
    my ( $elt, $hash_data, $seen ) = @_;
    $seen //= {};

    my $elt_id = do {
        no overloading;    # disable PPI stringification, to get class and refaddr
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
    if ( $elt->isa('PPI::Node') && ( my @children = $elt->children ) ) {
        my @code_children;
        for my $child (@children) {
            if ( __make_hash_data( $child, $hash_data, $seen ) ) {
                push @code_children, $child;
            }
        }

        # build hash from hashes of all children
        $hash = __make_hash( map { no overloading; $hash_data->{hashes}->{$_} } @code_children );
    }
    else {
        $hash = __make_hash( $elt->content );
    }

    $hash_data->{hashes}->{$elt_id} = $hash;
    push @{ $hash_data->{elements}->{ ref $elt }->{$hash} }, $elt;

    return 1;
}

around BUILDARGS => sub {
    my ( $orig, $self, @args ) = @_;
    my $args = $self->$orig(@args);

    my $hash_data = { hashes => {}, elements => {} };
    __make_hash_data( $args->{ppi}, $hash_data );

    return { %$args, %$hash_data };
};

1;
