package Code::Refactor::File;

use Moo;
use v5.16;

use Types::Path::Tiny qw< File Path >;
use Types::Standard qw{ HashRef ArrayRef InstanceOf };

use PPI;

use Code::Refactor::Snippet;
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

=head2 snippets

Code snippets from file

=cut

has snippets => (
    is      => 'lazy',
    isa     => ArrayRef [ InstanceOf ['Code::Refactor::Snippet'] ],
    builder => '_build_snippets',
);

sub _build_snippets {
    my $self = shift;

    say "Building snippets: " . $self->file->relative( $self->base_dir );
    my @stack = ( $self->ppi );
    my @snippets;

    my $base_dir = $self->base_dir;
    my $file     = $self->file;

    while ( my $ppi = shift @stack ) {
        if ( $ppi->can('children') && ( my @children = $ppi->children ) ) {
            push @stack, @children;
        }

        next unless is_interesting($ppi);

        my $snippet = Code::Refactor::Snippet->new(
            base_dir => $base_dir,
            file     => $file,
            ppi      => $ppi,
        );

        push @snippets, $snippet
          if $snippet->is_valid;
    }

    return \@snippets;
}

=head2 snippet_hashes

Snippets grouped by class and hashed value (using multiple hash types)

=cut

has snippet_hashes => (
    is      => 'lazy',
    isa     => HashRef [ HashRef [ HashRef [ ArrayRef [ InstanceOf ['Code::Refactor::Snippet'] ] ] ] ],
    builder => '_build_snippet_hashes',
);

sub _build_snippet_hashes {
    my $self = shift;

    say "Building snippets hashes: " . $self->file->relative( $self->base_dir );
    my %hashes;
    for my $snippet ( $self->snippets->@* ) {
        my $class  = $snippet->class;
        my $hashes = $snippet->hashes;
        for my $type ( keys %$hashes ) {
            my $hash = $hashes->{$type};
            push $hashes{$class}->{$type}->{$hash}->@*, $snippet;
        }
    }

    return \%hashes;
}

1;
