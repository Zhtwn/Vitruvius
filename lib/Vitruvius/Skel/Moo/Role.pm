package Vitruvius::Skel::Moo::Role;

use Vitruvius::Skel;

use Import::Into;

require Moo::Role;
require namespace::autoclean;

sub import {
    my $class = shift;

    Vitruvius::Skel->import_into(1);

    Moo::Role->import::into(1);
    namespace::autoclean->import::into(1);
}

1;
