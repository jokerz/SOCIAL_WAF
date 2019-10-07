#******************************************************
# @desc		データダウンロード
# @package	download.mpl
# @access	public
# @author	Iwahase Ryo
# @create	2008/11/28
# @version	1.00
#******************************************************

use strict;
use lib qw(/home/vhosts/MYSDK/JKZ/extlib/common);
use JKZ::UsrWebDB;
use POSIX;
use Archive::Zip qw ( :ERROR_CODES :CONSTANTS );
use Data::Dumper;

my $q = CGI->new ();

my $data;
my $length;
my $string=" " x 10000;
my $p_err=0;

#****************************
# ファイル名を取得
#****************************
my($fileTemp) = POSIX::tmpnam();
open( FILE, ">" . $fileTemp);	


#タイトル行の設定　仮
# owid, mobilemailaddress, carrier, sex, month_of_birth, date_of_birth, prefecture
$string = '会員No.' . ",";
$string .= 'メールアドレス' . ",";
$string .= 'キャリア' . ",";
$string .= '性別' . ",";
$string .= '誕生月' . ",";
$string .= '誕生日' . ",";
$string .= '住まい地区' . "\n";

$p_err = print FILE $string;

if($p_err == 0 ) {
	&ShowMsg('会員情報ダウンロード','ダウンロードエラーです',0,"");
	close( FILE );
	unlink($fileTemp);
	exists( $ENV{MODPERL} ) ? ModPerl::Util::exit() : exit();
}

my $cookie = $q->cookie('MYSDKCMSCookie');

my ($condition, $holder) = split (/,/, $cookie);
my @placeholder = split(/ /, $holder);

my $sql = "SELECT mid, mobilemailaddress, carrier, sex, month_of_birth, date_of_birth, prefecture"
 		. " FROM MYSDK.tMemberM WHERE "
 		. $condition;

my $dbh = JKZ::UsrWebDB::connect();
my $aryref = $dbh->selectall_arrayref($sql, { Columns => {} }, @placeholder);

if ($#{$aryref} > 0) {
	foreach (@{$aryref}) {
		$string = $_->{mid} . ",";
		$string .= "\"" . $_->{mobilemailaddress} . "\",";
		$string .= $_->{carrier} . ",";
		$string .= $_->{sex} . ",";
		$string .= $_->{month_of_birth} . ",";
		$string .= $_->{date_of_birth} . ",";
		$string .= $_->{prefecture};
		$string .= "\n";

		$p_err = print FILE $string;
	}
}
else {
	close( FILE );
	unlink($fileTemp);
}

$dbh->disconnect();

close( FILE );

#****************************
# CSVファイル
#****************************
my $dlfile='/tmp/memberinfo.csv';

#****************************
# 新規のzipアーカイブの作成
#****************************
my $zip = Archive::Zip->new();

#****************************
# zip ファイルをメンバに追加
#****************************
my $member = $zip->addFile( $fileTemp, $dlfile );

#****************************
# 圧縮レベルの設定
#****************************
$member->desiredCompressionLevel( COMPRESSION_LEVEL_BEST_COMPRESSION  );

#****************************
# zip書き込み
#    (0) 問題はなにもない．
#    (1) 読み込みストリーム (またはセントラルディレクトリ) が正常に終了した．
#    (2) 何らかの一般的な種類のエラーが起こった．
#    (3) 読み込んでいるZipファイル内でフォーマットのエラーが起こった．
#    (4) IO エラーが起こった．
#****************************
if( $zip->writeToFileNamed( $dlfile ) != 0 ) {
	&ShowMsg('ダウンロード', 'ファイルの作成に失敗しました', 0, '');
	exists( $ENV{MODPERL} ) ? ModPerl::Util::exit() : exit();
}

#****************************
# ダウンロードファイルの読み込み
#****************************
open( FILE, $dlfile );
binmode FILE;

read( FILE, $data, -s FILE );

#****************************
# ユーザにプッシュ
#****************************
$length = -s FILE;
print 'Content-Length: '.$length."\n";
print 'Content-disposition: attachment; filename="memberinfocsv.zip"'."\n";	#ユーザに見せるファイル名　関連なし
print 'Content-Type: application/zip'."\n\n";

### print 'Content-disposition: attachment; filename="meminfo.csv"'."\n";	#ユーザに見せるファイル名　関連なし
### print 'Content-Type: application/octet-stream'."\n\n";

$p_err = print $data;

if($p_err == 0 ) {
	&ShowMsg('会員情報ダウンロード', 'ダウンロードエラーです', 0, "");
}

close( FILE );

##ファイルを削除
unlink($fileTemp);
unlink($dlfile);

exists( $ENV{MODPERL} ) ? ModPerl::Util::exit() : exit();
