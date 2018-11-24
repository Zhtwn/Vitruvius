package Code::Refactor::Tlsh;

use strict;
use warnings;

use FFI::CheckLib;
use FFI::Platypus;
use FFI::Platypus::Memory qw{ malloc free };

# TODO - factor this out into a Digest::Tlsh that's CPAN-able

my $ffi = FFI::Platypus->new;
$ffi->lang('CPP');
$ffi->lib(find_lib_or_die lib => 'tlsh');

$ffi->custom_type(
    Tlsh => {
        native_type    => 'opaque',
        perl_to_native => sub { ${ $_[0] } },
        native_to_perl => sub { bless \$_[0], 'Code::Refactor::Tlsh' },
    }
);

$ffi->attach( [ 'Tlsh::Tlsh()'    => '_new' ]     => ['Tlsh'] => 'void' );
$ffi->attach( [ 'Tlsh::~Tlsh()'   => '_DESTROY' ] => ['Tlsh'] => 'void' );
$ffi->attach( [ 'Tlsh::version()' => 'version' ]  => ['Tlsh'] => 'string' );
$ffi->attach( [ 'Tlsh::update(unsigned char const*, unsigned int)' => '_update' ] => [ 'Tlsh', 'string', 'unsigned int' ] => 'void' );
$ffi->attach( [ 'Tlsh::final(unsigned char const*, unsigned int, int)' => '_final' ] => [ 'Tlsh', 'string', 'unsigned int', 'int' ] => 'void' );
$ffi->attach( [ 'Tlsh::getHash() const' => '_getHash' ] => [ 'Tlsh' ] => 'string' );
$ffi->attach( [ 'Tlsh::totalDiff(Tlsh const*, bool) const' => '_totalDiff' ] => [ 'Tlsh', 'Tlsh' ] => 'int' );

my $tlsh_size = $ffi->sizeof('Tlsh');

sub new {
    my $class = shift;
    my $ptr = malloc $tlsh_size;
    my $self = bless \$ptr, $class;
    _new($self);
    return $self;
}

sub update {
    my ( $self, $string ) = @_;
    my $length = length $string;
    _update($self, \$string, $length);
}

sub final {
    my ( $self, $string, $force_option ) = @_;
    $force_option //= 0;
    my $length = length $string;
    _final($self, \$string, $length, $force_option);
}

sub get_hash {
    my $self = shift;
    my $hash = _getHash($self);
    return $hash;
}

sub total_diff {
    my ( $self, $other ) = @_;
    my $total_diff = _totalDiff($self, $other);
    return $total_diff;
}

sub DESTROY {
    my $self = shift;
    _DESTROY($self);
}


