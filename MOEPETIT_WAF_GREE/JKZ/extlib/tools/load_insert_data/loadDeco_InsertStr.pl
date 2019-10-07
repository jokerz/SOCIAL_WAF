#!/usr/bin/perl -w
#******************************************************
# @desc		ローカル画像をDBに格納
#			このときに元画像以外に、sampleと記載されている文字列を元画像に挿入して合成
# 			ls images > load_images.sh
# 			chmod +x laod_images.sh
# 			perl -i.bk -p -e's/(.*?)(\.jpg)|(.*?)(_smp[0-9]{1,2})(\.jpg)/$1$2$3 "$1"/g' load_images.sh
# 			perl -i.bk -p -e's/(.*?)(_smp[0-9]{1,2}|)(\.jpg)/$1$2$3 "$1"/g' load_img.sh
# 			----これで画像名と商品コード＆サンプル画像名と商品コードを一覧にした----
# 			vi load_images.sh
# 			:1,$s/.*/.\/loadImages.pl images\/&/
# 			とする
# @package	loadDeco_InsertStr.pl
# @access	public
# @author	Iwahase Ryo
# @create	2009/06/11
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
	"gif"	=> "image/gif",
	"jpg"	=> "image/jpeg",
	"jpeg"	=> "image/jpeg",
	"jpe"	=> "image/pjpeg",
	"png"	=> "image/png"
);
my $mime_type = $mime_map{lc ($1)} if $image_file =~ /\.([^.]+)$/;
die "Cannot determine image MIME type\n" if !defined $mime_type;


my ($err, $image_data, $sample_image_data);
my $ORIGINAL_TEXT = 'sample';
my $FONT        = '/home/vhostsuser/KKFLA/tmp_work/sazanami-gothic.ttf';
my $STROKE      = 'none';
my $FILL        = 'grey';
my $UNDERCOLOR  = 'none';
my $WIDTH  = '20';  #$image->Get('width');
my $HEIGHT = '20'; #$image->Get('height');
## If usIng Japanese make code utf8
my $code = '';

use Jcode;
my $text = $ORIGINAL_TEXT; #'utf8' eq $code ? jcode($ORIGINAL_TEXT)->utf8 : $ORIGINAL_TEXT;

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
my $image = Image::Magick->new();
my ($label);
$label = Image::Magick->new(size=>"$WIDTH x $HEIGHT",pointsize=>20,font=>$FONT);
$label->Read($image_file);
$label->Annotate(
    text=>$text,
    gravity=>"north",
    fill=>$FILL,
    stroke=>$STROKE,
    undercolor=>$UNDERCOLOR,
);

push (@$image, $label);
$image->Scale(geometry=>"60");
$sample_image_data = $image->ImageToBlob();



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
