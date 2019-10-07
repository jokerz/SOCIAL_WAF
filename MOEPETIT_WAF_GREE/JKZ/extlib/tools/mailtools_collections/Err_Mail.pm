package Err_Mail;
### #/usr/bin/perl -w

use strict;
#use DBI;

use lib qw(/home/ryo/WebDB);
use UsrWebDB;

#########################
#  サイト種別
#########################
my $SITE_common=0;
my $SITE_kensho=1;
my $SITE_melo=2;

#########################
#  会員状態
#########################
my $MEMSTS_nomem = -1;	#非会員
my $MEMSTS_tempmem = 0;	#仮会員
my $MEMSTS_member = 1;	#会員
my $MEMSTS_leave = 9;	#退会

#########################
#  キャリア種別
#########################
my $TERM_docomo = 1;
my $TERM_jphone = 2;
my $TERM_astel = 3;
my $TERM_h		= 4;
my $TERM_ezweb = 5;
my $TERM_other = 0;
my $TERM_common = 9;

#########################
#  メール種別
#########################
my $Mail_kind_regok=1;		#会員登録完了メール設定
my $Mail_kind_regng=2;		#会員登録失敗メール設定
my $Mail_kind_temp=3;		#仮登録完了メール設定
#// my $Mail_kind_apply=3;		#パスワード問い合わせ返信メール設定
my $Mail_kind_memid=4;		#会員ID問い合わせ返信メール設定
my $Mail_kind_vote=5;		#投票受付完了メール設定
my $Mail_kind_intro=6;		#友達紹介通知メール(友達側）設定
my $Mail_kind_login=7;		#友達紹介ログイン通知メール設定
my $Mail_kind_win=8;		#当選者通知メール設定
my $Mail_kind_chkwin=9;	#当選者確認メール設定
#// my $Mail_kind_chkpwd=10;	#パスワード変更通知メール設定
my $Mail_kind_chgml=11;	#メールアドレス変更通知メール設定
my $Mail_kind_adml=12;		#広告メール設定
my $Mail_kind_point=13;	#ポイントプレゼントメール設定
my $Mail_kind_voteurl=14;	#投票URL通知メール設定
my $Mail_kind_voteurlng=15;	#投票URL通知不可メール設定
my $Mail_kind_scratch=16;	#スクラッチチャンス当選者通知メール設定
my $Mail_kind_chkscr=17;	#スクラッチチャンス当選者確認メール設定
my $Mail_kind_memidng=18;	#パスワード問い合わせ返信不可メール設定
my $Mail_kind_win2=19;		#当選者通知メール設定(2等)
my $Mail_kind_chkwin2=20;	#当選者確認メール設定(2等)
my $Mail_kind_win3=21;		#当選者通知メール設定(3等)
my $Mail_kind_chkwin3=22;	#当選者確認メール設定(3等)
my $Mail_kind_qregok=23;	#クイズ用会員登録完了メール設定
my $Mail_kind_qregng=24;	#クイズ用会員登録失敗メール設定
my $Mail_kind_qwin=25;		#クイズ用当選者通知メール設定
my $Mail_kind_qchkwin=26;	#クイズ用当選者確認メール設定
my $Mail_kind_qlose=27;		#クイズ用落選者通知メール設定
my $Mail_kind_pctotel=28;	#PCから携帯へのURL送信メール設定
my $Mail_kind_max=28;

###############################################
# メール送信エラー
#	input:
#		mailaddress : メールエラーとするメールアドレス
#		mailinfo  : メール配信情報
#		serverkind: サーバー種別
#
#	output :
#		 1 : 正常終了
#		 0 : エラー
#
##############################################
sub ErrMail{
my $db;
my $mailaddress="";
my $mailinfo="";
my $mailkind=0;
my $mailno=0;
my $serverkind=0;
my $class=0;
my $serialno=0;
my $ret=0;
my $sitekind=0;
my $sth;
my $rec;
my $memid="";


	($mailaddress, $mailinfo, $serverkind) = @_;

	if($mailaddress eq "" || $serverkind==0){
		return 0;
	}

	#############################
	# DBをオープン
	#############################

	# メールサーバー１
	if($serverkind == 1) {
		unless($db=DBI->connect("DBI:mysql:mail;host=kensho-ML1;port=3306","mysql","mysql",
								 {RaiseError => 0, PrintError => 1})){
			sleep 1;
		}
	}
	# メールサーバー２
	elsif($serverkind == 2) {
		unless($db=DBI->connect("DBI:mysql:mail;host=kensho-ML2;port=3306","mysql","mysql",
								 {RaiseError => 0, PrintError => 1})){
			sleep 1;
		}
	}
	# メールサーバー３
	elsif($serverkind == 3) {
		unless($db=DBI->connect("DBI:mysql:mail;host=kensho-ML3;port=3306","mysql","mysql",
								 {RaiseError => 0, PrintError => 1})){
			sleep 1;
		}
	}

	elsif($serverkind == 4) {
		unless($db=DBI->connect("DBI:mysql:mail;host=kensho-ML4;port=3306","mysql","mysql",
								 {RaiseError => 0, PrintError => 1})){
			sleep 1;
		}
	}
	# メールサーバー５
	elsif($serverkind == 5) {
		unless($db=DBI->connect("DBI:mysql:mail;host=kensho-ML5;port=3306","mysql","mysql",
								 {RaiseError => 0, PrintError => 1})){
			sleep 1;
		}
	}
	# メールサーバー6
        elsif($serverkind == 6) {

###############################
#
#
#
    my $dbh = UsrWebDB::connect ("diet");
    $dbh->do ("INSERT INTO kara_mail (mailaddr) values (?)",undef,$mailaddress);
    $dbh->disconnect ();





	#	unless($db=DBI->connect("DBI:mysql:mail;host=kensho-ML6;port=3306","mysql","mysql",
	#							 {RaiseError => 0, PrintError => 1})){
        #                sleep 1;
               # }
        }
	else {
		return 0;
	}

	#############################
	# メールヘッダから情報を取得
	#############################
	if($mailinfo ne ""){
		### サイト種別;メール種別;メール番号
		($sitekind, $mailkind, $mailno) = split(/;/,$mailinfo);
		if(!defined($sitekind) || $sitekind =~ /\D/) {
			$sitekind=0;
		}
		if(!defined($mailkind) || $mailkind =~ /\D/) {
			$mailkind=0;
		}
		if(!defined($mailno) || $mailno =~ /\D/) {
			$mailno=0;
		}
	}

	#############################
	# メールエラー情報を更新
	#############################
	eval{
		$db->do("SET AUTOCOMMIT=0") || die "トランザクション開始失敗\n";
		$db->do("BEGIN") || die "トランザクション開始失敗\n";

		#メールエラー情報の更新
		$db->do("INSERT INTO errmail(mailkind, mailno, class, serialno, mailaddress, sitekind, errdate) 
		         VALUES($mailkind, $mailno, $class, $serialno, '$mailaddress', $sitekind, NOW());") ||  die "Error\n";
	};

	if ($@) {
	    # もし、DBIがRaiseErrorでdieしたら、$@ には$DBI::errstrが入っています。
		# 登録失敗
		$db->do("ROLLBACK");
	}
	else {
		$db->do("COMMIT");
		$ret=1;
	}
	$db->do("SET AUTOCOMMIT=0") || die "トランザクション開始失敗\n";
	$db->disconnect;
	undef($db);
	return $ret;
}1;
