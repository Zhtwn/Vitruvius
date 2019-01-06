# NAME

Vitruvius - tools for code architect

# SYNOPSIS

    # TBW

# DESCRIPTION

Vitruvius is a set of tools to help the code architect.

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
