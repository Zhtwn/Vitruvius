package Vitruvius::LocationFactory;

use Vitruvius::Skel::Moo;

use Vitruvius::Types qw< File Dir >;

use Vitruvius::Core::Location;

=head1 NAME

Vitruvius::LocationFactory - factory for Locations

=head1 SYNOPSIS

    my $factory = Vitruvius::LocationFactory->new(
        base_dir => $base_dir,
        file     => $file,
    );

    my $location = $factory->new_location($ppi);

=head1 DESCRIPTION

A C<LocationFactory> holds the C<base_dir> and C<file> for Nodes that are
from the same source file, and provides a C<new_location> method that creates
a new C<Location> for a given C<PPI>

=head1 PARAMETERS

=head2 base_dir

Base directory, to be passed into Location

=cut

has base_dir => (
    is       => 'ro',
    isa      => Dir,
    required => 1,
    coerce   => 1,
);

=head2

File, to be passed into Location

=cut

has file => (
    is       => 'ro',
    isa      => File,
    required => 1,
    coerce   => 1,
);

=head1 METHODS

=head2 new_location

Create new Location for given PPI

=cut

sub new_location {
    my ( $self, $ppi ) = @_;

    return Vitruvius::Core::Location->new(
        base_dir => $self->base_dir,
        file     => $self->file,
        ppi      => $ppi,
    );
}

1;
