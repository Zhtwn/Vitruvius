use strict;
use warnings;

use File::Spec;
use FindBin;
use Test::More;

unless ( $ENV{AUTHOR_TESTING} ) {
    plan skip_all => 'Author test. Set $ENV{AUTHOR_TESTING} to enable.';
    done_testing();
    exit 0;
}

eval { require Test::Perl::Critic; };

plan( skip_all => "Test::Perl::Critic not available: $@" )
  if $@;

my $rcfile = File::Spec->catfile( $FindBin::Bin, 'perlcriticrc' );

Test::Perl::Critic->import( -verbose => 9, -profile => $rcfile );
all_critic_ok();
