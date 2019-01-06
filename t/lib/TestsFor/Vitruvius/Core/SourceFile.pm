package TestsFor::Vitruvius::Core::SourceFile;

use FindBin::libs;
use Vitruvius::Test;

use Path::Tiny;
use PPI;

sub test_basics : Test {
    my $test = shift;

    my $filename = __FILE__;

    my $base_dir = path('./t/lib')->absolute;

    my $file;

    ok( lives { $file = $CLASS->new( base_dir => $base_dir, file => $filename ) }, '->new should succeed', $@ . '' );

    isa_ok( $file, [$CLASS], '->new should return correct class' );

    ok( lives { $file->ppi }, '->ppi should succeed' );

    isa_ok( $file->ppi, ['PPI::Node'], '->ppi should return a PPI::Node' );

    ok( lives { $file->tree }, '->tree should succeed' );

    isa_ok( $file->tree, ['Vitruvius::Core::Tree'], '->tree should return a Core::Tree' );
}

1;
