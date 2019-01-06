use strict;
use warnings;

use FindBin::libs qw< export=libs >;
use Path::Tiny;
use Test2::Tools::Basic;

my ($test_lib) = grep { m{t/lib} } @libs;

my $lib_dir = path($test_lib, qw< TestsFor Vitruvius > );

my $iter = $lib_dir->iterator;

my $found;
while ( my $mod = $iter->() ) {
    next unless $mod->is_file && $mod->basename =~ /\.pm$/;
    next if $mod =~ m{TestsFor/Vitruvius/Core};
    next if $mod =~ m{TestsFor/Vitruvius/Analysis};
    $found = 1;
    require $mod;
}

pass('No tests for base modules found') unless $found;

done_testing;
