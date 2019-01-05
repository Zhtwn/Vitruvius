package TestsFor::Vitruvius::File;

use FindBin::libs;
use Vitruvius::Test;

use Path::Tiny;
use PPI;

use Vitruvius::Util qw< ppi_type >;

sub test_basics : Test {
    my $test = shift;

    my $file = __FILE__;

    my $base_dir = path('./t/lib')->absolute;

    my $tree;

    ok( lives { $file = $CLASS->new( base_dir => $base_dir, file => $file ) }, '->new should succeed' );

    isa_ok( $file, [$CLASS], '->new should return correct class' );

    ok( lives { $file->ppi }, '->ppi should succeed' );

    isa_ok( $file->ppi, ['PPI::Document'], '->ppi should be a PPI::Document' );

    ok( lives { $file->tree }, '->tree should succeed' );

    isa_ok( $file->tree, ['Vitruvius::Core::Tree'], '->tree should return correct class' );

}

1;
__DATA__
FOO
__END__
BAR
