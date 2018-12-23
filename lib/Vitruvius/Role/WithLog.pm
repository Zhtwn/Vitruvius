package Vitruvius::Role::WithLog;

use Vitruvius::Skel::Moo::Role;

use Vitruvius::Types qw< Str InstanceOf >;

use Log::Any ();

has _log_category => (
    is      => 'ro',
    lazy    => 1,
    isa     => Str,
    builder => '_build__log_category',
);

sub _build__log_category {
    my $self = shift;

    my $class = ref $self;
    $class =~ s/^Vitruvius:://;

    return 'Core' if $class =~ /^Core::/;

    return $class;
}

# Note: can't store the $log returned by Log::Any, because globs aren't serializable
sub log {
    my $self = shift;
    return Log::Any->get_logger( category => $self->_log_category );
}

1;
