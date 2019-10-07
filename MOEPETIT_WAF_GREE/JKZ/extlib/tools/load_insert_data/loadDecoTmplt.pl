#!/usr/bin/perl -w
#******************************************************
#
# ���i�J�e�S��4�p�@�ł��߃e���v��
#
# @desc		���[�J���摜��DB�Ɋi�[
#			gif�A�j��������60px�ŐÎ~�����T���v���摜�𐶐�
# 			ls images > load_images.sh
# 			chmod +x laod_images.sh
# 			perl -i.bk -p -e's/(.*?)(\.jpg)|(.*?)(_smp[0-9]{1,2})(\.jpg)/$1$2$3 "$1"/g' load_images.sh
# 			perl -i.bk -p -e's/(.*?)(_smp[0-9]{1,2}|)(\.jpg)/$1$2$3 "$1"/g' load_img.sh
# 			----����ŉ摜���Ə��i�R�[�h���T���v���摜���Ə��i�R�[�h���ꗗ�ɂ���----
# 			vi load_images.sh
# 			:1,$s/.*/.\/loadImages.pl images\/&/
# 			�Ƃ���
# @package	loadDeco.pl
# @access	public
# @author	Iwahase Ryo
# @create	2009/06/11
# @version	1.00
#******************************************************

use strict;
eval ("use Image::Magick;"); die "[err] Image::Magick ���C���X�g�[������Ă܂���B \n" if $@;

use lib qw(/home/vhostsuser/KKFLA/JKZ);
use JKZ::UsrWebDB;

use less;
use Image::Magick;


die "Usage: $0 image_file [ image_name ]\n" unless @ARGV >= 1 && @ARGV <= 2;
my $image_file = shift (@ARGV);
my $image_name = shift (@ARGV);
($image_name = $image_file) =~ s|.*/|| if !defined $image_name;

my %mime_map = (
	"gif"	=> "image/gif",
	"jpg"	=> "image/jpeg",
	"jpeg"	=> "image/jpeg",
	"jpe"	=> "image/pjpeg",
	"png"	=> "image/png"
);
my $mime_type = $mime_map{lc ($1)} if $image_file =~ /\.([^.]+)$/;
die "Cannot determine image MIME type\n" if !defined $mime_type;


my ($err, $image_data, $sample_image_data1, $sample_image_data2);


#**********************************
# �摜�̓ǂ݂��݂ƃf�[�^��
#**********************************
my $img = Image::Magick->new();
$err = $img->Read($image_file);

my ($width, $height) = $img->Get('width','height');

die "Can't read image file: $err\n" if $err;
$image_data = $img->ImageToBlob();

$img->Scale(geometry=>'60x80');
$sample_image_data1 = $img->ImageToBlob();
$img->Scale(geometry=>'30x40');
$sample_image_data2 = $img->ImageToBlob();


my $dbh = JKZ::UsrWebDB::connect();
$dbh->do('set names utf8');
$dbh->do (
		"REPLACE INTO MYSDK.tProductImageM
		(productm_code,image,image1,image2, mime_type) VALUES(?,?,?,?,?)",
			undef,
			$image_name, $image_data, $sample_image_data1, $sample_image_data2, $mime_type);
$dbh->disconnect ();
warn "$image_name loaded\n";

exit (0);
