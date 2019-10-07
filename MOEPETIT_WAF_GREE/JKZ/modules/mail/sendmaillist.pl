#!/usr/bin/perl -w
# 初期設定 -----------------------------------------------#
use strict;
use lib qw(/home/vhosts/JKZ);
#use lib qw(../../common);
use MyClass::UsrWebDB;
use Time::HiRes;
use Net::SMTP;
use Data::Dumper;
use Goku::SiteSettings;
use Goku::StrConv;

#########################
#  メール設定のタイトル
#########################
my @Mail_Title =('広告メール設定', 
				 'クイズ用正解者通知メール設定',
				 'クイズ用不正解者通知メール設定');


my ($db, $sth, $row, $sql);
my $errno=0;
my @setsubject=();
my @setcontents=();
my $rec;

my @mailsetting;


my $body=' ' x 100000;
my $send=1;
my $Header=' ' x 100000;
my @lostid;
my $interval=0;
my $sqlcnt=0;
my $sths;

#############################
# 開始時刻を設定
#############################
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my $today = ($year+1900) . '/' . ($mon+1) . '/' . "$mday $hour:$min:$sec";

#############################
# パラメータを取得
#############################
my ($mailkind, $id) = @ARGV;
#############################
# データベース名・テーブル名を決定
#############################
my @LOOKUP = (
	{'setting' => '1MP.tAdmailsetting', 'body' => '1MP.tAdcontents',
		'manage' => '1MP.tAdmailmanage'.$id,	'id_field' => 'admailno'},
	{'setting' => 'quizwinmailsetting', 'body' => 'quizwincontents',
		'manage' => 'quizwinmanage'.$id, 'id_field' => 'quizno'},
	{'setting' => 'quizlosemailsetting', 'body' => 'quizlosecontents',
		'manage' => 'quizlozemanage'.$id, 'id_field' => 'quizno'}
	);
my $look_ref = $LOOKUP[$mailkind-1];

unless($mailkind >= 1 && $mailkind <= 3){
	#送信不可
	warn 'メール送信失敗(メール種別エラー) ' . $Mail_Title[$mailkind-1] .
	  ": ID=$id : $today\n";
	exit;
}
warn 'メール送信開始 ' . $Mail_Title[$mailkind-1] .
": ID=$id : $today : " . Time::HiRes::time . "\n";

#############################
# 送信情報データベースへコネクト
#############################

$db = MyClass::UsrWebDB::connect();
$db->do('set names sjis');
if(!defined($db)){
	$errno=17;
	goto ERR_SOKET;
}
#############################
# メール内容を取得
# クイズ、広告メール共通
#############################
$sql = "select ifnull(carrier,0), ifnull(subject,''),
 ifnull(contents,'') from $look_ref->{'body'} where
 $look_ref->{'id_field'} = $id;";

$sth=$db->prepare($sql);
$row=$sth->execute;
if(!defined($row) || 0==$row){
	#送信失敗
	warn 'メール送信失敗(送信内容情報取得エラー) ' .
	  $Mail_Title[$mailkind-1] . ": ID=$id \n";
	$sth->finish;
	$db->disconnect;
	undef($db);
	$errno=11;
	goto ERR_SOKET;
}

#############################
# 送信設定情報を取得
# クイズ、広告メール共通
#############################
$sql = "select ifnull(fromaddress,''), ifnull(server,''),
 ifnull(header,'') from $look_ref->{'setting'} where
 $look_ref->{'id_field'} = $id;";
$sths=$db->prepare($sql);
$row=$sths->execute;
if(!defined($row) || $row==0){
	#送信失敗
	$sth->finish;
	$sths->finish;
	$db->disconnect;
	undef($db);
	warn 'メール送信失敗(送信設定情報取得エラー) ' .
	  $Mail_Title[$mailkind-1] . ": ID=$id \n";
	$errno=12;
	goto ERR_SOKET;
}


#############################
# メール内容を配列へ設定
#############################
my ($crr, $subject, $contents);
$sth->bind_columns(\$crr, \$subject, \$contents);
while($sth->fetch){
	#本文を設定
	$setsubject[$crr] = $subject;
	$setcontents[$crr] = $contents;
}
$sth->finish;

#コネクションをきらないためにSQL文を投げる
$db->do("select now();");

