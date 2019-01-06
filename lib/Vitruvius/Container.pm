package Vitruvius::Container;

use Vitruvius::Skel;

use Bread::Board;

use Vitruvius::Types qw< File >;

use Vitruvius::App;
use Vitruvius::FileSet;
use Vitruvius::Core::NodeSet;
use Vitruvius::Analysis::Similarity;

my $app = container app => as {
    service config => (
        class     => 'Vitruvius::App',
        lifecycle => 'Singleton',
        block     => sub {
            return Vitruvius::App->new_with_command;
        },
    );
    service fileset => (
        class        => 'Vitruvius::FileSet',
        dependencies => ['config'],
    );
    service nodeset => (
        class        => 'Vitruvius::Core::NodeSet',
        dependencies => [ 'config', 'fileset' ],
    );
    service similarity => (
        class        => 'Vitruvius::Analysis::Similarity',
        dependencies => [ 'config', 'nodeset' ],
    );
};

sub get_app {
    my $class = shift;
    return $app;
}

sub get_service {
    my ( $class, $service, %args ) = @_;
    return $class->get_app->resolve( service => $service, parameters => \%args );
}

1;
