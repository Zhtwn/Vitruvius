package Vitruvius::Container;

use Vitruvius::Skel;

use parent 'Exporter';

our @EXPORT = qw<
    resolve
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
    service fileset => (
        class        => 'Vitruvius::Core::FileSet',
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

sub resolve {
    my ( $service, %args ) = @_;
    return $app->resolve( service => $service, parameters => \%args );
}

1;
