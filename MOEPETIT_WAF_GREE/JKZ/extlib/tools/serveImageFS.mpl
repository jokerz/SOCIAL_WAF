#********************************************
# @desc		���[�J���f�B���N�g���̉摜���o��
# @desc		���[�U�[�Ǘ���ʗp
# @desc		�f�B���N�g���̓ǂݍ��݂��x��
# @package	serveImageFS
# @access	public
# @author	�֒��J�@��
# @create	2008/06/06
# @version	1.00
# @version	1.10
# @update	2008/09/26 �摜��Memcached�d�l����
#********************************************

use strict;
# �p�X�̏C���K�v����
use lib qw(/home/vhosts/JKZ);
my $q = CGI->new ();
my $image = $q->param ('f') if defined $q->param ('f');
use JKZ::UsrWebDB;
## Modified �摜��memcached�𗘗p���ăL���b�V���� 2008/09/26 BEGIN
#require JKZ::UsrWebDB;



## DiskFile�d�l BEGIN

my $image_dir = '/home/httpd/htdocs/img/img_hp01/';
my $data = $image_dir . $image;
## Modified 2008/09/24
my $mime_type;
if ($image =~ /jpg$/) {
	$mime_type = 'image/jpeg';
}
elsif ($image =~ /gif$/) {
	$mime_type = "image/gif";
}
elsif ($image =~ /png$/) {
	$mime_type = "image/png";
}

use MIME::Base64 qw(encode_base64 decode_base64);

## �L���b�V���T�[�o�[��192.168.10.30�ɕύX
my $memcached = JKZ::UsrWebDB::MemcacheInit ({
					'servers' => ["192.168.10.30:11211"],
					#'servers' => ["127.0.0.1:11211"],
					compress_threshold => 10_000,
					compress_ratio => 0.9,
				});
my $obj = $memcached->get ("ImageHP01:$image");

if (!$obj) {
	local $/;
	local *IMG;
	open (IMG, $data);
	$obj = encode_base64 (<IMG>);
	#binmode (IMG);
	#binmode STDOUT;
	close (IMG);
	$memcached->add ("ImageHP01:$image", $obj, 120);
}

my $cached_image = decode_base64 ($obj);
print $q->header (-type => $mime_type);
print $cached_image;

## DiskFile�d�l END


=pod
## DataBase�d�l BEGIN

## �L���b�V���T�[�o�[��192.168.10.30�ɕύX
my $memcached = JKZ::UsrWebDB::MemcacheInit ({
					#'servers' => ["192.168.10.30:11211"],
					'servers' => ["127.0.0.1:11211"],
					compress_threshold => 10_000,
					compress_ratio => 0.9,
				});
my $obj = $memcached->get ("ImageHP01:$image");
if(!$obj) {
	my $dbh = JKZ::UsrWebDB::connect ();
	$dbh->do ('set names utf8');
	#$dbh->do ('use HP_general');
	my ($image_data, $mime_type) = $dbh->selectrow_array ("SELECT imagedata, mime_type FROM CommonUse.tHP01IconM WHERE imagename=?", undef, $image);
	$dbh->disconnect ();

	$obj = {
		mime_type => $mime_type,
		image_data=> $image_data,
	};
	$memcached->add ("ImageHP01:$image", $obj, 120);
}

	print $q->header(-type=>$obj->{mime_type},-Content_Length=>length ($obj->{image_data}));
	#print $q->header(-type=>'image/gif');#,-Content_Length=>length ($obj->{image_data}));
	print $obj->{image_data};
## DataBase�d�l END
=cut



## Modified �摜��memcached�𗘗p���ăL���b�V���� 2008/09/26 BEGIN

=pod
print $q->header (-type => $mime_type);
open (IMG, $data);
binmode (IMG);
binmode STDOUT;
print <IMG>;
close (IMG);
=cut

ModPerl::Util::exit ();
