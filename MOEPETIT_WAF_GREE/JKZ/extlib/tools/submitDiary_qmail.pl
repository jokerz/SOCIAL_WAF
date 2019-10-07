#!/usr/bin/perl

#******************************************************
# @desc		�Y�t�摜�t���L���[����M����
# 			���[���Y�t�摜��ۑ�
# @package	submitDiary_qmail.pl
# @access	public
# @author	Iwahase Ryo
# @create	2006/06/17
# @version	1.00
#******************************************************


use strict;
#���W���[���̃`�F�b�N
eval ("use MIME::Parser;"); die "[err] MIME::Parser ���C���X�g�[������Ă܂���B \n" if $@;
eval ("use MIME::WordDecoder;"); die "[err] MIME::WordDecoder ���C���X�g�[������Ă܂���B \n" if $@;
eval ("use Image::Magick;"); die "[err] MIME::Image::Magick ���C���X�g�[������Ă܂���B \n" if $@;
use POSIX;
use NKF;
use Jcode;
use lib qw(/home/vhosts/JKZ);
use JKZ::UsrWebDB;
use JKZ::DB::Member;
use JKZ::DB::DiaryPage;
use JKZ::TransferMail;

my $outputdir= '/home/vhosts/hp01.1mp.jp/local/tmp_pool/';

#*************************
#	���[���̓��e
#*************************
my $mail_from;
my $mail_date;
my $mail_subject;
my $mail_body;

#********************************
# ��M���[�������Ɖ摜���o��
#  �y�щ摜�i�[
#********************************
sub dump_entity {
    my ($entity) = @_;

  # HEADER
    $mail_from .= $entity->head->get('from');
    $mail_date .= $entity->head->get('date');
    $mail_subject .= unmime ($entity->head->get('subject'));

my $diary;
	## ���[�����M�҂̃V�X�e��id���擾
	my $owid = getUserInfo ($mail_from);
	chomp ($owid);

	## BODY
    my @parts = $entity->parts;
#$diary = unmime ($entity->bodyhandle->as_string)."\n";
	## multipart...
    if (@parts) {
        my $i;
        foreach $i (0 .. $#parts) {
            dump_entity($parts[$i]);
        }
    }
    else {
 
						   #->parts(0)->bodyhandle->as_string
    	## MimeType�̎擾�Ə���
        my ($type, $subtype) = split ('/', $entity->head->mime_type);
        my $body = $entity->bodyhandle;
		## text
        if ($type =~ /^(text|message)$/) {
            $mail_body .= $body->as_string;
        }
         else {
		## binary
            my $filename= $entity->head->recommended_filename;

		#///////////////////////////////////////////////////////////////////////////////
		# �摜����舵���Ƃ��̋��ʏ��� (��F���摜�E320�ɕύX�E64�ɕύX��3�ɉ��H����)
		#///////////////////////////////////////////////////////////////////////////////
            my $err;
            my $image = Image::Magick->new ();

		#////////////////////////////////////
		# �摜��DataBase�ɃC���T�[�g���鏈��
		#////////////////////////////////////
			my ($thumbnail_320, $thumbnail_200, $thumbnail_64);
			my $image_data = $body->as_string;

## STEP.1) �摜�����H
			$err = $image->BlobToImage ($image_data);
			error ("Can't convert image data: $err") if $err;

			$err = $image->Scale (geometry => "240x320");
			die "Can't scale image file: $err\n" if $err;
			$thumbnail_320 = $image->ImageToBlob ();

			$err = $image->Scale (geometry => "120x200");
			die "Can't scale image file: $err\n" if $err;
			$thumbnail_200 = $image->ImageToBlob ();

			$err = $image->Scale (geometry => "64x64");
			die "Can't scale image file: $err\n" if $err;
			$thumbnail_64 = $image->ImageToBlob ();

			my $dbh = JKZ::UsrWebDB::connect ();
			my ($sql, $rc);

## STEP.2) ���H�ς݉摜���f�[�^�x�[�X��insert
			$dbh->do ('use HP_general;');
$dbh->do('set names utf8');
			#$sql = "REPLACE INTO tUserImageF (owid, image, thumbnail_320, thumbnail_200, thumbnail_64, mime_type) VALUES (?, ?, ?, ?, ?, ?)";
			## Modified 2008/06/25
			$sql = "REPLACE INTO tUserImageF (owid, image, thumbnail_320, thumbnail_200, thumbnail_64, mime_type) VALUES (?, ?, ?, ?, ?, CONCAT('image/', ?))";
			$rc = $dbh->do ($sql, undef, $owid, $image_data, $thumbnail_320, $thumbnail_200, $thumbnail_64, $subtype);

			## �����ŉ摜��id���擾���ē��L�̖{���ɉ摜�����v���O�����ƕK�v�p�����[�^��}��
			## /serveImage.mpl?owid=$owid&id=$image_insertid;s=2 �̌`�𐶐�
			my $image_insertid = $dbh->{mysql_insertid};

## STEP.3) �摜���R�[�h��primary key�ł��钼�O��id���擾���ĉ摜url�𐶐�
			#require JKZ::WebEnvConf qw($HASHURL);
use  JKZ::WebEnvConf qw($HASHURL);
=pod
			my $serveImageScript = '<a href="' . $HASHURL->{PATHINFO}->{MODPERL} . '/' . $HASHURL->{SCRIPT}->{SERVEIMAGE}
								. '?owid='
								. $owid
								. '&id='
								. $image_insertid
								. ';s=3'
								. '">'
								. '�摜</a>'
								;
=cut
			## �摜�ݸ�t�摜�\��
## Modify 2008/08/07 BEGIN
=pod
			my $serveImageScript = '<a href="' . $HASHURL->{PATHINFO}->{MODPERL} . '/' . $HASHURL->{SCRIPT}->{SERVEIMAGE}
								. '?owid='
								. $owid
								. '&id='
								. $image_insertid
								. ';s=3'
								. '">'
								. '<img src="' . $HASHURL->{PATHINFO}->{MODPERL} . '/' . $HASHURL->{SCRIPT}->{SERVEIMAGE}
								. '?owid='
								. $owid
								. '&id='
								. $image_insertid
								. ';s=4'
								. '" /></a><br />'
								;
=cut
			## �摜�ݸ�t�摜�\��
			my $image_param64  = '@@' . int ($owid) . $image_insertid . ';s4@@';
			my $image_param240 = '@@' . int ($owid) . $image_insertid . ';s2@@';

			my $serveImageScript = '<a href="' . $image_param240 . '">'
								 . '<img src="' . $image_param64 . '" /></a><br />'
								 ;
## Modify 2008/08/07 END

## STEP.3) ���L�̏����c
			## ���L�}���f�[�^
			
			my $diaryInsertData = {
				id			=> -1,
				owid		=> $owid,
			#tpagef_id	=> $tpagef_id,
			#open_level	=> ,
			#diary_date	=> ,
				subject		=> $mail_subject,
				diary		=> $serveImageScript . unmime($mail_body),
				comment_flag=> 2,
			};
#=pod
			my $mailcontents = {
				sendmail		=> '/usr/sbin/sendmail',
				subject			=> '�摜���L���e',
				from			=> 'diary@1mp.jp',
			};
#=cut
			my $myDiaryPage = JKZ::DB::DiaryPage->new ($dbh);
			$dbh->do ('set names sjis');
			if (!$myDiaryPage->executeUpdate ($diaryInsertData)) {
				$mailcontents->{contents_body} ="���L�̓o�^�Ɏ��s���܂����B";
			}
			else {
				$mailcontents->{contents_body} = "���L�̓o�^�ɐ������܂����B";
			}

#		my $myMail = JKZ::TransferMail->new ();
#		$myMail->setMailContents ($mailcontents);
#		$myMail->setMailAddress ($mail_from);
#		$myMail->SendMailSend ();

		}
	}
    1;
}


