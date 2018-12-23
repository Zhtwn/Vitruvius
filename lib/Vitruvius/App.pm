package Vitruvius::App;

use Vitruvius::Skel;

use MooseX::App qw< ConfigHome >;

# BROKEN: autoclean removes "new_with_command"
# use namespace::autoclean;

use Vitruvius::Types qw< Str PositiveInt >;

use String::CamelCase qw< decamelize >;

=head1 NAME

Vitruvius::App - base class for vitruvius scripts

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 GLOBAL OPTIONS

=head2 jobs

Number of jobs to use for parallelizable actions.

Default: 1

=cut

option jobs => (
    is            => 'ro',
    isa           => PositiveInt,
    cmd_aliases   => ['j'],
    default       => 1,
    documentation => 'number of parallel jobs to run',
);

=head1 METHODS

=head2 service_path

Service path in L<Vitruvius::Container> that corresponds to the App command class.

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
