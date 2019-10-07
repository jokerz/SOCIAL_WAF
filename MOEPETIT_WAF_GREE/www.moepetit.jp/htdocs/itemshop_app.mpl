#******************************************************
# itemshop_app.mpl
# @desc		アイテムショップ
# @access	public
# @author	Iwahase Ryo
# @create	2011/03/29
# @update   2011/04/19 ItemShopクラスだと認証をこけるので、TestItemShopを使用
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
        #use MyClass::Gree::ItemShop;
        #my $myapp = MyClass::Gree::ItemShop->new($cfg);
        #$myapp->run();
        use MyClass::Gree::TestItemShop;
        my $myapp = MyClass::Gree::TestItemShop->new($cfg);
        $myapp->run();

    };

    if($@) {
        print "Content-Type: text/html\r\n\r\n", "Error: $@";
    }

    exists $ENV{MOD_PERL} ? ModPerl::Util::exit() : exit();
}
