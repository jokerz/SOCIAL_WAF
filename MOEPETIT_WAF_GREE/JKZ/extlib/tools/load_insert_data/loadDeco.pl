#!/usr/bin/perl -w #******************************************************
#
# 商品カテゴリ３用　でこめ
#
# @desc		ローカル画像をDBに格納
#			gifアニメを横幅60pxで静止したサンプル画像を生成
# 			ls images > load_images.sh
# 			chmod +x laod_images.sh
# 			perl -i.bk -p -e's/(.*?)(\.jpg)|(.*?)(_smp[0-9]{1,2})(\.jpg)/$1$2$3 "$1"/g' load_images.sh
# 			perl -i.bk -p -e's/(.*?)(_smp[0-9]{1,2}|)(\.jpg)/$1$2$3 "$1"/g' load_img.sh
# 			----これで画像名と商品コード＆サンプル画像名と商品コードを一覧にした----
# 			vi load_images.sh
# 			:1,$s/.*/.\/loadDeco.pl images\/&/
# 			とする
# @package	loadDeco.pl
# @access	public
# @author	Iwahase Ryo
# @create	2009/06/11
# @version	1.00
#******************************************************

use strict;
eval ("use Image::Magick;"); die "[err] Image::Magick がインストールされてません。 \n" if $@;

use lib qw(/home/vhosts/MYSDK/JKZ);
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


my ($err, $image_data, $sample_image_data);


#**********************************
# 画像の読みこみとデータ化
#**********************************
my $img = Image::Magick->new();
$err = $img->Read($image_file);

my ($width, $height) = $img->Get('width','height');

die "Can't read image file: $err\n" if $err;
$image_data = $img->ImageToBlob();

#**********************************
# gifアニメ画像の1フレーム目だけをリサイズしてサンプルにする
#**********************************
#my $smp_width = ("199" <= $width) ? "100" : "60";
my $smp_width = ("199" <= $width) ? "100" : $width;
$img->[0]->Thumbnail(geometry=>"$smp_width",mode=>"Unframe");
$sample_image_data = $img->[0]->ImageToBlob();


#my $sql = "REPLACE INTO MYSDK.testProductImageM (productm_id,image,image1, mime_type,lastupdate) VALUES(?,?,?,?,NOW())";
my $sql = "REPLACE INTO MYSDK.tmpImageM (product_code,image,image1, mime_type,lastupdate) VALUES(?,?,?,?,NOW())";
my $dbh = JKZ::UsrWebDB::connect();
$dbh->do('set names utf8');
$dbh->do (
            $sql,
			undef,
			$image_name, $image_data, $sample_image_data, $mime_type);
$dbh->disconnect ();
warn "$image_name loaded\n";

exit (0);
