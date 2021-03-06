requires 'perl', '5.010';
requires 'Bread::Board';
requires 'Carp';
requires 'Diff::LibXDiff';
requires 'Digest::CRC';
requires 'FindBin::libs';
requires 'Hash::Merge';
requires 'Import::Into';
requires 'List::MoreUtils';
requires 'List::Util';
requires 'Log::Any';
requires 'Log::Any::Adapter::Screen';
requires 'Moo';
requires 'MooX::StrictConstructor';
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
    requires 'perl', '5.012';
    requires 'Test::Compile';
    requires 'Test::More', '0.96';
    requires 'Test2::Tools::xUnit', '0.003';
};

on configure => sub {
    requires 'Module::Build::Tiny', '0.034';
};

on develop => sub {
    requires 'Test::Perl::Critic';
};
