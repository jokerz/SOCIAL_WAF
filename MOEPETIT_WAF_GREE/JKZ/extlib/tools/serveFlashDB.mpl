#**************************
# @desc		Flash表示スクリプト
# @package	serveFlashDB.mpl
# @access	public
# @author	Iwahase Ryo
# @create	2009/05/26
# @update
# @version	1.00
#**************************
use strict;
use CGI::Carp qw(fatalsToBrowser);
use lib qw(/home/vhosts/MYSDK/JKZ);
use WebUtil;
use JKZ::UsrWebDB;

use constant SWF_PUBLISHDIR	=> '/home/vhosts/MYSDK/JKZ/publish/swf/';


my $q = CGI->new();
## id of FlashData
my ($product_id, $id) = ( $q->param('p'), $q->param('i'));

my $published = SWF_PUBLISHDIR . sprintf("%s_%s",  $product_id, $id);
my $swfobj;
my $swfdata;
my $mime_type;

## オブジェクトがある場合OK 無い場合はDBからデータを取得
eval {
	$swfobj		= WebUtil::publishObj( { file=>$published } );
	$swfdata	= $swfobj->{swfdata};
	$mime_type	= $swfobj->{mime_type};
};

if ($@) {
	my $dbh = JKZ::UsrWebDB::connect();
	$dbh->do ('set names utf8');
	$dbh->do ('use MYSDK');

	($swfdata, $mime_type) = $dbh->selectrow_array ("SELECT swf, mime_type FROM MYSDK.tProductSwf WHERE productm_id=? AND id=?", undef, $product_id, $id);
	$dbh->disconnect ();

	
	WebUtil::publishObj( { file => $published,
							 obj  => { swfdata => $swfdata, mime_type => $mime_type }
						  } );
}


print $q->header(
			-type=>$mime_type,
			-Content_Length=>length($swfdata),
		);

print $swfdata;

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
