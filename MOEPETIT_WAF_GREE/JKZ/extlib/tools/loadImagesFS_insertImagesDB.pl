#! /usr/bin/perl -w
#******************************************************
# @desc		���[�J���摜��DB�Ɋi�[
# 			���������Ƃ��āA�摜�f�B���N�g����
# 			�摜�����擾���āAshellscript�ɂ���
# 			ls images > load_images.sh
# 			chmod +x laod_images.sh
# 			perl -i.bk -p -e's/(.*?)(\.jpg)|(.*?)(_smp[0-9]{1,2})(\.jpg)/$1$2$3 "$1"/g' load_images.sh
# 			perl -i.bk -p -e's/(.*?)(_smp[0-9]{1,2}|)(\.jpg)/$1$2$3 "$1"/g' load_img.sh
# 			----����ŉ摜���Ə��i�R�[�h���T���v���摜���Ə��i�R�[�h���ꗗ�ɂ���----
# 			vi load_images.sh
# 			:1,$s/.*/.\/loadImages.pl images\/&/
# 			�Ƃ���
# @package	loadImages.pl
# @access	public
# @author	Iwahase Ryo
# @create	2006/12/31
# @version	1.00
#******************************************************

use strict;
eval ("use Image::Magick;"); die "[err] Image::Magick ���C���X�g�[������Ă܂���B \n" if $@;

use lib qw(/home/vhosts/JKZ);
use MyClass::UsrWebDB;

use less;
use Image::Magick;



die "Usage: $0 image_file [ image_name ]\n" unless @ARGV >= 1 && @ARGV <= 2;
my $image_file = shift (@ARGV);
my $image_name = shift (@ARGV);
($image_name = $image_file) =~ s|.*/|| if !defined $image_name;

my %mime_map = (
	"gif" => "image/gif",
	"jpg" => "image/jpeg",
	"jpeg" => "image/jpeg",
	"jpe" => "image/pjpeg",
	"png" => "image/png"
);
my $mime_type = $mime_map{lc ($1)} if $image_file =~ /\.([^.]+)$/;
die "Cannot determine image MIME type\n" if !defined $mime_type;


my $img = Image::Magick->new;
my ($err, $image_data, $thumbnail_data_240,$thumbnail_data_70,$thumbnail_data_50);

$err = $img->Read ($image_file);
die "Can't read image file: $err\n" if $err;
$image_data = $img->ImageToBlob ();

$err = $img->Scale (geometry => "240x240");
die "Can't scale image file: $err\n" if $err;
$thumbnail_data_240 = $img->ImageToBlob ();

$err = $img->Scale (geometry => "70x70");
die "Can't scale image file: $err\n" if $err;
$thumbnail_data_70 = $img->ImageToBlob ();

$err = $img->Scale (geometry => "50x50");
die "Can't scale image file: $err\n" if $err;
$thumbnail_data_50 = $img->ImageToBlob ();

my $dbh = MyClass::UsrWebDB::connect();
$dbh->do('set names utf8');

## ���摜���i�[���Ȃ��^�C�v
$dbh->do (
		"REPLACE INTO 1MP.tProductImageM
        (productm_id, image, image1,image2, mime_type) VALUES(?,?,?,?,?)",
            undef,
            $image_name, $thumbnail_data_240, $thumbnail_data_70, $thumbnail_data_50, $mime_type
);


## ���摜���i�[����^�C�v
#$dbh->do (
#		"REPLACE INTO 1MP.tProductImageM
#		(productm_id, image, image1,image2, mime_type) VALUES(?,?,?,?,?)",
#			undef,
#			$image_name, $image_data, $thumbnail_data_240,$thumbnail_data_70,$thumbnail_data_50,$mime_type);


$dbh->disconnect ();
warn "$image_name loaded\n";

exit (0);
