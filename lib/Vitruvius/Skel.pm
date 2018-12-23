package Vitruvius::Skel;

use strict;
use warnings;

use Import::Into;

sub import {
    my $class = shift;

    $class->import_into(1);
}

sub import_into {
    my ( $class, $level ) = @_;

    $level += 1;

    strict->import::into($level);
    warnings->import::into($level);
    utf8->import::into($level);
    feature->import::into( $level, ':5.10' );
}

1;
