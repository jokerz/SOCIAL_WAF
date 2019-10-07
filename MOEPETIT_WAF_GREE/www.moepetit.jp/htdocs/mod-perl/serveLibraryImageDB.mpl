#**************************
#
# 画像表示スクリプト(画像を縮小表示する)
# 図鑑作成時の画像選択時用に画像をリアルタイムで縮小
# serveLibraryImageDB.mpl
# @access    public
# @author    Iwahase Ryo
# @create    2011/05/12
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

my $namespace   = $cfg->param('WAF_NAME_SPACE') . 'LibraryImageData';
my $q           = CGI->new();

## このパラメータが指定された場合、値は何でもよいけど120x160のサイズの画像を生成
my $s           = $q->param('s') || undef;
my ($my_library_id, $my_getimage_id) = split(/:/, $q->param('mlii'));

my $col_name    = (defined($s)) ? 'image' : 'resized_image';


my $key         = join (';', (int($my_library_id), int($my_getimage_id), $col_name));
my $memcached   = MyClass::UsrWebDB::MemcacheInit();
my $obj         = $memcached->get("$namespace:$key");

if(!$obj) {
	my $dbh = MyClass::UsrWebDB::connect({
                 dbaccount => $cfg->param('DATABASE_USER'),
                 dbpasswd  => $cfg->param('DATABASE_PASSWORD'),
                 dbname    => $cfg->param('DATABASE_NAME'),
              });

    $dbh->do ('set names utf8');

    my $sql                      = sprintf("SELECT mime_type, %s FROM %s.tMyLibraryImageM WHERE my_library_id=? AND my_getimage_id = ?;", $col_name, $cfg->param('DATABASE_NAME'));
    my ($mime_type, $image_data) = $dbh->selectrow_array ($sql, undef, $my_library_id, $my_getimage_id);
    $dbh->disconnect();


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