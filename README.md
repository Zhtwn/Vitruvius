# NAME

Code::Refactor - tools to aid in code refactoring

# SYNOPSIS

    use Code::Refactor;

# DESCRIPTION

Code::Refactor is fun and incomplete

# PARAMETERS

## jobs

Number of jobs to use to parse files

Default: 1

## base\_dir

Base directory for all files

Default: `cwd`

## filenames

File names to be scanned

## min\_similarity

Minimum "similarity" - defaults to 95

## min\_ppi\_hash\_length

Minimum PPI hash length - defaults to 100

# ATTRIBUTES

## files

Code::Refactor::File instances for all files

## nodes

All nodes from all files, hashed by type

## diffs

Diff instance for all pairs of nodes, hashed by type

## groups

Groups, ordered by something reasonable

# PRIVATE METHODS

## \_node\_pairs

Build pairs of nodes

## \_parallelize

Run in parallel jobs

# AUTHOR

Noel Maddy <zhtwnpanta@gmail.com>

# COPYRIGHT

Copyright 2018- Noel Maddy

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO
