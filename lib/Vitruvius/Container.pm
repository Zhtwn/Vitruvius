package Vitruvius::Container;

use Vitruvius::Skel;

use Bread::Board;

use Vitruvius::Types qw< File >;

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

sub get_service {
    my ( $class, $service, %args ) = @_;
    return $app->resolve( service => $service, %args );
}

1;
# FIXME - do I want this to be an exporter with a method that provides $app?

