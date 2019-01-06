package Vitruvius::Core::Location;

use Vitruvius::Skel::Moo;

use Vitruvius::Types qw< Str Int Maybe InstanceOf Dir File Path>;

use Path::Tiny;
use Cwd;

use overload '""' => 'stringify';

=head1 NAME

Vitruvius::Core::Location - location of Node

=head1 SYNOPSIS

    # construction without file
    my $location = Vitruvius::Core::Location->new( ppi => $ppi );

    # construction with file
    my $location = Vitruvius::Core::Location->new(
        ppi      => $ppi,
        base_dir => '/share/src/Project/lib',
        file     => '/share/src/Project/lib/Foo.pm'
    );

    # human-readable location, with filename, subname, and line number
    my $string_location = $location->stringify;

    # or overloaded
    my $string_location = $location . '';

=head1 DESCRIPTION

A C<Vitruvius::Core::Location> specifies the location of a L<Vitruvius::Core::Node>.

It extracts the name of the containing subroutine and the line number in the
file from the provided C<ppi>.

It uses the provided C<base_dir> and C<file> to provide a relative path to
the file.

=head1 PARAMETERS

=head2 base_dir

Base directory for files

=cut

has base_dir => (
    is       => 'ro',
    isa      => Dir,
    coerce   => 1,
);

=head2 file

File of snippet

=cut

has file => (
    is       => 'ro',
    isa      => File,
    coerce   => 1,
);

=head2 ppi

PPI of snippet

=cut

has ppi => (
    is       => 'ro',
    isa      => InstanceOf ['PPI::Element'],
    required => 1,
);

=head1 ATTRIBUTES

=head2 rel_file

File, relative to base directory

=cut

has rel_file => (
    is      => 'ro',
    lazy    => 1,
    isa     => Maybe [Path],
    builder => '_build_rel_file',
);

sub _build_rel_file {
    my $self = shift;

    return unless $self->file && $self->base_dir;

    return $self->file->relative( $self->base_dir );
}

=head2 subname

String representation of related subroutine name

=cut

has subname => (
    is      => 'ro',
    lazy    => 1,
    isa     => Str,
    builder => '_build_subname',
);

sub _build_subname {
    my $self = shift;

    my $ppi = $self->ppi;

    return $ppi->class eq 'PPI::Statement::Sub' && $ppi->name ? $ppi->name : '';
}

=head2 containing_sub

Subroutine containing this ppi

FIXME: bad name

=cut

has containing_sub => (
    is      => 'ro',
    lazy    => 1,
    isa     => Str,
    builder => '_build_containing_sub',
);

sub _build_containing_sub {
    my $self = shift;

    my $subname = '';

    my $cur = $self->ppi;
    while ( $cur->class ne 'PPI::Document' ) {
        if ( $cur->class eq 'PPI::Statement::Sub' && $cur->name ) {
            $subname = $cur->name;
            last;
        }
        $cur = $cur->parent;
    }

    return $subname;
}

=head1 line_number

Line number within file

=cut

has line_number => (
    is      => 'ro',
    lazy    => 1,
    isa     => Int,
    builder => '_build_line_number',
);

sub _build_line_number {
    my $self = shift;

    my $location = $self->ppi->location;

    my $line_number = $location->[0];

    return $line_number;
}

=head2 as_string

Human-readable location for node, as string

=cut

has as_string => (
    is      => 'ro',
    lazy    => 1,
    isa     => Str,
    builder => '_build_as_string',
);

sub _build_as_string {
    my $self = shift;

    my $sub;

    if ($self->subname) {
        $sub = 'sub ' . $self->subname;
    }
    elsif ($self->containing_sub) {
        $sub = 'in sub ' . $self->containing_sub;
    }
    else {
        $sub = 'no sub';
    }

    my $rel_file = $self->rel_file // '';
    return join ', ', grep { $_ } ( $rel_file . '', $sub, 'L' . $self->line_number );
}

=head1 METHODS

=head2 stringify

String location for node, as overload-callable method

=cut

sub stringify { shift->as_string }

1;
