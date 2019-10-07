########################
#
# 画像表示スクリプト
# serveImage.mpl
# @update 2008/09/26
# @update 2008/09/30 動作修正
########################
use strict;
use CGI::Carp qw(fatalsToBrowser);
use lib qw(/home/vhosts/MYSDK/JKZ);
use WebUtil;
use JKZ::UsrWebDB;
#use MIME::Base64 qw(encode_base64 decode_base64);

my $q = new CGI;

## p=product_id i =id s = image size

#if (defined ($q->param('p')) && defined ($q->param('i')) && defined ($q->param('s'))) {
	my ($product_id, $id, $size) = ( $q->param('p'), $q->param('i'), $q->param('s') );

	my @thumb = (undef,'image', 'thumbnail_200', 'thumbnail_64', 'thumbnail_40');
	my $col_name = (defined ($size) ? $thumb[$size] : "thumbnail_64");

	my $memcached = JKZ::UsrWebDB::MemcacheInit ({
					'servers' => ["192.168.10.30:11211"],
					#'servers' => ["127.0.0.1:11211"],
					compress_threshold => 10_000,
					compress_ratio => 0.9,
				});

	my $key = join (';', (int ($product_id), $id,$size));
	my $obj = $memcached->get ("MYSDKImageData:$key");
	if(!$obj) {
		my $dbh = JKZ::UsrWebDB::connect();
		$dbh->do ('set names utf8');
		$dbh->do ('use MYSDK');
		my ($mime_type, $image_data) = $dbh->selectrow_array (
						"SELECT mime_type, $col_name FROM MYSDK.tProductImage WHERE productm_id=? AND id=?",
						undef,
						$product_id, $id
						);
		$dbh->disconnect ();

		$obj = {
			mime_type => $mime_type,
			image_data=> $image_data,
		};
		$memcached->add ("MYSDKImageData:$key", $obj, 600);
	}
	print $q->header(-type=>$obj->{mime_type},-Content_Length=>length ($obj->{image_data}));
	print $obj->{image_data};
#}

ModPerl::Util::exit ();


## サブルーティンはやめ
#sub printImage {
=pod
## MemCacheを使用する手法
	my ($owid, $id, $size, $dbh) = @_;
	my @thumb = (undef,'image', 'thumbnail_320', 'thumbnail_200', 'thumbnail_64');
	my $col_name = (defined ($size) ? $thumb[$size] : "thumbnail_64");

	my $memcached = JKZ::UsrWebDB::MemcacheInit ({
						'servers' => ["192.168.10.30:11211"],
						#'servers' => ["127.0.0.1:11211"],
						compress_threshold => 10_000,
						compress_ratio => 0.9,
					});

	my $key = join (';', (int ($owid), $id,$size));
	my $obj = $memcached->get ("ImageData:$key");
	if(!$obj) {
		my ($mime_type, $image_data) = $dbh->selectrow_array (
							"SELECT mime_type, $col_name FROM HP_general.tUserImageF WHERE owid=? AND id=?",
							undef,
							$owid, $id
							);
		$obj = {
			mime_type => $mime_type,
			image_data=> $image_data,
		};
		$memcached->add ("ImageData:$key", $obj, 120);
	}

	my $q = new CGI;
	print $q->header(-type=>$obj->{mime_type},-Content_Length=>length ($obj->{image_data}));
	print $obj->{image_data};

=cut

=pod
## MemCacheを使用しない手法
	my ($owid, $id, $size, $dbh) = @_;

	my @thumb = (undef,'image', 'thumbnail_320', 'thumbnail_200', 'thumbnail_64');
	my $col_name = (defined ($size) ? $thumb[$size] : "thumbnail_64");

	my ($mime_type, $image_data) = $dbh->selectrow_array (
						"SELECT mime_type, $col_name FROM HP_general.tUserImageF WHERE owid=? AND id=?",
						undef,
						$owid, $id
						);

	my $q = new CGI;
	print $q->header(-type=>$mime_type,-Content_Length=>length ($image_data));
	
	print $image_data;
=cut
#}


sub Error {
my $msg = shift;
my $q = new CGI;
	print $q->header (),
			$q->start_html ("Error"),
			$q->p ($q->escapeHTML ($msg)),
			$q->end_html ();
	ModPerl::Util::exit ();
}
