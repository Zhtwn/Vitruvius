package Vitruvius::Container;

use Vitruvius::Skel;

use parent 'Exporter';

our @EXPORT = qw<
    construct
>;

use Bread::Board;

use Vitruvius::Types qw< File Str >;

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
};

sub construct {
    my ( $service, %args ) = @_;
    return $app->resolve( service => $service, parameters => \%args );
}

1;
