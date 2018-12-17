package Vitruvius::App::Similarity;

use MooseX::App::Command;
extends 'Vitruvius::App';

use 5.010;

use namespace::autoclean;

use Types::Common::Numeric qw< PositiveInt >;
use Types::Path::Tiny      qw< Dir >;
use Types::Standard        qw< Str ArrayRef InstanceOf >;

use Carp;
use Cwd;
use Path::Tiny;

use Vitruvius::Analysis::Similarity;

option base_dir => (
    is            => 'ro',
    isa           => Dir,
    cmd_flag      => 'base-dir',
    cmd_aliases   => ['b'],
    default       => sub { path( cwd() ); },
    documentation => 'base directory for source code files',
);

option min_similarity => (
    is            => 'ro',
    isa           => PositiveInt,
    cmd_flag      => 'min-similarity',
    cmd_aliases   => ['s'],
    default       => 80,
    documentation => 'minimum PPI similarity to include in report',
);

option min_ppi_size => (
    is            => 'ro',
    isa           => PositiveInt,
    cmd_flag      => 'min-ppi-size',
    cmd_aliases   => ['p'],
    default       => 50,
    documentation => 'minimum PPI size to include in report',
);

parameter filename => (
    is            => 'ro',
    isa           => Str,
    cmd_flag      => 'filenames',
    documentation => 'source code files to analyze',
);

has filenames => (
    is      => 'ro',
    lazy    => 1,
    isa     => ArrayRef [Str],
    builder => '_build_filenames',
);

sub _build_filenames {
    my $self = shift;

    return [ $self->filename, $self->extra_argv->@* ];
}

sub run {
    croak "Run application using Vitruvius::Container->get_service('similarity')";
}

1;
