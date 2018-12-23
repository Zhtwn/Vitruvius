package TestsFor::Vitruvius::Core::Code;

use FindBin::libs;
use Vitruvius::Test;

use Perl::Tidy;
use PPI;

use Vitruvius::Util qw< ppi_type >;

# ugly heuristic to build expected raw code (without comments and tidied)
sub _expected_raw_code {
    my ( $type, $code ) = @_;

    my @raw_lines;

    my $leading_space_count;

    for my $line (split /\n/, $code) {
        # remove comment-only lines
        next if $line =~ /^\s+#.*$/;

        # remove trailing comments (sorta)
        $line =~ s/\s+#.*$//;

        push @raw_lines, $line;
    }

    my $raw_code = join "\n", @raw_lines, '';   # add trailing newline

    # force perltidy to remove leading spaces, since PPI also does that
    $raw_code =~ s/^ *// unless $type eq 'PPI::Document';

    my ( $tidy_code, $stderr );

    my $argv = '-npro'; # ignore local perltidyrc
    my $error = Perl::Tidy::perltidy( argv => $argv, stderr => \$stderr, source => \$raw_code, destination => \$tidy_code );

    return $error ? $raw_code : $tidy_code;
}

sub test_basics : Test {
    my $test = shift;

    my $perl_code = <<'EOF';
    # comment
    sub foo {
        my @bar = ( 9);
        # another comment
        for my $baz (@bar ) {
            print "$baz\n";     # yet another comment
        }
    }
EOF

    ( my $block_code = $perl_code ) =~ s/sub foo //;

    my $ppi_document = PPI::Document->new( \$perl_code );

    my ($ppi_sub) = grep { ref $_ eq 'PPI::Statement::Sub' } $ppi_document->children;

    my ($ppi_block) = grep { ref $_ eq 'PPI::Structure::Block' } $ppi_sub->children;

    my @cases = (
        {
            name              => 'full PPI::Document',
            ppi               => $ppi_document,
            expected_code     => $perl_code,
            # Perl code with comments removed, and tidied
            expected_raw_code => _expected_raw_code('PPI::Document', $perl_code),
        },
        {
            name              => 'PPI::Statement::Sub',
            ppi               => $ppi_sub,
            expected_code     => $ppi_sub->content,
            # Perl code with comments removed, and tidied
            expected_raw_code => _expected_raw_code('PPI::Statement::Sub', $perl_code),
        },
        {
            name              => 'PPI::Structure::Block',
            ppi               => $ppi_block,
            expected_code     => $ppi_block->content,
            # Perl code with comments removed, and tidied
            expected_raw_code => _expected_raw_code('PPI::Structure::Block', $block_code),
        },
    );

    for my $case (@cases) {
        subtest $case->{name} => sub {
            my $code;
            ok( lives { $code = $CLASS->new( ppi => $case->{ppi} ) }, '->new should succeed' );

            isa_ok( $code, [$CLASS], '->new should return correct class' );

            # Note: anything other than PPI::Document removes trailing newline
            my $expected_code = $case->{expected_code};
            $expected_code =~ s/\n$// unless ref $case->{ppi} eq 'PPI::Document';

            is( $code->content, $expected_code, '->content should match original code' );

            is( $code->raw_content, $case->{expected_raw_code}, '->raw_content should remove comments from original code and tidy it' );

            is( $code->type, ref $case->{ppi}, '->type should be correct' );

            ok( $code->crc_hash, '->crc_hash should be defined' );

            is( $code->ppi_element_hash, ppi_type( $code->type ), '->ppi_element_hash should be correct' );
        };
    }
}

1;
