#******************************************************
# otherpage_app.mpl
# @desc		他のグリーユーザーのページ
# @access	public
# @author	Iwahase Ryo
# @create	2011/04/11
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
        use MyClass::Gree::OtherPage;
        my $myapp = MyClass::Gree::OtherPage->new($cfg);
        $myapp->run();
    };

    if($@) {
        print "Content-Type: text/html\r\n\r\n", "Error: $@";
    }

    exists $ENV{MOD_PERL} ? ModPerl::Util::exit() : exit();
}
