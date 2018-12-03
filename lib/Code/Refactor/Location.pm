package Code::Refactor::Location;

use Moo;

use feature 'state';

use Types::Path::Tiny qw< File Path >;
use Types::Standard qw< Str Int InstanceOf >;

use Path::Tiny;
use Cwd;

use overload '""' => 'stringify';

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

File of snippet

=cut

has file => (
    is       => 'ro',
    isa      => InstanceOf ['Path::Tiny'],
    required => 1,
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
    is      => 'lazy',
    isa     => InstanceOf ['Path::Tiny'],
    builder => '_build_rel_file',
);

sub _build_rel_file {
    my $self = shift;

    return $self->file->relative( $self->base_dir );
}

=head2 subname

String representation of related subroutine name

=cut

has subname => (
    is      => 'lazy',
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
    is      => 'lazy',
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
    is      => 'lazy',
    isa     => Int,
    builder => '_build_line_number',
);

sub _build_line_number {
    my $self = shift;

    my $location = $self->ppi->location;

    my $line_number = $location->[0];

    return $line_number;
}

=head1 METHODS

=head2 stringify

Human-readable location for snippet, as string

=cut

sub stringify {
    my $self = shift;

    my $sub = $self->subname ? 'sub ' . $self->subname : 'in sub ' . $self->containing_sub;
    return join ', ', grep { $_ } ( $self->rel_file . '', $sub, 'L' . $self->line_number );
}

1;
