package Vitruvius;

use Vitruvius::Skel::Moo;

our $VERSION = '0.01';

use Vitruvius::Types qw< Str Bool Maybe Object InstanceOf >;

use String::CamelCase qw< decamelize >;

use Vitruvius::Container;

=head1 NAME

Vitruvius - tools for code architect

=head1 SYNOPSIS

  # TBW

=head1 DESCRIPTION

Vitruvius is a set of tools to help the code architect.

=head1 ATTRIBUTES

=head2 config

Configuration: either C<MooseX::App::Message::Envelope> (for help output)
or C<Vitruvius::App::*> (for actual application run)

=cut

has config => (
    is      => 'ro',
    isa     => InstanceOf ['MooseX::App::Message::Envelope'] | InstanceOf ['Vitruvius::App'],
    lazy    => 1,
    builder => '_build_config',
);

sub _build_config {
    my $self = shift;

    # HACK - force "help" and "usage" to do what they say
    # (for some reason, MooseX::App lists this in usage for non-top-level commands,
    # but only implements it for top-level commands?)
    s/^(help|usage)$/--$1/ for @ARGV;

    return resolve('config');
}

=head2 service_path

Service path in L<Vitruvius::Container> that corresponds to the App command class.

Maps C<Vitruvius::App::FooBar::Baz> into C<foo_bar/bar> service name: all components
after C<App> are decamelized and joined by "/".

=cut

has service_path => (
    is      => 'ro',
    lazy    => 1,
    isa     => Maybe [Str],
    builder => '_build_service_path',
);

sub _build_service_path {
    my $self = shift;

    my $config = $self->config;

    my $class = ref $config;

    return unless $class =~ /^Vitruvius::App::(.*)$/;

    my $app_subclass = $1;

    my $service_path = join '/', map { decamelize $_ } split /::/, $app_subclass;

    return $service_path;
}

=head1 service

Service to run (from L<Vitruvius::Container>). Will not be defined if
"config" (MooseX::App) returns a help message instead of an App to run.

=cut

has service => (
    is      => 'ro',
    isa     => Maybe [Object],
    lazy    => 1,
    builder => '_build_service',
);

sub _build_service {
    my $self = shift;

    my $service_path = $self->service_path
      or return;

    return resolve($service_path);
}

=head1 METHODS

=head2 run

Run the app

=cut

sub run {
    my $self = shift;

    my $rc = 0;

    if (my $service = $self->service) {

        # TODO: factor out generic reporting
        say for $service->report_lines->@*;
    }
    else {

        my $config = $self->config;

        # config stringifies into message
        say $config->stringify;

        $rc = $config->exitcode if defined $config->exitcode;
    }

    return $rc;
}

1;
__END__

=head1 AUTHOR

Noel Maddy E<lt>zhtwnpanta@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2018- Noel Maddy

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
