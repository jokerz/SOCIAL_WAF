#******************************************************
# my_itembox_app.mpl
# @desc		アイテムボックス
# @access	public
# @author	Iwahase Ryo
# @create	2011/03/29
#******************************************************
use strict;
use vars qw($cfg);

BEGIN {

    my $config = $ENV{'MOEPETIT_CONFIG'};
    require MyClass::Config;
	$cfg = MyClass::Config->new($config);

}
{
    eval {
        use MyClass::Gree::MyItemBox;
        my $myapp = MyClass::Gree::MyItemBox->new($cfg);
        $myapp->run();
    };

    if($@) {
        print "Content-Type: text/html\r\n\r\n", "Error: $@";
    }

    exists $ENV{MOD_PERL} ? ModPerl::Util::exit() : exit();
}
