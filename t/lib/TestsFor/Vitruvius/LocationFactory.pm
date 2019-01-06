package TestsFor::Vitruvius::LocationFactory;

use FindBin::libs;
use Vitruvius::Test;

use Path::Tiny;
use PPI;

use Vitruvius::Util qw< ppi_type >;

sub test_basics : Test {
    my $test = shift;

    my $file = __FILE__;

    my $base_dir = path('./t/lib')->absolute;

    my $ppi_document = PPI::Document->new($file);

    my ($ppi_sub) = grep { ref $_ eq 'PPI::Statement::Sub' } $ppi_document->children;

    my ($ppi_block) = grep { ref $_ eq 'PPI::Structure::Block' } $ppi_sub->children;

    my $factory;

    ok( lives { $factory = $CLASS->new( base_dir => $base_dir, file => $file ) }, '->new should succeed' );

    isa_ok( $factory, [$CLASS], '->new should return correct class' );

    my @cases = (
        {
            name        => 'full document',
            ppi         => $ppi_document,
            stringified => 'TestsFor/Vitruvius/LocationFactory.pm, no sub, L1',
        },
        {
            name        => 'first sub',
            ppi         => $ppi_sub,
            stringified => 'TestsFor/Vitruvius/LocationFactory.pm, sub test_basics, L11',
        },
        {
            name        => 'first block in sub',
            ppi         => $ppi_block,
            stringified => 'TestsFor/Vitruvius/LocationFactory.pm, in sub test_basics, L11',
        },
    );

    for my $case (@cases) {

        subtest $case->{name} => sub {
            my $location;

            ok( lives { $location = $factory->new_location( $case->{ppi} ) }, '->new_location should succeed' );

            isa_ok( $location, ['Vitruvius::Core::Location'], '->new_location should return Location' );

            is( $location->rel_file, 'TestsFor/Vitruvius/LocationFactory.pm', '->rel_file should be correct' )
              if $location->base_dir && $location->file;

            is( $location->stringify, $case->{stringified}, '->stringify should be correct' );
        };
    }
}

1;
