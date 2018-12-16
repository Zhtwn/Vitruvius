package Vitruvius::Util;

use strict;
use warnings;
use 5.010;

use parent 'Exporter';

our @EXPORT_OK = qw<
  ppi_type
  is_interesting
  parallelize
>;

use List::MoreUtils 'part';
use List::Util 'min';
use Parallel::ForkManager;
use Scalar::Util qw< blessed >;

# HACK - copy of the PDOM class tree from PPI documentation
my @pdom_classes = qw<
  PPI::Element
  PPI::Node
  PPI::Document
  PPI::Document::Fragment
  PPI::Statement
  PPI::Statement::Package
  PPI::Statement::Include
  PPI::Statement::Sub
  PPI::Statement::Scheduled
  PPI::Statement::Compound
  PPI::Statement::Break
  PPI::Statement::Given
  PPI::Statement::When
  PPI::Statement::Data
  PPI::Statement::End
  PPI::Statement::Expression
  PPI::Statement::Variable
  PPI::Statement::Null
  PPI::Statement::UnmatchedBrace
  PPI::Statement::Unknown
  PPI::Structure
  PPI::Structure::Block
  PPI::Structure::Subscript
  PPI::Structure::Constructor
  PPI::Structure::Condition
  PPI::Structure::List
  PPI::Structure::For
  PPI::Structure::Given
  PPI::Structure::When
  PPI::Structure::Unknown
  PPI::Token
  PPI::Token::Whitespace
  PPI::Token::Comment
  PPI::Token::Pod
  PPI::Token::Number
  PPI::Token::Number::Binary
  PPI::Token::Number::Octal
  PPI::Token::Number::Hex
  PPI::Token::Number::Float
  PPI::Token::Number::Exp
  PPI::Token::Number::Version
  PPI::Token::Word
  PPI::Token::DashedWord
  PPI::Token::Symbol
  PPI::Token::Magic
  PPI::Token::ArrayIndex
  PPI::Token::Operator
  PPI::Token::Quote
  PPI::Token::Quote::Single
  PPI::Token::Quote::Double
  PPI::Token::Quote::Literal
  PPI::Token::Quote::Interpolate
  PPI::Token::QuoteLike
  PPI::Token::QuoteLike::Backtick
  PPI::Token::QuoteLike::Command
  PPI::Token::QuoteLike::Regexp
  PPI::Token::QuoteLike::Words
  PPI::Token::QuoteLike::Readline
  PPI::Token::Regexp
  PPI::Token::Regexp::Match
  PPI::Token::Regexp::Substitute
  PPI::Token::Regexp::Transliterate
  PPI::Token::HereDoc
  PPI::Token::Cast
  PPI::Token::Structure
  PPI::Token::Label
  PPI::Token::Separator
  PPI::Token::Data
  PPI::Token::End
  PPI::Token::Prototype
  PPI::Token::Attribute
  PPI::Token::Unknown
>;

# encode all tokens to two-char hex strings
my $i               = 0;
my %token_for_class = map { $_ => sprintf '%02x', $i++ } @pdom_classes;
my %class_for_token = reverse %token_for_class;

=head1 EXPORTABLE FUNCTIONS

=head2 ppi_type

Return string indicating type of PPI element

=cut

sub ppi_type {
    my $ppi_class = shift;

    return $token_for_class{$ppi_class};
}

=head2 is_interesting

Is this PPI "interesting" for refactoring?

FIXME: bad name

=cut

sub is_interesting {
    my $class = shift;

    if ( $class eq 'PPI::Statement::Sub' ) {
        return 1;
    }

    return;

    #   elsif ( $class eq 'PPI::Structure::Block' ) {
    #       return 1 unless $ppi->parent;
    #       return 1 unless $ppi->parent->class eq 'PPI::Statement::Sub';
    #   }

    #   return;
}

=head2 parallelize

Run given work in parallel jobs

=cut

sub parallelize {
    my %args = @_;

    my $jobs       = $args{jobs};
    my $message    = $args{message};
    my $input      = $args{input};
    my $child_sub  = $args{child_sub};
    my $finish_sub = $args{finish_sub};

    # never use more jobs than we have inputs
    $jobs = $jobs, scalar @$input;

    say "$message using $jobs jobs...";
    my $i = 0;
    my @input_batches = part { $i++ % $jobs } @$input;

    my $pm = Parallel::ForkManager->new($jobs);

    $pm->run_on_finish(
        sub {
            my ( $pid, $exit_code, $ident, $exit_signal, $core_dump, $return ) = @_;
            if ($return) {
                $finish_sub->($return);
            }
        }
    );

  JOB:
    for my $job_num ( 0 .. $jobs - 1 ) {
        $pm->start and next JOB;

        my $output = $child_sub->( $input_batches[$job_num] );

        $pm->finish( 0, $output );
    }

    $pm->wait_all_children;
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
