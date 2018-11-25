package Code::Refactor::TreeData;

use Moo;

use Types::Standard qw{ ArrayRef HashRef InstanceOf Dict };

use Digest::CRC qw{ crc32 };

use Code::Refactor::Tlsh;

=head1 PARAMETERS

=head2 ppi

PPI::Node for this abstract syntax tree

NOTE: all document-level non-code sections are pruned in BUILDARGS

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

my $MIN_CONTENT_LENGTH = 50;

sub __make_hash {
    my $ppi = shift;

    my $content = $ppi->content;

    my $tlsh = Code::Refactor::Tlsh->new;
    $tlsh->final($content, 1);
    my $hash = $tlsh->get_hash;

    return $hash;
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
    return if $elt->isa('PPI::Token::Comment') || $elt->isa('PPI::Token::Whitespace');

    return if length $elt->content < $MIN_CONTENT_LENGTH;

    if ( $elt->isa('PPI::Node') && ( my @children = $elt->children ) ) {
        __make_hash_data( $_, $hash_data, $seen ) for @children;
    }

    if ( my $hash = __make_hash($elt) ) {
        $hash_data->{hashes}->{$elt_id} = $hash;
        push @{ $hash_data->{elements}->{ ref $elt }->{$hash} }, $elt;
    }

    return 1;
}

around BUILDARGS => sub {
    my ( $orig, $self, @args ) = @_;
    my $args = $self->$orig(@args);

    # skip all document-level non-code elements
    my $raw_ppi = $args->{ppi}->clone;

    $raw_ppi->prune(
        sub {
            my ( $top, $elt ) = @_;
            return
                 $elt->isa('PPI::Token::Comment')
              || $elt->isa('PPI::Token::Data')
              || $elt->isa('PPI::Token::End')
              || $elt->isa('PPI::Token::Pod');
        }
    );

    $args->{ppi} = $raw_ppi;

    my $hash_data = { hashes => {}, elements => {} };
    __make_hash_data( $args->{ppi}, $hash_data );

    return { %$args, %$hash_data };
};

1;
