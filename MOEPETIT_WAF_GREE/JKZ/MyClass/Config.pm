package MyClass::Config;
# $Id: Config.pm 355 2006-03-06 06:29:24Z user $

use base qw(Config::Simple);
use strict;

sub new {
    my ($class, $file) = @_;
    return $class->SUPER::new($file);
}
sub readConf {
    my $self = shift;

    return $self->vars;
}


sub param {
    my $this = shift;
    my @args = @_;
    
    return $this->SUPER::param(@args) || '';
}

1;