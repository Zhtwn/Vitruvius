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

    my $subname = '';
    if ( $ppi->class eq 'PPI::Statement::Sub' && $ppi->name ) {
        $subname = "sub " . $ppi->name;
    }
    else {
        my $cur = $ppi;
        while ( $cur->class ne 'PPI::Document' ) {
            if ( $cur->class eq 'PPI::Statement::Sub' && $cur->name ) {
                $subname = "in sub " . $cur->name;
                last;
            }
            $cur = $cur->parent;
        }
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

    my $base_dir = $self->base_dir;
    return join ', ', grep { $_ } ( $self->file->relative($base_dir) . '', $self->subname, 'L' . $self->line_number );
}

1;
