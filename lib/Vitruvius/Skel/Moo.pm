package Vitruvius::Skel::Moo;

use Vitruvius::Skel;

use Import::Into;

require Moo;
require MooX::TypeTiny;
require namespace::autoclean;

sub import {
    my $class = shift;

    $class->import_into(1);
}

sub import_into {
    my ( $class, $level ) = @_;

    $level += 1;

    Vitruvius::Skel->import_into($level);

    Moo->import::into($level);
    MooX::TypeTiny->import::into($level);
    namespace::autoclean->import::into($level);
}

1;
