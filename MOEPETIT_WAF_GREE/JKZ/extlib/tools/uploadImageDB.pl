#!/usr/bin/perl -w -I /home/httpd/WebDB

#******************************************************
# @desc		�摜�A�b�v���[�_�[
# 			DB�i�[�^�C�v
# @package	uploadImages_DB
# @access	public
# @author	Iwahase Ryo
# @create	2005/11/30
# @version	1.00
#******************************************************
#
# ����͓��ɉ摜�̃t�@�C�����͂���Ȃ�
# ���̑���ɉ摜���������鏤�i�R�[�h
# ���K�v�B1���i�ɑ΂��ĕ����摜�������Ă�
# ���i�R�[�h�{autoincrement��primarykey��
# ���Ă�̂Ŗ��Ȃ�

use strict;
eval ("use Image::Magick;"); die "[err] Image::Magick ���C���X�g�[������Ă܂���B \n" if $@;

use CGI;
use CGI::Carp qw(fatalsToBrowser);
use JKZ::WebEnvConf qw ($HASHTB $HASHURL);
use UsrWebDB;

my $q = new CGI;
$CGI::POST_MAX = 1024 * 100;	#���̃A�b�v���[�h�ő�e�ʂ�100KB�܂ŁB�t�@�C����5��

my @ImageData= $q->param('image');
my $ProdCode = $q->param('prod_code');
my $Id = "";
$Id = $q->param('id') if defined $q->param('id') || $q->param('id') ne "";
my $dbh = UsrWebDB::connect ("demo_master");
my ($i, $rc);
foreach my $imagedata (@ImageData) {
++$i;
	$imagedata = "" unless defined ($imagedata);
	my $mime_type = $q->uploadInfo($imagedata)->{'Content-Type'};

	###############################
	#
	# �����ŉ摜���f�B���N�g�ł͂Ȃ�DB�Ɋi�[���邩��ύX
	#
	#####@�����̊֐�����t���T�C�Y�̉摜��200x200 64X64 40x40 �̃T���l�C�������
	my ($image_data, $thumbnail_data_200, $thumbnail_data_64, $thumbnail_data_40) = Read_ImageFile ($imagedata);

		$rc = $dbh->do (
			"REPLACE INTO $HASHTB->{PRODIMAGE}
				(prod_code,image,thumbnail_200,thumbnail_64,thumbnail_40,mime_type) VALUES(?,?,?,?,?,?) ;",
			undef,
			$ProdCode, $image_data, $thumbnail_data_200, $thumbnail_data_64, $thumbnail_data_40, $mime_type
			) if $Id eq '';
	 $rc = $dbh->do ("REPLACE INTO $HASHTB->{PRODIMAGE} (id,prod_code,image,thumbnail_200,thumbnail_64,thumbnail_40,mime_type) VALUES(?,?,?,?,?,?,?) ;",
	 undef,
	 $Id, $ProdCode, $image_data, $thumbnail_data_200, $thumbnail_data_64, $thumbnail_data_40, $mime_type ) if defined ($q->param('id')) || $Id ne '';

	warn "Loading $ProdCode has benn successed \n";
}
$dbh->disconnect ();

unless ($rc eq '0E0') {
	my %VarS = $q->Vars();
	Print_Results (\%VarS);
}
else { warn "Failure \n"; exit (); }

sub Read_ImageFile {
	my $fh = shift;
	my $img = Image::Magick->new;
	my ($image_data, $thumbnail_data_200,$thumbnail_data_64,$thumbnail_data_40);
	my $err;

	(read ($fh, $image_data, -s $fh) == -s $fh)
		or error ("Can't read image file: $!");
	$err = $img->BlobToImage ($image_data);
	error ("Can't convert image data: $err") if $err;
	$err = $img->Scale (geometry => "200x200");
	error ("Can't convert image data: $err") if $err;
	$thumbnail_data_200 = $img->ImageToBlob ();
	$err = $img->Scale (geometry => "64x64");
	error ("Can't convert image data: $err") if $err;
	$thumbnail_data_64 = $img->ImageToBlob ();
	$err = $img->Scale (geometry => "40x40");
	error ("Can't convert image data: $err") if $err;
	$thumbnail_data_40 = $img->ImageToBlob ();

	return ($image_data, $thumbnail_data_200,$thumbnail_data_64,$thumbnail_data_40);
}


sub Print_Results {
	my $vars = shift;
	my $param = ( defined ( $vars->{id} ) && $vars->{id} ne '' ? "action=edit;prod_id=$vars->{prod_id};thumbnail=2" : "action=view" );
	print $q->redirect(-url=>"$HASHURL->{PATHADMIN}/mod-perl/setProduct.mpl?$param",-target=>"main");
	exit ();
}

sub error {
	my $msg = shift;

	print $q->header (-charset=>"shift_jis");
	print $q->start_html ();
	print $q-> ($q->escapeHTML ("Error: $msg")) . $q->end_html ();
	exit ();
}