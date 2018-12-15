requires 'perl', 'v5.16.0';
requires 'Diff::LibXDiff';
requires 'Digest::CRC';
requires 'Hash::Merge';
requires 'List::MoreUtils';
requires 'List::Util';
requires 'Moo';
requires 'MooX::TypeTiny';
requires 'MooseX::App';
requires 'PPI';
requires 'Parallel::ForkManager';
requires 'Path::Tiny';
requires 'Perl::Tidy';
requires 'Scalar::Util';
requires 'Text::Levenshtein::XS';
requires 'Types::Common::Numeric';
requires 'Types::Path::Tiny';
requires 'Types::Standard';
requires 'feature';
requires 'parent';

on test => sub {
    requires 'Test::Compile';
    requires 'Test::More', '0.96';
};

on configure => sub {
    requires 'Module::Build::Tiny', '0.034';
};
