package MyClass::Attribute::Handler;
use strict; 
use warnings; 
use base 'Class::Component::Attribute';
 
sub register { 
    my($class, $plugin, $c, $method, $value, $code) = @_;
    $plugin->handler_method($method); 
} 

1;
