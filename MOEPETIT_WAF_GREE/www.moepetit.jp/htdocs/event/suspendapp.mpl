#******************************************************
# Controller
# @desc      GREE ライフサイクルイベント:アプリ停止
# @package   suspendapp.mpl
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
        use MyClass::Gree::SuspendApp;
        my $myapp = MyClass::Gree::SuspendApp->new($cfg);
        $myapp->run();
    };

    if($@) {
        print "Content-Type: text/html\r\n\r\n", "Error: $@";
    }

    exists $ENV{MOD_PERL} ? ModPerl::Util::exit() : exit();
}