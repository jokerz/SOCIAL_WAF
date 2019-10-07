#! /usr/bin/perl -w
#******************************************************
# 商品カテゴリ１用のプログラム　絵文字
# loadEmoji.pl sample.gif
# @desc   ローカル画像をDBに格納
#         このときに元画像以外に、sampleと記載されている画像を合成して、sampleと記載されている画像を生成
#         した準備として、画像ディレクトリで
#         画像情報を取得して、shellscriptにする
#         シェルスクリプトからloadEmoji.plを実行し、画像をデータベースに格納する。
#         画像ファイル名の拡張子から前の部分をコンテンツコードとする
#         画像格納スクリプト：loadEmoji.pl
#                   引数：path/to/filename product_id  eg: loadEmoji.pl pic/1.gif 1
#
# step1 画像保存
#  ディレクトリtmp/picを作成して対象画像を保存する
#
# step2 ファイルを用意して 画像一覧ファイルを生成
#  [ryo@penguin tmp]$ echo -e '#!/bin/sh\n\n' > ls.sh
#  [ryo@penguin tmp]$ find pic/ -name '*gif' >> ls.sh
#
# step3 一覧ファイルをシェルスクリプトにする。
#  画像一覧ファイル内のリストをコマンド実行文にする
#  コマンド→perl loadEmoji.pl pic/1.gif 1 を生成するtために置換する
#  [ryo@penguin tmp]$ perl -i -p -e 's/^(pic\/)(\d)(\.gif)/perl loadEmoji\.pl $1$2$3 $2/g' ls.sh
#
# step4 ls.shをシェル実行可能にする
#  [ryo@penguin tmp]$ chmod +x ls.sh
#
# step5 実行
#  [ryo@penguin tmp]$ sh ls.sh
#  1 loaded
#  2 loaded
#  3 loaded
#  4 loaded
#  5 loaded
#  6 loaded
#  …
#
# @package	loadEmoji.pl
# @access	public
# @author	Iwahase Ryo
# @create	2010/06/01
# @version	1.00
#******************************************************

use strict;
eval ("use Image::Magick;"); die "[err] Image::Magick がインストールされてません。 \n" if $@;

#use lib qw(/home/vhostsuser/KKFLA/JKZ);
use lib qw(/home/vhosts/MYSDK/JKZ);
use JKZ::UsrWebDB;
use less;
use Image::Magick;


die "Usage: $0 image_file [ image_name ]\n" unless @ARGV >= 1 && @ARGV <= 2;
my $image_file = shift (@ARGV);
my $image_name = shift (@ARGV);
($image_name = $image_file) =~ s|.*/|| if !defined $image_name;

my %mime_map = (
    "gif"  => "image/gif",
    "jpg"  => "image/jpeg",
    "jpeg" => "image/jpeg",
    "jpe"  => "image/pjpeg",
    "png"  => "image/png"
);
my $mime_type = $mime_map{lc ($1)} if $image_file =~ /\.([^.]+)$/;
die "Cannot determine image MIME type\n" if !defined $mime_type;


#**********************************
# 文字「sample」の画像
#**********************************
#my $READFILE = 'sample.gif';
my $READFILE = 'bg_smp.gif';
my $sampletmplt = Image::Magick->new();
$sampletmplt->Read($READFILE);


my ($err, $image_data, $sample_image_data);

#**********************************
# 画像の読みこみとデータ化
#**********************************
my $img = Image::Magick->new();
$err = $img->Read($image_file);
die "Can't read image file: $err\n" if $err;
$image_data = $img->ImageToBlob();

my $height  = $img->Get('height');
my $width   = $img->Get('width');

#**********************************
# アニメーションを静止にしてのサンプル用
#**********************************
#$sampletmplt->Composite(image=>$img, gravity=>"north");
$sampletmplt->Composite(image=>$img->[0], gravity=>"north");
$sample_image_data = $sampletmplt->ImageToBlob();

#**********************************
# アニメーション状態のままでのサンプル用
#**********************************
#my $clone_img = $img->Clone();
#$clone_img->Composite(image=>$sampletmplt, gravity => "South");
#$sample_image_data = $clone_img->ImageToBlob();

undef $sampletmplt;
undef $img;



my $dbh = JKZ::UsrWebDB::connect();
$dbh->do('set names utf8');
#tProductImageM
#my $sql = "REPLACE INTO MYSDK.tProductImageM (productm_id,image,image1, mime_type,lastupdate) VALUES(?,?,?,?,NOW())";
my $sql = "REPLACE INTO MYSDK.tmtImageM (product_name,image,image1, mime_type,lastupdate) VALUES(?,?,?,?,NOW())";
$dbh->do(
    $sql, 
    undef,
    $image_name, $image_data, $sample_image_data, $mime_type
);
$dbh->disconnect ();

warn "$image_name loaded\n";

exit (0);
