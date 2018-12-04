package Code::Refactor::Tree;

use Moo;
use v5.16;

use Types::Path::Tiny qw< File Path >;
use Types::Standard qw{ HashRef ArrayRef InstanceOf };

use PPI;

use Code::Refactor::Snippet;
use Code::Refactor::Util qw< is_interesting >;

=head1 PARAMETERS

=head2 location_factory

Factory to create Location for each node

=cut

has location_factory => (
    is       => 'ro',
    isa      => InstanceOf['Code::Refactor::LocationFactory'],
    required => 1,
    handles  => ['new_location'],
);

=head2 ppi

PPI for this tree, excluding Data, End, and Pod sections

=cut

has ppi => (
    is      => 'lazy',
    isa     => InstanceOf ['PPI::Node'],
    required => 1,
);

=head1 ATTRIBUTES

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

Snippets grouped by class, hash type, and hashed value (using multiple hash types)

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

=head2 root

Root Node of decorated code tree

=cut

has root => (
    is => 'lazy',
    isa => InstanceOf['Code::Refactor::Node'],
    builder => '_build_root',
    handles => ['ppi_hashes'],
);

sub _tree_node {
    my ($self, $ppi) = @_;

    my $children = [];
    if ($ppi->can('children') && $ppi->children) {
        $children = map { $self->_tree_node($_) } $ppi->children;
    }

    return Code::Refactor::Node->new(
        location => $self->new_location($ppi),
        ppi      => $ppi,
        children => $children,
    );
}


sub _build_root {
    my $self = shift;

    say "Building tree " . $self->file->relative( $self->base_dir );

    return $self->_tree_node($self->ppi);
}

1;
