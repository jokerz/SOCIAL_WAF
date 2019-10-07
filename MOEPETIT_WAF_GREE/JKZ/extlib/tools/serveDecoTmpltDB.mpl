#**************************
# @desc		デコメテンプレートスクリプト
# @package	serveFlashDB.mpl
# @access	public
# @author	Iwahase Ryo
# @create	2009/05/28
# @update
# @version	1.00
#**************************
use strict;
use CGI::Carp qw(fatalsToBrowser);
use lib qw(/home/vhosts/MYSDK/JKZ);
use WebUtil;
use JKZ::UsrWebDB;
use JKZ::JKZMobile;

use constant DECO_PUBLISHDIR	=> '/home/vhosts/MYSDK/JKZ/publish/decotmplt/';


my $agent = JKZ::JKZMobile->new();
my $carrier = $agent->getCarrierCode();

my $q = CGI->new();
## id of FlashData
my ($product_id, $id) = ( $q->param('p'), $q->param('i'));

my $published = DECO_PUBLISHDIR . sprintf("%s_%s",  $product_id, $id);
my $decoobj;
my $decodata;
my $mime_type;


## 実データ
my ($dmt, $hmt, $khm);
my ($mime_type_docomo, $mime_type_softbank, $mime_type_au);
my ($file_size_docomo, $file_size_softbank, $file_size_au);



## オブジェクトがある場合OK 無い場合はDBからデータを取得
eval {
	$decoobj	= WebUtil::publishObj( { file=>$published } );
	$decodata	= $decoobj->[$carrier - 1]->{decodata};
	$mime_type	= $decoobj->[$carrier - 1]->{mime_type};
};

if ($@) {
	my $dbh = JKZ::UsrWebDB::connect();
	$dbh->do ('set names utf8');
	$dbh->do ('use MYSDK');

	($dmt, $hmt, $khm, $mime_type_docomo, $mime_type_softbank, $mime_type_au, $file_size_docomo, $file_size_softbank, $file_size_au) = $dbh->selectrow_array (
 "SELECT
 dmt, hmt, khm,
 mime_type_docomo, mime_type_softbank, mime_type_au,
 file_size_docomo, file_size_softbank, file_size_au
 FROM MYSDK.tProductDecoTmplt
 WHERE productm_id=?", undef, $product_id);

	$dbh->disconnect ();


	my $tmpobj = [
				{
					decodata	=> $dmt,
					mime_type	=> $mime_type_docomo,
					file_size	=> $file_size_docomo,
				},
				{
					decodata	=> $hmt,
					mime_type	=> $mime_type_softbank,
					file_size	=> $file_size_softbank,
				},
				{
					decodata	=> $khm,
					mime_type	=> $mime_type_au,
					file_size	=> $file_size_au,
				},
				];

=pod
	WebUtil::publishObj( { file => $published,
							 obj  => [
								{
									decodata	=> $dmt,
									mime_type	=> $mime_type_docomo,
									file_size	=> $file_size_docomo,
								},
								{
									decodata	=> $hmt,
									mime_type	=> $mime_type_softbank,
									file_size	=> $file_size_softbank,
								},
								{
									decodata	=> $khm,
									mime_type	=> $mime_type_au,
									file_size	=> $file_size_au,
								},
							 ]
						  } );

$decodata = $khm;
$mime_type = 'application/x-kddi-htmlmail';
=cut


	WebUtil::publishObj( { file => $published,
							 obj  => $tmpobj
						});

$decodata = $tmpobj->[$carrier - 1]->{decodata};
$mime_type = $tmpobj->[$carrier - 1]->{mime_type};

}



print $q->header(
			-type=>$mime_type,
			-Content_Length=>length($decodata),
		);

print $decodata;

ModPerl::Util::exit ();



sub Error {
my $msg = shift;
my $q = new CGI;
	print $q->header (),
			$q->start_html ("Error"),
			$q->p ($q->escapeHTML ($msg)),
			$q->end_html ();
	ModPerl::Util::exit ();
}
