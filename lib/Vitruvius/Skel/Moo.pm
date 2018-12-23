package Vitruvius::Skel::Moo;

use Vitruvius::Skel;

use Import::Into;

require Moo;
require MooX::TypeTiny;
require namespace::autoclean;

sub import {
    my $class = shift;

    Vitruvius::Skel->import_into(1);

    Moo->import::into(1);
    MooX::TypeTiny->import::into(1);
    namespace::autoclean->import::into(1);
}

1;