#############################
# 送信設定情報を配列へ設定
#############################
my ($readfrom, $readserver, $readheader);
$sths->bind_columns(\$readfrom, \$readserver, \$readheader);
while($sths->fetch){
	if($readfrom eq "" || $readserver eq "" ){
		#送信失敗
		$sths->finish;
		$db->disconnect;
		undef($db);
		warn 'メール送信失敗(送信設定情報 内容エラー) ' .
		  $Mail_Title[$mailkind-1] . ": ID=$id Server=$readserver\n";
		$errno=13;
		goto ERR_SOKET;
	}
	# SMTPでソケットを捏ねる
	my $sp;
	unless($sp = Net::SMTP->new($readserver, Debug => 1)){
		#接続できなければ、このサーバー情報は使わない
		next;
	}
	#@mailsettingはハッシュのリファレンスの配列
	push @mailsetting, {'smtp' => $sp,
						'from' => $readfrom,
						'server' => $readserver,
						'headerbase' => $readheader};
}
$sths->finish;

unless(defined $mailsetting[0]{'smtp'}){
	#SMTP接続が1つも有効にならなかった
	goto ERR_SOKET;
}

#############################
# メールを送信
############################# 
#$sth=$db->prepare("select distinct m.id_no, m.password, m.carrier, m.mailaddr
# from member m, $look_ref->{'manage'} t where m.id_no = t.id_no");
#sth=$db->prepare("select distinct m.memid, m.password, m.cryptpwd, m.carrier, m.mailaddr
# from tMemberM m, $look_ref->{'manage'} t where m.memid = t.id_no");

#$sth=$db->prepare("select distinct m.memid, m.password, m.cryptpwd, m.carrier, m.mailaddr
# from tMemberM m, $look_ref->{'manage'} t where m.id_no = t.id_no");

#$sth=$db->prepare("select distinct m.owid, m.password, m.cryptpassword, m.carrier, m.mobilemailaddress
# from 1MP.tMemberM m, $look_ref->{'manage'} t where m.owid = t.id_no");
 # 2010/02/01
