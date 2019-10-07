#!/usr/bin/perl

#******************************************************
# @desc		空メール登録処理 変更登録用（新規登録用プログラム名と同じ)
# @package	receiveqmail
# @author	Iwahase Ryo
# @create	2009/09/17
# @update   2010/08/02 サイトのドメインを変更したため
# @version	
#******************************************************


use strict;
use vars qw($include_path);

BEGIN {
	## クラスのインクルードパスを取得するための処理
	require Cwd;
	my $pwd = Cwd::getcwd();
	($include_path = $pwd) =~ s!/modules/.+!!;

	unshift @INC, $include_path;
}

use MIME::Parser;
use MIME::WordDecoder;
use Jcode;

use MyClass::WebUtil;
use MyClass::UsrWebDB;
use MyClass::TransferMail;

## 処理ログ出力ディレクトリ…対象アカウントにより変更すること
my $outputdir= '/home/vhosts/DENISMCD/JKZ/modules/mail/info/';

#******************************************************
#	メールの内容
#******************************************************
my $mail_from;
my $mail_date;
my $mail_subject;
my $mail_body;


sub dump_entity {
    my ($entity) = @_;

  # HEAD
    $mail_from .= $entity->head->get('from');
    chomp($mail_from);
    $mail_date .= $entity->head->get('date');
    $mail_subject .= unmime($entity->head->get('subject'));
	chomp($mail_subject);

  # BODY
    my @parts = $entity->parts;
    if (@parts) {
    	my $i;
        foreach $i (0 .. $#parts) {
            dump_entity($parts[$i]);
        }
    }
 
    	# Modified 処理追加 2010/03/23 BEGIN
#=pod
   	# MimeTypeの取得と処理 
    my ($type, $subtype) = split ('/', $entity->head->mime_type);
    my $body = $entity->bodyhandle;
    ### text
    if ($type =~ /^(text|message)$/) {
            $mail_body .= $body->as_string;
    }
#=cut
    # Modified 処理追加 2010/03/23 END
 
 
    1;
}
#------------------------------
#
# main
#

