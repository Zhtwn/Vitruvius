package Vitruvius::App;

use Vitruvius::Skel;

use MooseX::App qw< ConfigHome >;

with qw< Vitruvius::Role::WithLog >;

# BROKEN: autoclean removes "new_with_command"
# use namespace::autoclean;

use Vitruvius::Types qw< Bool Str PositiveInt >;

use Log::Any::Adapter;
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

=head2 verbose

Enable verbose output

=cut

option verbose => (
    is            => 'ro',
    isa           => Bool,
    cmd_aliases   => ['v'],
    documentation => 'show verbose progress',
);

=head1 ATTRIBUTES

=head2 log_adapter

=cut

has log_adapter => (
    is      => 'ro',
    default => 'Screen',
);

=head2 log_options

Log::Any::Adapter options

=cut

has log_options => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_log_options',
);

sub _build_log_options {
    my $self = shift;

    return {
        min_level => $self->verbose ? 'info' : 'warn',
    };
}

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

=head1 INTERNAL METHODS

=head2 BUILD

Upon construction, initialize Log::Any::Adapter as specified by C<log_adapter>

=cut

sub BUILD {
    my $self = shift;

    Log::Any::Adapter->set( $self->log_adapter, $self->log_options->%* );
}

1;
