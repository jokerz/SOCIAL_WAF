#! /usr/bin/perl -w
#******************************************************
# ���i�J�e�S���P�p�̃v���O�����@�G����
# loadEmoji.pl sample.gif
# @desc   ���[�J���摜��DB�Ɋi�[
#         ���̂Ƃ��Ɍ��摜�ȊO�ɁAsample�ƋL�ڂ���Ă���摜���������āAsample�ƋL�ڂ���Ă���摜�𐶐�
#         ���������Ƃ��āA�摜�f�B���N�g����
#         �摜�����擾���āAshellscript�ɂ���
#         �V�F���X�N���v�g����loadEmoji.pl�����s���A�摜���f�[�^�x�[�X�Ɋi�[����B
#         �摜�t�@�C�����̊g���q����O�̕������R���e���c�R�[�h�Ƃ���
#         �摜�i�[�X�N���v�g�FloadEmoji.pl
#                   �����Fpath/to/filename product_id  eg: loadEmoji.pl pic/1.gif 1
#
# step1 �摜�ۑ�
#  �f�B���N�g��tmp/pic���쐬���đΏۉ摜��ۑ�����
#
# step2 �t�@�C����p�ӂ��� �摜�ꗗ�t�@�C���𐶐�
#  [ryo@penguin tmp]$ echo -e '#!/bin/sh\n\n' > ls.sh
#  [ryo@penguin tmp]$ find pic/ -name '*gif' >> ls.sh
#
# step3 �ꗗ�t�@�C�����V�F���X�N���v�g�ɂ���B
#  �摜�ꗗ�t�@�C�����̃��X�g���R�}���h���s���ɂ���
#  �R�}���h��perl loadEmoji.pl pic/1.gif 1 �𐶐�����t���߂ɒu������
#  [ryo@penguin tmp]$ perl -i -p -e 's/^(pic\/)(\d)(\.gif)/perl loadEmoji\.pl $1$2$3 $2/g' ls.sh
#
# step4 ls.sh���V�F�����s�\�ɂ���
#  [ryo@penguin tmp]$ chmod +x ls.sh
#
# step5 ���s
#  [ryo@penguin tmp]$ sh ls.sh
#  1 loaded
#  2 loaded
#  3 loaded
#  4 loaded
#  5 loaded
#  6 loaded
#  �c
#
# @package	loadEmoji.pl
# @access	public
# @author	Iwahase Ryo
# @create	2010/06/01
# @version	1.00
#******************************************************

use strict;
eval ("use Image::Magick;"); die "[err] Image::Magick ���C���X�g�[������Ă܂���B \n" if $@;

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
# �����usample�v�̉摜
#**********************************
#my $READFILE = 'sample.gif';
my $READFILE = 'bg_smp.gif';
my $sampletmplt = Image::Magick->new();
$sampletmplt->Read($READFILE);


my ($err, $image_data, $sample_image_data);

#**********************************
# �摜�̓ǂ݂��݂ƃf�[�^��
#**********************************
my $img = Image::Magick->new();
$err = $img->Read($image_file);
die "Can't read image file: $err\n" if $err;
$image_data = $img->ImageToBlob();

my $height  = $img->Get('height');
my $width   = $img->Get('width');

#**********************************
# �A�j���[�V������Î~�ɂ��ẴT���v���p
#**********************************
#$sampletmplt->Composite(image=>$img, gravity=>"north");
$sampletmplt->Composite(image=>$img->[0], gravity=>"north");
$sample_image_data = $sampletmplt->ImageToBlob();

#**********************************
# �A�j���[�V������Ԃ̂܂܂ł̃T���v���p
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
