#*********************************************
# サイト画像表示スクリプト
# @update    2010/05/07   ModPerl・Apache側で設定した環境変数から
#                        設定情報を取得して、DBアクセスするように変更
#                         memcachedのnamespaceとしてDATABASE NAME+TABLE NAMEを使用すること
#*********************************************
use strict;
use vars qw($cfg);

BEGIN {
    my $config = $ENV{'MOEPETIT_CONFIG'};
    require MyClass::Config;
    $cfg = MyClass::Config->new($config);
}

use CGI;
use CGI::Carp qw(fatalsToBrowser);
use MyClass::WebUtil;
use MyClass::UsrWebDB;

my $namespace = $cfg->param('WAF_NAME_SPACE') . 'SiteImageData';
my $q         = CGI->new();
my $id        = $q->param('i');
my $key       = $id;
my $memcached = MyClass::UsrWebDB::MemcacheInit();
my $obj       = $memcached->get("$namespace:$key");

if(!$obj) {
    my $dbh = MyClass::UsrWebDB::connect({
                 dbaccount => $cfg->param('DATABASE_USER'),
                 dbpasswd  => $cfg->param('DATABASE_PASSWORD'),
                 dbname    => $cfg->param('DATABASE_NAME'),
              });

    $dbh->do('set names utf8');

    my $sql                      = sprintf("SELECT mime_type, image FROM %s.tSiteImageM WHERE id=?;", $cfg->param('DATABASE_NAME'));
    my ($mime_type, $image_data) = $dbh->selectrow_array($sql, undef, $id);
    $dbh->disconnect ();

    $obj = {
        mime_type => $mime_type,
        image_data=> $image_data,
    };
    $memcached->add("$namespace:$key", $obj, 3600);
}

print $q->header(-type=>$obj->{mime_type},-Content_Length=>length ($obj->{image_data}));
print $obj->{image_data};

ModPerl::Util::exit();

__END__