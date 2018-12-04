package Code::Refactor::Util;

use strict;
use warnings;

use parent 'Exporter';

our @EXPORT_OK = qw<
  ppi_type
  hash_ppi
  is_interesting
>;

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

# NOTE: uses Perl's character increment, using 'a' - 'z', then 'aa' - 'az', etc
my $token = 'a';
my %token_for_class = map { $_ => $token++ } @pdom_classes;
my %class_for_token = reverse %token_for_class;

=head1 EXPORTABLE FUNCTIONS

=head2 ppi_type

Return string indicating type of PPI element

=cut

sub ppi_type {
    my $ppi = shift;

    die "not a PPI::Element" unless blessed $ppi && $ppi->isa('PPI::Element');

    return $token_for_class{$ppi->class};
}

=head2 hash_ppi

Return a hash representing the structure of the given PPI

=cut

sub hash_ppi {
    my $ppi = shift;

    die "not a PPI::Element" unless blessed $ppi && $ppi->isa('PPI::Element');

    my @children = $ppi->can('children') ? $ppi->children : ();

    if (!@children) {
        return $token_for_class{ref $ppi} // 'XXX';
    }
    else {
        return '[' . join(',', map { hash_ppi($_) } @children ) . ']';
    }
}

=head2 is_interesting

Is this PPI "interesting" for refactoring?

FIXME: bad name

=cut

sub is_interesting {
    my $ppi = shift;

    my $class = $ppi->class;

    if ( $class eq 'PPI::Statement::Sub' ) {
        return 1;
    }
    elsif ( $class eq 'PPI::Structure::Block' ) {
        if ($ppi->parent->class ne 'PPI::Statment::Sub' ) {
            return 1;
        }
    }

    return;
}

1;