sub main {
    my $buf;
    {
        local $/;
        $buf= <>;
    }

	#******************************************************
	#	メールの件名の文字コードの処理
	#******************************************************
	#'*'   => sub { jcode(shift)->utf8 }, #本来はISO-2022-JPのみ
	MIME::WordDecoder->default(
	    MIME::WordDecoder->new( [
	        '*'   => sub { jcode(shift)->sjis }, #本来はISO-2022-JPのみ
	        ]
	    )
	);

    my $parser = new MIME::Parser;
    $parser->output_to_core(1);
    $parser->tmp_recycling(1);
    $parser->tmp_to_core(1);
    $parser->use_inner_files(1);

    my $entity = $parser->parse_data($buf) or die;

    dump_entity($entity);

    #####@使用テーブルのhash
    my %TABLE = (
    				'mailsetting'	=> 'DENISMCD.tMailSettingM',
    				'member'		=> 'DENISMCD.tMemberM',
    				'maillog'		=> 'DENISMCD.tMailAddressLogF',
    			);

	#my ($guid) = MyClass::WebUtil::decryptBlowFish($mail_subject);
    # Modified 本文対応 処理追加 2010/03/07
    my ($guid) = MyClass::WebUtil::decryptBlowFish($mail_body);

	my $dbh    = MyClass::UsrWebDB::connect();

	#*********************************************
	# 全体的に使用する変数
	#******************************************************
	my $sql;
	my $msg;
	my $return_mail_id;
	my @messages;
	my $session_id;

	#********************************
	# step 1) 登録済み確認 会員チェックと既にﾒｱﾄﾞが登録されているかtMemberMから検索
	#********************************
	## guidとﾒﾙｱﾄﾞを条件にヒットしなかったらエラー（ここが新規登録用と違う）
	#$sql = sprintf("SELECT IF(mobilemailaddress IS NOT NULL, 1, -1)  FROM %s WHERE guid=? AND status_flag=?;", $TABLE{member});

	#my $rv = $dbh->selectrow_array($sql, undef, $guid, 2);
	## 返信メールの確定 1==regist 2==support 3==modify 4==error 5==withdraw 6==order
	##					新規    変更      登録済み そもそもデータ無し
	#$return_mail_id = 1 == $rv ? 3 : 0 > $rv ? 4 : 5;

	#$messages[1] = undef;
	#$messages[3] = undef;
	#$messages[4] = "登録されているメールアドレスがございません。新規にメルマガ登録をしてください。";
	#$messages[5] = "未登録会員です。キラ☆カワの会員様以外はメルマガ登録できません。";
	#$msg = $messages[$return_mail_id];


	## 処理内容に対応した数値を返す
	$sql = sprintf(
"SELECT IF
  (mobilemailaddress IS NOT NULL, IF(mobilemailaddress=?, 4, 3), 1)
 FROM %s
  WHERE
   guid=?
  AND
   status_flag=?;", $TABLE{member});

	$return_mail_id = $dbh->selectrow_array($sql, undef, $mail_from, $guid, 2);

	## 返信メールの確定 1==info 3==modify 4==error 5==unknownuser
	##					新規    変更      登録済み そもそもデータ無し
	$messages[1] = "メールアドレスの登録がございません。";
	$messages[3] = undef;
	$messages[4] = "メールアドレス登録処理は完了しております。";
	$messages[5] = "未登録会員です。会員様以外はメルマガ登録できません。";
	$msg = $messages[$return_mail_id];

	goto RETURN_MAIL_EXIT unless 3 == $return_mail_id;

	#********************************
	# step 2)	変更メアド仮登録 /変更メアド仮登録済み確認 
	#			tMemberMにメールアドレスが存在する場合は、メールアドレス変更となる
	#			tMailAddressLogFのformer_mobilemailaddressとtMemberMのmobilemailaddressが一致しているかの確認→この場合は変更メアド仮登録状態
	#			変更メアド仮登録状態の場合は最終処理が必要
	#********************************

	$sql = sprintf("SELECT session_id FROM %s WHERE guid=? AND new_mobilemailaddress=?
 AND former_mobilemailaddress=(SELECT mobilemailaddress FROM %s WHERE guid=?);", $TABLE{maillog}, $TABLE{member});

	$session_id = $dbh->selectrow_array($sql, undef, $guid, $mail_from, $guid);

	#********************************
	# step 3)	変更ｱﾄﾞﾚｽ仮登録が未完了の場合は仮登録処理を実行
	#			session_idが存在しないことが条件
	#********************************
	unless ($session_id) {
		require POSIX;
		POSIX->import(qw(strftime));
		$ENV{'TZ'} = "Japan";
		my $TODAY = strftime("%Y%m%d", localtime);
		my $now = strftime("%Y-%m-%d %I:%M:%S", localtime);
		my $now = strftime("%Y%m%d%I%M%S", localtime); # timeformat 20100112150822 (2010/01/12 15:08 20)
		my $tmpfile = $outputdir . $TODAY . '.log';

		$session_id = MyClass::WebUtil::encodeMD5($guid, $now);

		#my $debuginfo = sprintf("[ $now ] --mailfrom : %s --mail_subject : %s --guid : %s --session_id : %s ", $mail_from, $mail_subject, $guid, $session_id);
	    my $debuginfo = sprintf("[ $now ] --mailfrom : %s --mail_body : %s --guid : %s --session_id : %s ", $mail_from, $mail_body, $guid, $session_id);
	    open (FF,">>$tmpfile");
		print FF $debuginfo . "\n";
		close (FF);

		$sql = sprintf("INSERT INTO %s (guid, session_id, status_flag, new_mobilemailaddress, registration_date, former_mobilemailaddress)
 VALUES(
  ?, ?, ?, ?, NOW(),
  (SELECT mobilemailaddress FROM %s WHERE guid=?)
 );", $TABLE{maillog}, $TABLE{member});




		my $attr_ref = MyClass::UsrWebDB::TransactInit($dbh);
		eval {
			## 仮登録なのでstatus_flagに１を挿入
			$dbh->do($sql, undef, $guid, $session_id, 1, $mail_from, $guid);
			$dbh->commit();
		};
		if ($@) {
			$return_mail_id = 4;
			$msg = '仮登録失敗です。';
			goto RETURN_MAIL_EXIT;
		}

		MyClass::UsrWebDB::TransactFin($dbh, $attr_ref, $@);
	}

 ## Modified サイトドメインを変更したため登録URLの変更 -- 2010/08/02 --
	#$msg = sprintf("下記のURLにアクセスして登録を完了させてください。
	#				http://m.1mp.jp/mod-perl/mm.mpl?s=%s",
	#			$session_id);
	$msg = sprintf("下記のURLにアクセスして登録を完了させてください。
					http://www.avidimer.com/mod-perl/mm.mpl?s=%s",
				$session_id);

	#******************************************************
	# step 4)	ここからは共通のメール返信処理
	#			条件idの値によって返信メールの内容が変わる
	#******************************************************
RETURN_MAIL_EXIT:

 	my ($From,$Sub,$Header,$Body,$Footer) = $dbh->selectrow_array("SELECT from_address, subject, header, body, footer FROM DENISMCD.tMailSettingM WHERE id=?;", undef, $return_mail_id);

	$dbh->disconnect();

	$Body =~ s!(%%msg%%)!$msg!;

	my $mailcontents = {
		sendmail		=> '/usr/sbin/sendmail',
		subject			=> $Sub,
		from			=> $From,
		contents_body	=>
"
$Header
$Body
$Footer
",
	};

	#******************************************************
	# step 5) メール送信
	#******************************************************
	my $myMail = MyClass::TransferMail->new();
	$myMail->setMailContents($mailcontents);
	$myMail->setMailAddress($mail_from);
	$myMail->SendMailSend();

    1;
}

exit(&main ? 0 : -1);

#------------------------------
1;
