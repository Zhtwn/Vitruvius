package TestsFor::Vitruvius::Location;

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

    my @cases = (
        {
            name => 'full document',
            args => {
                ppi      => $ppi_document,
                base_dir => $base_dir,
                file     => $file,
            },
            stringified => 'TestsFor/Vitruvius/Location.pm, no sub, L1',
        },
        {
            name => 'first sub',
            args => {
                ppi      => $ppi_sub,
                base_dir => $base_dir,
                file     => $file,
            },
            stringified => 'TestsFor/Vitruvius/Location.pm, sub test_basics, L11',
        },
        {
            name => 'first block in sub',
            args => {
                ppi      => $ppi_block,
                base_dir => $base_dir,
                file     => $file,
            },
            stringified => 'TestsFor/Vitruvius/Location.pm, in sub test_basics, L11',
        },
        {
            name => 'first block in sub, no base_dir',
            args => {
                ppi      => $ppi_block,
                file     => $file,
            },
            stringified => 'in sub test_basics, L11',
        },
        {
            name => 'first block in sub, no file',
            args => {
                ppi      => $ppi_block,
                base_dir => $base_dir,
            },
            stringified => 'in sub test_basics, L11',
        },
    );

    for my $case (@cases) {

        subtest $case->{name} => sub {
            my $location;

            ok( lives { $location = $CLASS->new( $case->{args} ) }, '->new should succeed' );

            isa_ok( $location, [$CLASS], '->new should return correct class' );

            is( $location->rel_file, 'TestsFor/Vitruvius/Location.pm', '->rel_file should be correct' )
              if $location->base_dir && $location->file;

            is( $location->stringify, $case->{stringified}, '->stringify should be correct' );
        };
    }
}

1;
