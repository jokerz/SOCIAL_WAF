#*********************************************
# @desc      Flash表示スクリプト
#            初回はDBからデータを取得して、シリアライズオブジェクトを生成
#            オブジェクトがある場合はオブジェクトからデータを取得
# @packag    serveFlashDB.mpl
# @access    public
# @author    Iwahase Ryo
# @create    2009/05/26
# @update    2009/06/07 ダウンロードカウント処理を追加
# @update    2010/05/07 1.ModPerl・Apache側で設定した環境変数から
#                        設定情報を取得して、DBアクセスするように変更
#                       2.memcachedのnamespaceとしてDATABASE NAME+TABLE NAMEを使用すること
#                       3.Flashコンテンツとデコメテンプレートのデータシリアライズディレクトリの設定値
# @version   1.00
# @version   1.20
#*********************************************
use strict;
use vars qw($cfg);

BEGIN {
    my $config = $ENV{'MOEPETIT_CONFIG'};
    require MyClass::Config;
    $cfg = MyClass::Config->new($config);
}

use CGI::Carp qw(fatalsToBrowser);
use MyClass::WebUtil;
use constant SWF_PUBLISHDIR => $cfg->param('SERIALIZEDOJB_DIR') . '/contents/swf/';
use CGI;

my $q  = CGI->new();

my $mii = $q->param('mii');

my ($my_item_id, $item_id);

if ($mii eq "") {
    $item_id = '1001';
}
else {
    ($my_item_id, $item_id) = split(/:/, $mii);
}
=pod
if ($q->param('mii') eq "" || !defined($q->param('mii'))) {
    $item_id = '1001';
}
else {
    ($my_item_id, $item_id) = split(/:/, $q->param('mii'));
}
=cut
my ($contents_id, $category_id) = split(/:/, $q->param('p'));
my $stopwatch_id = $q->param('msi') || '6001';

my $s   = $q->param('s');
my $a   = $q->param('a');
my $o   = $q->param('o');
my $p   = $q->param('p');
my $nn  = $q->param('nn');

my $msi = $q->param('msi');
my $xy  = $q->param('xy');


## パラメータ値
my $param  = sprintf("?s=%s&p=%s&mii=%s&msi=%s&a=%s&o=%s&nn=%s&xy=%s", $s, $p, $mii,$msi, $a, $o, $nn, $xy);
#my $param  = sprintf("?s=%s&a=%s&o=%s&nn=%s&mii=%s&msi=%s", $s, $a, $o, $nn, $mii, $msi);
my $swf_id = sprintf("%s:%03d%02d:%s", $item_id, $contents_id, $category_id, $stopwatch_id);


#*************************************
# アイテム使用処理
#*************************************
# Modified この処理はここで実行するとMyPage->fcheck_flash_gameメソッドで必ず無効となるため、fcheck_flash_gameメソッド内に処理を移動
=pod
if ("" ne $my_item_id) {
    my ($gree_user_id, $encrypt) = split(/:/, $s);

    require MyClass::UsrWebDB;
    require MyClass::JKZDB::MyItem;;
    my $dbh = MyClass::UsrWebDB::connect({
                 dbaccount => $cfg->param('DATABASE_USER'),
                 dbpasswd  => $cfg->param('DATABASE_PASSWORD'),
                 dbname    => $cfg->param('DATABASE_NAME'),
              });

    my $myItem = MyClass::JKZDB::MyItem->new($dbh);
    # 失敗の場合はスルー
    #$myItem->updateMyItemStatus({ gree_user_id => $gree_user_id, my_item_id => $my_item_id, status_flag => 1 });
    $myItem->updateMyItemStatus({ my_item_id => $my_item_id, status_flag => 1 });
    my $namespace    = 'dMOEPETIT_gsa_user_gameitem';
    my $memcached = MyClass::UsrWebDB::MemcacheInit(
                {
                    servers            => ["192.168.1.201:11211"],
                    namespace          => 'gsa:',
                    compress_threshold => 10_000,
                    compress_ratio     => 0.9,
                }
    );

    $memcached->delete("$namespace:$gree_user_id");
}
=cut



my $published          = SWF_PUBLISHDIR . sprintf("%s", $swf_id);


#print $q->header('text/plain');
#print "="x100, "\n", $swf_id;
#print $q->Dump();

#ModPerl::Util::exit();

#__END__

=pod
eval {
    $swfobj     = MyClass::WebUtil::publishObj( { file=>$published } );
    $swfdata    = $swfobj->{swfdata};
    $mime_type  = $swfobj->{mime_type};
};

if ($@) {
    require MyClass::UsrWebDB;
    my $dbh = MyClass::UsrWebDB::connect({
                 dbaccount => $cfg->param('DATABASE_USER'),
                 dbpasswd  => $cfg->param('DATABASE_PASSWORD'),
                 dbname    => $cfg->param('DATABASE_NAME'),
              });

	$dbh->do('set names utf8');

    my $sql                = sprintf("SELECT swf, mime_type FROM %s.tTestContentsSwfM WHERE swf_id=?;", $cfg->param('DATABASE_NAME'));
    ($swfdata, $mime_type) = $dbh->selectrow_array ($sql, undef, $swf_id);
	$dbh->disconnect ();

    MyClass::WebUtil::publishObj({
        file => $published,
        obj  => {
            swfdata   => $swfdata,
            mime_type => $mime_type
        }
    });
}
=cut

my $swfobj;
my $swfdata;
my $mime_type;

    require MyClass::UsrWebDB;
    my $dbh = MyClass::UsrWebDB::connect({
                 dbaccount => $cfg->param('DATABASE_USER'),
                 dbpasswd  => $cfg->param('DATABASE_PASSWORD'),
                 dbname    => $cfg->param('DATABASE_NAME'),
              });

	$dbh->do('set names utf8');

    my $sql                = sprintf("SELECT swf, mime_type FROM %s.tTestContentsSwfM WHERE swf_id=?;", $cfg->param('DATABASE_NAME'));
    ($swfdata, $mime_type) = $dbh->selectrow_array ($sql, undef, $swf_id);
    $dbh->disconnect ();


print $q->header(
            -type=>$mime_type,
            -Content_Length=>length($swfdata),
      );
print $swfdata;

ModPerl::Util::exit();
