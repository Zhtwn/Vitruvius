package TestsFor::Vitruvius;

use FindBin::libs;
use Vitruvius::Test;

use Path::Tiny;

use Vitruvius;

sub base_help : Test {
    my $test = shift;

    local @ARGV = ('help');

    my $vitruvius;

    ok( lives { $vitruvius = $CLASS->new() }, '->new should succeed', $@ . '' );

    isa_ok( $vitruvius, [$CLASS], '->new should return correct class' );

    ok( lives { $vitruvius->run }, '->run should succeed', $@ . '' );
}

sub similarity_help : Test {
    my $test = shift;

    local @ARGV = ( 'similarity', 'help' );

    my $vitruvius;

    ok( lives { $vitruvius = $CLASS->new() }, '->new should succeed', $@ . '' );

    isa_ok( $vitruvius, [$CLASS], '->new should return correct class' );

    ok( lives { $vitruvius->run }, '->run should succeed', $@ . '' );
}

sub single_job : Test {
    my $test = shift;

    my $base_dir = path('./lib')->absolute;

    my $core_dir = path('./lib/Vitruvius/Core');

    my @files = map { $_ . '' } $core_dir->children;

    local @ARGV = (
        'similarity',
        '--jobs', 1,
        @files,
    );

    my $vitruvius;

    ok( lives { $vitruvius = $CLASS->new() }, '->new should succeed', $@ . '' );

    isa_ok( $vitruvius, [$CLASS], '->new should return correct class' );

    ok( lives { $vitruvius->run }, '->run should succeed', $@ . '' );
}

sub multiple_jobs : Test {
    my $test = shift;

    my $base_dir = path('./lib')->absolute;

    my $core_dir = path('./lib/Vitruvius/Core');

    my @files = map { $_ . '' } $core_dir->children;

    local @ARGV = (
        'similarity',
        '--jobs', 2,
        @files,
    );

    my $vitruvius;

    ok( lives { $vitruvius = $CLASS->new() }, '->new should succeed', $@ . '' );

    isa_ok( $vitruvius, [$CLASS], '->new should return correct class' );

    ok( lives { $vitruvius->run }, '->run should succeed', $@ . '' );
}

1;
