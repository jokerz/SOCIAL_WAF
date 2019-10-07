#!/usr/bin/perl

#******************************************************
# @desc		添付画像メール受信
# 			メール添付画像を保存
# @package	mailreceiver_with_image.pl
# @access	public
# @author	Iwahase Ryo
# @create	2006/12/31
# @update	2008/05/26 120x200を追加
# @update	2008/05/27  ReplaceでDBにインサート
# @update	2008/06/02  メール件名にIDがある場合はデータを上書き
# @version	1.00
#******************************************************

use strict;
#モジュールのチェック
eval ("use MIME::Parser;"); die "[err] MIME::Parser がインストールされてません。 \n" if $@;
eval ("use MIME::WordDecoder;"); die "[err] MIME::WordDecoder がインストールされてません。 \n" if $@;
eval ("use Image::Magick;"); die "[err] MIME::Image::Magick がインストールされてません。 \n" if $@;
#use MIME::Parser;
#use MIME::WordDecoder;
#use Image::Magick;

use lib qw(/home/vhosts/JKZ);
use WebUtil;
use JKZ::UsrWebDB;
use JKZ::DB::Member;
use JKZ::TransferMail;

## 画像出力先
my $outputdir= '/home/vhosts/hp01.1mp.jp/local/tmp';
my $mail_from;
my $mail_date;
my $mail_subject;
my $mail_body;

sub dump_entity {
    my ($entity) = @_;

  # HEADER
    $mail_from .= $entity->head->get('from');
    $mail_date .= $entity->head->get('date');
    $mail_subject .= $entity->head->get('subject');

	## メール送信者のシステムidを取得
	my $owid = getUserInfo ($mail_from);
	chomp ($owid);

	## 画像のidをメールの件名から取得
	my $userimage_id = $mail_subject if $mail_subject;

  # BODY
    my @parts = $entity->parts;
    if (@parts) {                    # multipart...
        my $i;
        foreach $i (0 .. $#parts) {       # dump each part...
            dump_entity($parts[$i]);
        }
    }
    else {                          # single part...

      # MimeTypeの取得と処理
        my ($type, $subtype) = split ('/', $entity->head->mime_type);
        my $body = $entity->bodyhandle;
        if ($type =~ /^(text|message)$/) {     # text
            $mail_body .= $body->as_string;
        }
        else {                               # binary
            my $filename= $entity->head->recommended_filename;
            #$filename =~ s/.bmp$/.png/i;

		#//////////////////////////////////////////////////////////////////////////////
		# 画像を取り扱うときの共通処理 (例：元画像・320に変更・64に変更の3つに加工する)
		#//////////////////////////////////////////////////////////////////////////////
            my $err;
            my $image = Image::Magick->new ();

		#//////////////////////////////////////////
		# 画像をDataBaseにインサートする処理
		#//////////////////////////////////////////
			my ($thumbnail_320, $thumbnail_200, $thumbnail_64);
			my $image_data = $body->as_string;

			$err = $image->BlobToImage ($image_data);
			error ("Can't convert image data: $err") if $err;

			#$err = $image->Scale (geometry => "320x240");
			$err = $image->Scale (geometry => "240x320");
			die "Can't scale image file: $err\n" if $err;
			$thumbnail_320 = $image->ImageToBlob ();

			#$err = $image->Scale (geometry => "120x200");
			$err = $image->Scale (geometry => "120x200");
			die "Can't scale image file: $err\n" if $err;
			$thumbnail_200 = $image->ImageToBlob ();

			$err = $image->Scale (geometry => "64x64");
			die "Can't scale image file: $err\n" if $err;
			$thumbnail_64 = $image->ImageToBlob ();

			my $dbh = JKZ::UsrWebDB::connect ();
			my ($sql, $rc);

			$dbh->do ('use HP_general;');
$dbh->do('set names utf8');
			if ($userimage_id) {
				## Modified 更新機能を追加。更新はメールの件名に画像IDをいれ、それを元に更新 2008/06/02
		#//////////////////////////////////////////
		# 既存画像の更新
		#//////////////////////////////////////////
				#$sql = "REPLACE INTO tUserImageF (id, owid, image, thumbnail_320, thumbnail_200, thumbnail_64, mime_type) VALUES (?, ?, ?, ?, ?, ?, ?)";
				## Modified 2008/06/25
				$sql = "REPLACE INTO tUserImageF (id, owid, image, thumbnail_320, thumbnail_200, thumbnail_64, mime_type) VALUES (?, ?, ?, ?, ?, ?, CONCAT('image/',?))";
				$rc = $dbh->do ($sql, undef, $userimage_id, $owid, $image_data, $thumbnail_320, $thumbnail_200, $thumbnail_64, $subtype);
			} else {
		#//////////////////////////////////////////
		# 新規画像の追加
		#//////////////////////////////////////////
				#$sql = "REPLACE INTO tUserImageF (owid, image, thumbnail_320, thumbnail_200, thumbnail_64, mime_type) VALUES (?, ?, ?, ?, ?, ?)";
				## Modified 2008/06/25
				$sql = "REPLACE INTO tUserImageF (owid, image, thumbnail_320, thumbnail_200, thumbnail_64, mime_type) VALUES (?, ?, ?, ?, ?, CONCAT('image/',?))";
				$rc = $dbh->do ($sql, undef, $owid, $image_data, $thumbnail_320, $thumbnail_200, $thumbnail_64, $subtype);
			}
        }
    }
    1;
}


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
		WebUtil::warnMSG_LINE ($myMember, __LINE__);
		return $myMember->{columns}->{owid};
	}
}


#------------------------------
#
# main
#

sub main {
  # メールの読み込み
    my $buf;
    {
        local $/;
        $buf= <>;
    }

    my $parser = new MIME::Parser;
    $parser->output_to_core (1);
    $parser->tmp_recycling (1);
    $parser->tmp_to_core (1);
    $parser->use_inner_files (1);

    my $entity = $parser->parse_data ($buf) or die;

    dump_entity ($entity);

    1;
}

exit (&main ? 0 : -1);

#------------------------------
1;
