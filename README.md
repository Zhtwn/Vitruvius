# NAME

Vitruvius - tools for code architects

# SYNOPSIS

    # find and report similarities in code
    % vitruvius similarity file ...

# DESCRIPTION

Vitruvius is a framework and set of tools to help the code architect.

## Tools

Available tools:

- find similar code ([Vitruvius::Analysis::Similarity](https://metacpan.org/pod/Vitruvius::Analysis::Similarity))

Planned tools:

- find methods that are acting as functions, and vice versa
- find methods that could be simpler in a different class
- find classes that might need merging or splitting

## Name

Vitruvius was a notable Roman architect, famous for his Three Virtues (Principles)
of good architecture, which are just as applicable to good software architecture
as they are to physical constructs:

- Durability - it should be designed to last
- Utility - it should be designed to work
- Beauty - it should be designed to be enjoyed

# EXECUTION

# RATIONALE

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
