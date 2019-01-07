# NAME

Vitruvius - tools for code architects

# SYNOPSIS

    # find and report similarities in code
    % vitruvius similarity file ...

# DESCRIPTION

Vitruvius is a framework and set of tools to help the code architect analyze
a code base.

## Tools

Available tools:

- find similar code ([Vitruvius::Analysis::Similarity](https://metacpan.org/pod/Vitruvius::Analysis::Similarity))

Planned tools:

- find methods that are acting as functions, and vice versa
- find methods that could be simpler in a different class
- find classes that might need merging or splitting

# EXECUTION

You will typically use these tools from the command line. Each tool is a command
provided by the `script/vitruvius` script. To see the available commands, use
the `help` command:

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

To see the options available for a specific tool, use the `--help` option on
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

# CONFIGURATION

Default values for the options can be set in a config file in `$HOME/.vitruvius`,
using any config file format recognized by [Config::Any](https://metacpan.org/pod/Config::Any). For example, using this
as `$home/.vitruivus/config.yaml` will set the default `jobs` and `min-ppi-size`:

    ---
    global:
        jobs: 8
    similarity:
        min_ppi_size: 100

Note: the options need to use the underscored version of the option, as specified
in the `parameter` and `option` attributes defined in `Vitruvius::App::*`,
rather than the hyphenated version of the option as accepted by the command-line.
(This needs to be fixed.)

# RATIONALE

I spend far too much time staring at code trying to analyze its architecture so
that I can figure out where and how to make the changes I need. `Vitruvius` is
an attempt to automate the automatable parts of that analysis.

## Name

Vitruvius was a notable Roman architect, famous for his Three Virtues (Principles)
of good architecture, which are just as applicable to good software architecture
as they are to physical constructs:

- Durability - it should be designed to last
- Utility - it should be designed to work
- Beauty - it should be designed to be enjoyed

# ARCHITECTURE

To Be Expanded

## Command-line Application

Vitruvius uses [MooseX::App](https://metacpan.org/pod/MooseX::App), with one module in `Vitruvius::App` for each
possible action. The `Vitruvius::App` instances also act as Config instances,
since they have attributes (options or parameters) for all configuration items
that are used for the application.

## Dependency Injection

Vitruvius uses [Bread::Board](https://metacpan.org/pod/Bread::Board) in [Vitruvius::Container](https://metacpan.org/pod/Vitruvius::Container) to provide dependency
injection into the main application classes. This allows injecting the `config`
object into all of those classes without needing the configuration to be global
or to be passed between all classes.

The integration between [Vitruvius::App](https://metacpan.org/pod/Vitruvius::App) and [Vitruvius::Container](https://metacpan.org/pod/Vitruvius::Container) is currently
done in this class (`Vitruvius`).

## Core

The core classes are in [Vitruvius::Core](https://metacpan.org/pod/Vitruvius::Core), and provide all of the components
needed to load, parse, and compare multiple Perl Files. Although these components
were initially designed to provide what is needed for `Analysis::Similarity`,
it is hoped that they will also provide what is needed for other analyses.

# ADDING ANALYSES

To Be Documented

# ATTRIBUTES

## config

Configuration: either `MooseX::App::Message::Envelope` (for help output)
or `Vitruvius::App::*` (for actual application run)

## service\_path

Service path in [Vitruvius::Container](https://metacpan.org/pod/Vitruvius::Container) that corresponds to the App command class.

Maps `Vitruvius::App::FooBar::Baz` into `foo_bar/bar` service name: all components
after `App` are decamelized and joined by "/".

# service

Service to run (from [Vitruvius::Container](https://metacpan.org/pod/Vitruvius::Container)). Will not be defined if
"config" (MooseX::App) returns a help message instead of an App to run.

# METHODS

## run

Run the app

# AUTHOR

Noel Maddy <zhtwnpanta@gmail.com>

# COPYRIGHT

Copyright 2018- Noel Maddy

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

# POD ERRORS

Hey! **The above document had some coding errors, which are explained below:**

- Around line 39:

    &#x3d;back without =over

- Around line 131:

    You forgot a '=back' before '=head1'
