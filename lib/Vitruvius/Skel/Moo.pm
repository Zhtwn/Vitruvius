package Vitruvius::Skel::Moo;

use Vitruvius::Skel;

use Import::Into;

require Moo;
require Moo::Role;
require MooX::TypeTiny;
require namespace::autoclean;

sub import {
    my $class = shift;

    $class->import_into(1);
}

# Moo roles to apply
my @moo_roles = qw<
  Vitruvius::Role::WithLog
>;

sub import_into {
    my ( $class, $level ) = @_;

    my $import_level = $level + 1;

    Vitruvius::Skel->import_into($import_level);

    Moo->import::into($import_level);
    MooX::TypeTiny->import::into($import_level);
    namespace::autoclean->import::into($import_level);

    my ($target) = caller($level);
    Moo::Role->apply_roles_to_package( $target, @moo_roles )
}

1;
