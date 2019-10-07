#******************************************************
# Controller
# @desc      GREE ライフサイクルイベント:アプリ追加
# @package   addapp.mpl
# @access    public
# @author    Iwahase Ryo
# @create    2011/03/01
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
        use MyClass::Gree::AddApp;
        my $myapp = MyClass::Gree::AddApp->new($cfg);
        $myapp->run();
    };

    if($@) {
        print "Content-Type: text/html\r\n\r\n", "Error: $@";
    }

    exists $ENV{MOD_PERL} ? ModPerl::Util::exit() : exit();
}
