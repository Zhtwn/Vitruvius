package Vitruvius::App;

use MooseX::App qw< ConfigHome >;

# BROKEN: autoclean removes "new_with_command"
# use namespace::autoclean;

use Types::Standard qw< Str>;

use String::CamelCase qw< decamelize >;

=head1 NAME

Vitruvius::App - base class for vitruvius scripts

=cut

has service_path => (
    is      => 'ro',
    lazy    => 1,
    isa     => Str,
    builder => '_build_service_path',
);

sub _build_service_path {
    my $self = shift;

    my $class = ref $self || $self;

    my $base_class = __PACKAGE__;

    ( my $command_name = $class ) =~ s/^${base_class}:://;

    return join '/', map { decamelize $_ } split /::/, $command_name;
}

1;
