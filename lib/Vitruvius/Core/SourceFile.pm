package Vitruvius::Core::SourceFile;

use Vitruvius::Skel::Moo;

use Vitruvius::Types qw< HashRef ArrayRef InstanceOf Path File VtvTree VtvLocationFactory >;

use PPI;

use Vitruvius::Core::LocationFactory;
use Vitruvius::Core::Tree;

=head1 NAME

Vitruvius::Core::SourceFile - a single processed Perl file

=head1 SYNOPSIS

    # Constructor
    my $file = Vitruvius::Core::SourceFile->new( base_dir => $base_dir, file => $file );

    # Vitruvius::Tree for file
    my $tree = $file->tree;


=head1 DESCRIPTION

A C<Vitruvius::Core::SourceFile> represents a single parsed Perl code file. It provides
a L<Vitruvius::Core::Tree> representing the code in the file.

=head1 PARAMETERS

=head2 base_dir

Base directory for files

=cut

has base_dir => (
    is       => 'ro',
    isa      => Path,
    required => 1,
    coerce   => 1,
);

=head2 file

File name

=cut

has file => (
    is       => 'ro',
    isa      => File,
    required => 1,
    coerce   => 1,
);

=head1 ATTRIBUTES

=head2 location_factory

Factory to create Location with this base_dir and file

=cut

has location_factory => (
    is      => 'ro',
    lazy    => 1,
    isa     => VtvLocationFactory,
    builder => '_build_location_factory',
);

sub _build_location_factory {
    my $self = shift;

    return Vitruvius::Core::LocationFactory->new(
        base_dir => $self->base_dir,
        file     => $self->file,
    );
}

=head2 ppi

PPI from this file, excluding Data, End, and Pod sections

=cut

has ppi => (
    is      => 'ro',
    lazy    => 1,
    isa     => InstanceOf ['PPI::Node'],
    builder => '_build_ppi',
);

sub _build_ppi {
    my $self = shift;

    my $filename = $self->file . '';    # stringify Path::Tiny obj

    $self->log->info("Reading and parsing " . $self->file->relative( $self->base_dir ));

    my $ppi = PPI::Document->new($filename);

    $ppi->prune(
        sub {
            my ( $top, $elt ) = @_;
            return
                 $elt->isa('PPI::Token::Data')
              || $elt->isa('PPI::Token::End')
              || $elt->isa('PPI::Token::Pod');
        }
    );

    return $ppi;
}

=head2 tree

Code tree

=cut

has tree => (
    is      => 'ro',
    lazy    => 1,
    isa     => InstanceOf [VtvTree],
    builder => '_build_tree',
    handles => [
        qw<
          nodes
          >
    ],
);

sub _build_tree {
    my $self = shift;

    return Vitruvius::Core::Tree->new(
        location_factory => $self->location_factory,
        ppi              => $self->ppi,
    );
}

1;
