package Vitruvius::Role::App::WithFiles;

use MooseX::App::Role;
use 5.010;

use Types::Path::Tiny      qw< Dir >;
use Types::Standard        qw< Str ArrayRef >;

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

1;
