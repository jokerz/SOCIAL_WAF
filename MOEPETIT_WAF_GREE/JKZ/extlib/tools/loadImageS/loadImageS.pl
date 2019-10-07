#! /usr/bin/perl -w
#******************************************************
# @desc		ローカル画像をDBに格納
#			このときに元画像以外に、sampleと記載されている画像を合成して、sampleと記載されている画像を生成
# 			した準備として、画像ディレクトリで
# 			画像情報を取得して、shellscriptにする
# 			ls images > load_images.sh
# 			chmod +x laod_images.sh
# 			perl -i.bk -p -e's/(.*?)(\.jpg)|(.*?)(_smp[0-9]{1,2})(\.jpg)/$1$2$3 "$1"/g' load_images.sh
# 			perl -i.bk -p -e's/(.*?)(_smp[0-9]{1,2}|)(\.jpg)/$1$2$3 "$1"/g' load_img.sh
# 			----これで画像名と商品コード＆サンプル画像名と商品コードを一覧にした----
# 			vi load_images.sh
# 			:1,$s/.*/.\/loadImages.pl images\/&/
# 			とする
# @package	loadImageS.pl
# @access	public
# @author	Iwahase Ryo
# @create	2009/06/09
# @version	1.00
#******************************************************

use strict;
eval ("use Image::Magick;"); die "[err] Image::Magick がインストールされてません。 \n" if $@;

use lib qw(/home/vhostsuser/KKFLA/JKZ);
use JKZ::UsrWebDB;

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


my $READFILE = 'bg_smp.gif';
my ($err, $image_data, $sample_image_data);

#**********************************
# サンプル画像テンプレートの読みこみ
#**********************************

my $sampletmplt = Image::Magick->new();
$sampletmplt->Read($READFILE);

#**********************************
# 画像の読みこみとデータ化
#**********************************
my $img = Image::Magick->new();
$err = $img->Read ($image_file);
die "Can't read image file: $err\n" if $err;
$image_data = $img->ImageToBlob ();

#**********************************
# 画像合成とデータ化
#**********************************
$sampletmplt->Composite(image=>$img, gravity=>"north");
$sample_image_data = $sampletmplt->ImageToBlob();



my $dbh = JKZ::UsrWebDB::connect();
$dbh->do('set names utf8');
$dbh->do (
		"REPLACE INTO MYSDK.tProductDecoIcon
		(productm_code,image,sample_image, mime_type) VALUES(?,?,?,?)",
			undef,
			$image_name, $image_data, $sample_image_data, $mime_type);
$dbh->disconnect ();
warn "$image_name loaded\n";

exit (0);
