use strict;
use warnings;

use FindBin::libs qw< export=libs >;
use Path::Tiny;
use Test2::Tools::Basic;

my ($test_lib) = grep { m{t/lib} } @libs;

my $lib_dir = path($test_lib, qw< TestsFor > );

my $app_file = $lib_dir->child('Vitruvius.pm');

require $app_file;

done_testing;

__END__

use strict;
use warnings;

use FindBin::libs qw< export=libs >;
use Path::Tiny;
use Test2::Tools::Basic;

my $iter = $lib_dir->iterator;

my $found;
while ( my $mod = $iter->() ) {
    next unless $mod->is_file && $mod->basename =~ /\.pm$/;
    $found = 1;
    require $mod;
}

pass('No tests for analysis modules found') unless $found;

done_testing;
