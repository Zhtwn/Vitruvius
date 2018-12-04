package Code::Refactor::LocationFactory;

use Moo;
use v5.16;

use Types::Path::Tiny qw< Path >;

use Code::Refactor::Location;

=head1 PARAMETERS

=head2 base_dir

Base directory, to be passed into Location

=cut

has base_dir => (
    is       => 'ro',
    isa      => Path,
    required => 1,
);

=head2

File, to be passed into Location

=cut

has file => (
    is => 'ro',
    isa => Path,
    required => 1,
);

=head1 METHODS

=head2 new_location

Create new Location for given PPI

=cut

sub new_location {
    my ( $self, $ppi ) = @_;

    return Code::Refactor::Location->new(
        base_dir => $self->base_dir,
        file     => $self->file,
        ppi      => $ppi,
    );
}

1;
