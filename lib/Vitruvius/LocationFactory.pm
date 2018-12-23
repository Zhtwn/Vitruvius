package Vitruvius::LocationFactory;

use Vitruvius::Skel::Moo;

use Types::Path::Tiny qw< File Dir >;

use Vitruvius::Location;

=head1 PARAMETERS

=head2 base_dir

Base directory, to be passed into Location

=cut

has base_dir => (
    is       => 'ro',
    isa      => Dir,
    required => 1,
);

=head2

File, to be passed into Location

=cut

has file => (
    is       => 'ro',
    isa      => File,
    required => 1,
);

=head1 METHODS

=head2 new_location

Create new Location for given PPI

=cut

sub new_location {
    my ( $self, $ppi ) = @_;

    return Vitruvius::Location->new(
        base_dir => $self->base_dir,
        file     => $self->file,
        ppi      => $ppi,
    );
}

1;
