package Code::Refactor::File;

use Moo;
use v5.16;

use Types::Path::Tiny qw< File Path >;
use Types::Standard qw{ HashRef ArrayRef InstanceOf };

use PPI;

use Code::Refactor::LocationFactory;
use Code::Refactor::Tree;
use Code::Refactor::Util qw< is_interesting >;

=head1 PARAMETERS

=head2 base_dir

Base directory for files

=cut

has base_dir => (
    is       => 'ro',
    isa      => Path,
    required => 1,
);

=head2 file

File name

=cut

has file => (
    is       => 'ro',
    isa      => File,
    required => 1,
    coerce   => File->coercion,
);

=head1 ATTRIBUTES

=head2 location_factory

Factory to create Location with this base_dir and file

=cut

has location_factory => (
    is      => 'lazy',
    isa     => InstanceOf ['Code::Refactor::LocationFactory'],
    builder => '_build_location_factory',
);

sub _build_location_factory {
    my $self = shift;

    return Code::Refactor::LocationFactory->new(
        base_dir => $self->base_dir,
        file     => $self->file,
    );
}

=head2 ppi

PPI from this file, excluding Data, End, and Pod sections

=cut

has ppi => (
    is      => 'lazy',
    isa     => InstanceOf ['PPI::Node'],
    builder => '_build_ppi',
);

sub _build_ppi {
    my $self = shift;

    my $filename = $self->file . '';    # stringify Path::Tiny obj

    say "Reading and parsing " . $self->file->relative( $self->base_dir );

    my $ppi = PPI::Document->new($filename);

    $ppi->prune(
        sub {
            my ( $top, $elt ) = @_;
            return
                 $self->isa('PPI::Token::Data')
              || $self->isa('PPI::Token::End')
              || $self->isa('PPI::Token::Pod');
        }
    );

    return $ppi;
}

=head2 tree

Code tree

=cut

has tree => (
    is      => 'lazy',
    isa     => InstanceOf ['Code::Refactor::Tree'],
    builder => '_build_tree',
    handles => [
        qw<
          nodes
          node_ppi_hashes
          >
    ],
);

sub _build_tree {
    my $self = shift;

    return Code::Refactor::Tree->new(
        location_factory => $self->location_factory,
        ppi              => $self->ppi,
    );
}

1;
