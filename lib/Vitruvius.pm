package Vitruvius;

use Vitruvius::Skel::Moo;

our $VERSION = '0.01';

use Vitruvius::Types qw< Str Bool Maybe Object InstanceOf >;

use String::CamelCase qw< decamelize >;

use Vitruvius::Container;

=head1 NAME

Vitruvius - tools for code architects

=head1 SYNOPSIS

  # find and report similarities in code
  % vitruvius similarity file ...

=head1 DESCRIPTION

Vitruvius is a framework and set of tools to help the code architect analyze
a code base.

=head2 Tools

Available tools:

=over

=item * find similar code (L<Vitruvius::Analysis::Similarity>)

=back

Planned tools:

=over

=item * find methods that are acting as functions, and vice versa

=item * find methods that could be simpler in a different class

=item * find classes that might need merging or splitting

=back

=back

=head1 EXECUTION

You will typically use these tools from the command line. Each tool is a command
provided by the C<script/vitruvius> script. To see the available commands, use
the C<help> command:

    % vitruvius help
    usage:
        vitruvius <command> [long options...]
        vitruvius help
        vitruvius <command> --help

    short description:
        base class for vitruvius scripts

    global options:
        --jobs                number of parallel jobs to run [Default:"1";
                              Integer]
        --verbose -v          show verbose progress [Flag]
        --config              Path to command config file
        --help -h --usage -?  Prints this usage information. [Flag]

    available commands:
        similarity
        help        Prints this usage information

To see the options available for a specific tool, use the C<--help> option on
that command:

    % vitruvius similarity --help
    usage:
        vitruvius similarity [filenames] [long options...]
        vitruvius help
        vitruvius similarity --help

    parameters:
        filenames  source code files to analyze

    options:
        --jobs                number of parallel jobs to run [Default:"1";
                              Integer]
        --verbose -v          show verbose progress [Flag]
        --base-dir -b         base directory for source code files
        --min-similarity -s   minimum PPI similarity to include in report [
                              Default:"80"; Integer]
        --min-ppi-size -p     minimum PPI size to include in report [Default:"50"
                              ; Integer]
        --config              Path to command config file
        --help -h --usage -?  Prints this usage information. [Flag]

    available subcommands:
        help  Prints this usage information

=head1 CONFIGURATION

Default values for the options can be set in a config file in C<$HOME/.vitruvius>,
using any config file format recognized by L<Config::Any>. For example, using this
as C<$home/.vitruivus/config.yaml> will set the default C<jobs> and C<min-ppi-size>:

    ---
    global:
        jobs: 8
    similarity:
        min_ppi_size: 100

Note: the options need to use the underscored version of the option, as specified
in the C<parameter> and C<option> attributes defined in C<Vitruvius::App::*>,
rather than the hyphenated version of the option as accepted by the command-line.
(This needs to be fixed.)

=head1 RATIONALE

I spend far too much time staring at code trying to analyze its architecture so
that I can figure out where and how to make the changes I need. C<Vitruvius> is
an attempt to automate the automatable parts of that analysis.

=head2 Name

Vitruvius was a notable Roman architect, famous for his Three Virtues (Principles)
of good architecture, which are just as applicable to good software architecture
as they are to physical constructs:

=over

=item * Durability - it should be designed to last

=item * Utility - it should be designed to work

=item * Beauty - it should be designed to be enjoyed

=head1 ARCHITECTURE

To Be Expanded

=head2 Command-line Application

Vitruvius uses L<MooseX::App>, with one module in C<Vitruvius::App> for each
possible action. The C<Vitruvius::App> instances also act as Config instances,
since they have attributes (options or parameters) for all configuration items
that are used for the application.

=head2 Dependency Injection

Vitruvius uses L<Bread::Board> in L<Vitruvius::Container> to provide dependency
injection into the main application classes. This allows injecting the C<config>
object into all of those classes without needing the configuration to be global
or to be passed between all classes.

The integration between L<Vitruvius::App> and L<Vitruvius::Container> is currently
done in this class (C<Vitruvius>).

=head2 Core

The core classes are in L<Vitruvius::Core>, and provide all of the components
needed to load, parse, and compare multiple Perl Files. Although these components
were initially designed to provide what is needed for C<Analysis::Similarity>,
it is hoped that they will also provide what is needed for other analyses.

=head1 ADDING ANALYSES

To Be Documented

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