#*************************
# ���[�����M�ҏ��擾
#*************************
sub getUserInfo {
	my $mail_from = shift;
	chomp ($mail_from);
	my $dbh = JKZ::UsrWebDB::connect ();
	my $myMember = JKZ::DB::Member->new ($dbh);

	#///////////////////////////////////
	# ���M�����[���A�h���X����owid�̎擾
	#///////////////////////////////////
	my %condition = (
		column		=> 'owid',
		wherestr	=> 'mobilemailaddress = ?',
		placeholder => ["$mail_from",],
	);

	my $myMember = JKZ::DB::Member->new ($dbh);
	if ($myMember->getOneValue (\%condition)) {
		return $myMember->{columns}->{owid};
	}
}


#*************************
# main
#*************************
sub main {
	#//////////////////
	# ���[���̓ǂݍ���
	#//////////////////
    my $buf;
    {
        local $/;
        $buf= <>;
    }


	### -------------------------
	#'*'   => sub { jcode(shift)->utf8 }, #�{����ISO-2022-JP�̂�
	MIME::WordDecoder->default(
	    MIME::WordDecoder->new( [
	        '*'   => sub { jcode(shift)->sjis }, #�{����ISO-2022-JP�̂�
	        ]
	    )
	);



    my $parser = new MIME::Parser;
    $parser->output_to_core (1);
    $parser->tmp_recycling (1);
    $parser->tmp_to_core (1);
    $parser->use_inner_files (1);
#my $entity =$parser->parse(\*STDIN);
#dump_entity (\$entity);
    my $entity = $parser->parse_data ($buf) or die;

    dump_entity ($entity);

    1;
}

exit (&main ? 0 : -1);

#------------------------------
1;
