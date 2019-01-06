package Vitruvius;

use Vitruvius::Skel::Moo;

our $VERSION = '0.01';

use Vitruvius::Types qw< Bool Maybe Object InstanceOf >;

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

    return Vitruvius::Container->get_service('config');
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

    my $config = $self->config;

    return unless $config->isa('Vitruvius::App');

    return Vitruvius::Container->get_service( $config->service_path );
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
