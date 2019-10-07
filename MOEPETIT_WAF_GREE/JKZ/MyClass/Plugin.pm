package MyClass::Plugin;


use strict;
use warnings;
use base 'Class::Component::Plugin';
=pod
__PACKAGE__->mk_accessors(qw/ base_config /);

sub init {
	my ($self, $c) = @_;
#	use Data::Dumper;
#	warn Dumper($self);
#	warn Dumper($c);
#	warn Dumper($self->config);
	
	$self->base_config($self->config);
	$self->config($self->config->{config});
}
=cut

1;
__END__