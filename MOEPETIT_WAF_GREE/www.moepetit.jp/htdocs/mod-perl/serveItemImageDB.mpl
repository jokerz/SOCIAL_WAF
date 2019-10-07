#**************************
#
# アイテム画像表示スクリプト
# serveItemImageDB.mpl
# @access    public
# @author    Iwahase Ryo
# @create    2011/04/04
#**************************
use strict;
use vars qw($cfg);

BEGIN {
    my $config = $ENV{'MOEPETIT_CONFIG'};
    require MyClass::Config;
    $cfg = MyClass::Config->new($config);
}

use CGI;
use MyClass::UsrWebDB;

my $namespace        = $cfg->param('WAF_NAME_SPACE') . 'ItemImageData';
my $q                = CGI->new();
my $item_id          = $q->param('ii');
my $memcached        = MyClass::UsrWebDB::MemcacheInit();
my $obj              = $memcached->get("$namespace:$item_id");

if(!$obj) {
	my $dbh = MyClass::UsrWebDB::connect({
                 dbaccount => $cfg->param('DATABASE_USER'),
                 dbpasswd  => $cfg->param('DATABASE_PASSWORD'),
                 dbname    => $cfg->param('DATABASE_NAME'),
              });

    $dbh->do('set names utf8');

    my $sql                      = sprintf("SELECT mime_type, image FROM %s.tItemImageM WHERE itemm_id=?;", $cfg->param('DATABASE_NAME'));
    my ($mime_type, $image_data) = $dbh->selectrow_array ($sql, undef, $item_id);
    $dbh->disconnect();

    $obj = {
    mime_type => $mime_type,
    image_data=> $image_data,
    };
	$memcached->add("$namespace:$item_id", $obj, 3600);
}

print $q->header(-type=>$obj->{mime_type},-Content_Length=>length ($obj->{image_data}));
print $obj->{image_data};

ModPerl::Util::exit();

__END__