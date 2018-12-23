package Vitruvius::Test;

use strict;
use warnings;

use Import::Into;

use FindBin::libs;

require Data::Dumper;
require Test2::Tools::xUnit;
require Test2::V0;
require Vitruvius::Skel::Moo;

sub import {
    Vitruvius::Skel::Moo->import_into(1);

    Data::Dumper->import::into(1);
    Test2::Tools::xUnit->import::into(1);

    my $test_class = caller;
    my %target;
    if ( $test_class =~ /^TestsFor::(.*)$/ ) {
        $target{'-target'} = $1;
    }
    ( my $class_under_test = $test_class ) =~ s/^TestsFor:://;
    Test2::V0->import::into( 1, %target );
}

1;
