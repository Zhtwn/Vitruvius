package Vitruvius::Container;

use Vitruvius::Skel;

use parent 'Exporter';

our @EXPORT = qw<
    construct
>;

use Bread::Board;

use Vitruvius::Types qw< Path File Str >;

# NOTE: Bread::Board's class auto-load seems not to be fork-safe,
# so manually load any classes needed by services that need to be
# fork-safe
use Vitruvius::Core::SourceFile;

my $app = container app => as {
    service config => (
        class     => 'Vitruvius::App',
        lifecycle => 'Singleton',
        block     => sub {
            return Vitruvius::App->new_with_command;
        },
    );
    service file_set => (
        class        => 'Vitruvius::Core::FileSet',
        dependencies => ['config'],
    );
    service node_set => (
        class        => 'Vitruvius::Core::NodeSet',
        dependencies => [ 'config', 'file_set' ],
    );
    service similarity => (
        class        => 'Vitruvius::Analysis::Similarity',
        dependencies => [ 'config', 'node_set' ],
    );
    service source_file => (
        class        => 'Vitruvius::Core::SourceFile',
        parameters   => {
            base_dir => { isa => Path, coerce => 1 },
            file     => { isa => File, coerce => 1 },
        },
    );
};

sub construct {
    my ( $service, %args ) = @_;
    return $app->resolve( service => $service, parameters => \%args );
}

1;
