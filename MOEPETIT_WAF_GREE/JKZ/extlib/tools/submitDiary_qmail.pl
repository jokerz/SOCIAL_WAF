#!/usr/bin/perl

#******************************************************
# @desc		添付画像付日記メール受信処理
# 			メール添付画像を保存
# @package	submitDiary_qmail.pl
# @access	public
# @author	Iwahase Ryo
# @create	2006/06/17
# @version	1.00
#******************************************************


use strict;
#モジュールのチェック
eval ("use MIME::Parser;"); die "[err] MIME::Parser がインストールされてません。 \n" if $@;
eval ("use MIME::WordDecoder;"); die "[err] MIME::WordDecoder がインストールされてません。 \n" if $@;
eval ("use Image::Magick;"); die "[err] MIME::Image::Magick がインストールされてません。 \n" if $@;
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
#	メールの内容
#*************************
my $mail_from;
my $mail_date;
my $mail_subject;
my $mail_body;

#********************************
# 受信メール処理と画像取り出し
#  及び画像格納
#********************************
sub dump_entity {
    my ($entity) = @_;

  # HEADER
    $mail_from .= $entity->head->get('from');
    $mail_date .= $entity->head->get('date');
    $mail_subject .= unmime ($entity->head->get('subject'));

my $diary;
	## メール送信者のシステムidを取得
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
    	## MimeTypeの取得と処理
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
		# 画像を取り扱うときの共通処理 (例：元画像・320に変更・64に変更の3つに加工する)
		#///////////////////////////////////////////////////////////////////////////////
            my $err;
            my $image = Image::Magick->new ();

		#////////////////////////////////////
		# 画像をDataBaseにインサートする処理
		#////////////////////////////////////
			my ($thumbnail_320, $thumbnail_200, $thumbnail_64);
			my $image_data = $body->as_string;

## STEP.1) 画像を加工
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

## STEP.2) 加工済み画像をデータベースにinsert
			$dbh->do ('use HP_general;');
$dbh->do('set names utf8');
			#$sql = "REPLACE INTO tUserImageF (owid, image, thumbnail_320, thumbnail_200, thumbnail_64, mime_type) VALUES (?, ?, ?, ?, ?, ?)";
			## Modified 2008/06/25
			$sql = "REPLACE INTO tUserImageF (owid, image, thumbnail_320, thumbnail_200, thumbnail_64, mime_type) VALUES (?, ?, ?, ?, ?, CONCAT('image/', ?))";
			$rc = $dbh->do ($sql, undef, $owid, $image_data, $thumbnail_320, $thumbnail_200, $thumbnail_64, $subtype);

			## ここで画像のidを取得して日記の本文に画像処理プログラムと必要パラメータを挿入
			## /serveImage.mpl?owid=$owid&id=$image_insertid;s=2 の形を生成
			my $image_insertid = $dbh->{mysql_insertid};

## STEP.3) 画像レコードのprimary keyである直前のidを取得して画像urlを生成
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
								. '画像</a>'
								;
=cut
			## 画像ﾘﾝｸ付画像表示
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
			## 画像ﾘﾝｸ付画像表示
			my $image_param64  = '@@' . int ($owid) . $image_insertid . ';s4@@';
			my $image_param240 = '@@' . int ($owid) . $image_insertid . ';s2@@';

			my $serveImageScript = '<a href="' . $image_param240 . '">'
								 . '<img src="' . $image_param64 . '" /></a><br />'
								 ;
## Modify 2008/08/07 END

## STEP.3) 日記の処理…
			## 日記挿入データ
			
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
				subject			=> '画像日記投稿',
				from			=> 'diary@1mp.jp',
			};
#=cut
			my $myDiaryPage = JKZ::DB::DiaryPage->new ($dbh);
			$dbh->do ('set names sjis');
			if (!$myDiaryPage->executeUpdate ($diaryInsertData)) {
				$mailcontents->{contents_body} ="日記の登録に失敗しました。";
			}
			else {
				$mailcontents->{contents_body} = "日記の登録に成功しました。";
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
# メール送信者情報取得
#*************************
sub getUserInfo {
	my $mail_from = shift;
	chomp ($mail_from);
	my $dbh = JKZ::UsrWebDB::connect ();
	my $myMember = JKZ::DB::Member->new ($dbh);

	#///////////////////////////////////
	# 送信元メールアドレスからowidの取得
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
	# メールの読み込み
	#//////////////////
    my $buf;
    {
        local $/;
        $buf= <>;
    }


	### -------------------------
	#'*'   => sub { jcode(shift)->utf8 }, #本来はISO-2022-JPのみ
	MIME::WordDecoder->default(
	    MIME::WordDecoder->new( [
	        '*'   => sub { jcode(shift)->sjis }, #本来はISO-2022-JPのみ
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
