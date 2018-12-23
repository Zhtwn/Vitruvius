package Vitruvius::Types;

use Vitruvius::Skel;

use Type::Library -base;
use Type::Utils -all;

use FindBin::libs qw< export=libs >;
use Path::Tiny;

# include some standard types
BEGIN { extends qw< Types::Standard Types::Common::String Types::Common::Numeric Types::Path::Tiny > }

# declare class types for all Core classes
my ($lib_base) = grep { m{Vitruvius/lib} } @libs;

my $lib_dir = path($lib_base);

my $core_dir = $lib_dir->child( 'Vitruvius', 'Core' );

my $core_iter = $core_dir->iterator( { recurse => 1 } );

while ( my $core_file = $core_iter->() ) {
    next unless $core_file =~ /\.pm$/;
    my $module = $core_file->relative($lib_dir) . '';
    $module =~ s{/}{::}g;
    $module =~ s/\.pm$//;

    (my $type = $module) =~ s/^Vitruvius::Core:://;

    $type = 'Vtv' . $type;

    class_type $type => { class => $module };
}

1;