$sth=$db->prepare("select distinct m.owid, m.carrier, m.mobilemailaddress
 from 1MP.tMemberM m, $look_ref->{'manage'} t where m.owid = t.id_no");

$row=$sth->execute;
if(!defined($row) || 0==$row ){
	#送信失敗
	$sth->finish;
	$db->disconnect;
	undef($db);
	warn 'メール送信失敗(送信先情報取得エラー) ' .
	  $Mail_Title[$mailkind-1] . ": ID=$id \n";
	$errno=14;
    goto ERR_SOKET;
}

warn $Mail_Title[$mailkind-1] . ": ID=$id " . ' 送信ループ開始 ' .
"($$) " . Time::HiRes::time . "\n";
# Modified 2010/02/01
#my ($userid, $password, $cryptpwd, $dstmail);
#$sth->bind_columns(\$userid, \$password, \$cryptpwd, \$crr, \$dstmail);
my ($userid, $dstmail);
$sth->bind_columns(\$userid, \$crr, \$dstmail);
#$sendの初期値は1
my $sv; #@mailsettingの添え字
my $sendcnt = 0; #総送信数
while($sth->fetch){
	#単純にラウンドロビン実現するための処理
	$sendcnt++;
	#総送信数をサーバーの数で割って、そのあまりを添え字に使う
	$sv = $sendcnt % ($#mailsetting + 1);
# Modified 2010/02/01
	#if($userid eq "" || $password eq "" || $dstmail eq "" ||
	if($userid eq "" || $dstmail eq "" ||
	   ($setsubject[$crr] eq "" && $setcontents[$crr] eq "") ){
		#会員ID、パスワード、メールアドレスのいずれかが空文字の場合
		#もしくは件名と本文の両方が空文字の場合は,この会員をエラーにする
		$send=0;
		goto SENDERR;
	}

	#本文の読み出し
	$body=$setcontents[$crr];

	#IDとﾊﾟｽﾜｰﾄﾞを置換
### 	$body =~ s/i=\d{8}&p=.{13}/i=$userid\&p=$password/gi;
### 	$body =~ s/id=\d{8}&password=.{13}/id=$userid\&password=$password/gi;
### 	$body =~ s/s=.{8}&/s=$no\&/gi;
#	$body =~ s/i=0000000000&p=1111/i=$userid\&p=$password/gi;

# Modified 2010/02/01
	#$body =~ s/i=0000000000&p=1111/i=$userid\&p=$cryptpwd/gi;
	#$body =~ s/id=0000000000&password=1111/id=$userid\&password=$cryptpwd/gi;
	$body =~ s/i=0000000000&p=1111/i=$userid/gi;
	$body =~ s/id=0000000000&password=1111/id=$userid/gi;

#	$body =~ s/s=22222222&/s=$no\&/gi;

	#完全な形の本文にする
	# 2 == 2 ** 1; 8 == 2 **3
	#DoCoMo,AUは Base64
	my $num_crr = (log $crr) / (log 2); #numeric carrier
	$body = Goku::StrConv::GetMailBody($body,$num_crr);

	#完全な形のヘッダーにする
	$Header = Goku::StrConv::GetMailHeader(
		$setsubject[$crr], #Suject
		$mailsetting[$sv]{'from'}, #From
		$dstmail, #To
		$num_crr, #ここはnumericが欲しい
		$mailsetting[$sv]{'headerbase'} #付加ヘッダー
		);

    # MAILコマンドの作成、送信
	unless( $mailsetting[$sv]{'smtp'}->mail($mailsetting[$sv]{'from'}) ){
		$mailsetting[$sv]{'smtp'}->reset();
		$send = 0;
		goto SENDERR;
	}
	# RCPT TO:の送信
	unless($mailsetting[$sv]{'smtp'}->to("$dstmail") ){
		$mailsetting[$sv]{'smtp'}->reset();
		$send=0;
		goto SENDERR;
	}
	# DATA コマンドの送信
	unless($mailsetting[$sv]{'smtp'}->data() ){
		$mailsetting[$sv]{'smtp'}->reset();
		$send=0;
		goto SENDERR;
	}
	# Headerの送信
	unless($mailsetting[$sv]{'smtp'}->datasend($Header) ){
		$mailsetting[$sv]{'smtp'}->reset();
		$send=0;
		goto SENDERR;
	}
	# bodyの送信
	unless($mailsetting[$sv]{'smtp'}->datasend($body."\n") ){
		$mailsetting[$sv]{'smtp'}->reset();
		$send=0;
		goto SENDERR;
	}
	# データー送信おしまい
	unless($mailsetting[$sv]{'smtp'}->dataend() ){
		$mailsetting[$sv]{'smtp'}->reset();
		$send=0;
		goto SENDERR;
	}

SENDERR:	
	if($send==0){
		if($userid ne ""){
			push @lostid, $userid;
		}
		#初期値に戻す
		$send=1;
	}
}

$db->disconnect;
undef($db);

warn $Mail_Title[$mailkind-1] . ": ID=$id " . ' 送信ループ終了 ' .
"($$) " . Time::HiRes::time . "\n";

ERR_SOKET:
if($errno==0){
	# メール送信が失敗している送信先をチェック
	if($#lostid>=0){
		#失敗先あり
		warn $Mail_Title[$mailkind-1] . ": ID=$id " .
		  ' 送信フラグ更新' . "\n";

		$db = JKZ::UsrWebDB::connect ();
		$db->do('set names sjis');
		#送信テーブルに対して、送信失敗フラグを立てるのみ、
		#member表に対しては処理しない
		foreach (@lostid){
			if($_ ne ""){
				$db->do("update $look_ref->{'manage'} set send_status = 0
                         where $look_ref->{'id_field'}='$_';");
			}
		}
		$db->disconnect;
		undef($db);
	}
}
else{
	#エラーが発生したので、リトライを通知
	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	warn 'メール送信失敗 (Error Code=' . $errno . ") " . $Mail_Title[$mailkind-1] . ": ID=$id : " . ($year+1900) . '/' . ($mon+1) . '/' . "$mday $hour:$min:$sec : " . Time::HiRes::time . "\n";
=pod
  #ここでは、リトライ処理として、テンプレートテーブルを名前変更することで
  #再度リトライ対象となる。
	my $retcnt=0;
	while($retcnt<5){
		$db=UsrWebDB::connect('commondata');
		$row=$db->do("show tables like '$detsendtbl';");
		if(defined($row) && $row==1){
			$db->do("alter table $detsendtbl rename to $detrettbl;");
			$retcnt=5;
			last;
		}
		else{
			$retcnt++;
		}
		$db->disconnect;
		undef($db);
	}
=cut
}

### QUITコマンドの送信
foreach (@mailsetting) {
	$_->{'smtp'}->quit();
}

if($errno==0){
	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$today = ($year+1900) . '/' . ($mon+1) . '/' . "$mday $hour:$min:$sec";
	
	warn 'メール送信終了 ' . $Mail_Title[$mailkind-1] . ": ID=$id " .
	  ($year+1900) . '/' . ($mon+1) . '/' . "$mday $hour:$min:$sec : " .
		Time::HiRes::time . "\n";
}

exit;
