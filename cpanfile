requires 'perl', '5.010';
requires 'Bread::Board';
requires 'Carp';
requires 'Diff::LibXDiff';
requires 'Digest::CRC';
requires 'Hash::Merge';
requires 'Import::Into';
requires 'List::MoreUtils';
requires 'List::Util';
requires 'Moo';
requires 'MooX::TypeTiny';
requires 'MooseX::App';
requires 'MooseX::App::Plugin::ConfigHome';
requires 'PPI';
requires 'Parallel::ForkManager';
requires 'Path::Tiny';
requires 'Perl::Tidy';
requires 'Scalar::Util';
requires 'String::CamelCase';
requires 'Text::Levenshtein::XS';
requires 'Types::Common::Numeric';
requires 'Types::Path::Tiny';
requires 'Types::Standard';
requires 'namespace::autoclean';
requires 'feature';
requires 'parent';

on test => sub {
    requires 'Test::Compile';
    requires 'Test::More', '0.96';
};

on configure => sub {
    requires 'Module::Build::Tiny', '0.034';
};

on develop => sub {
    requires 'Test::Perl::Critic';
};
