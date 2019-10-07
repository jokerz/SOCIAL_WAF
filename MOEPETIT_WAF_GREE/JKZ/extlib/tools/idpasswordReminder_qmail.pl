#!/usr/bin/perl

#******************************************************
# 
# ID忘れの会員処理
# 2008/06/03
#******************************************************

use strict;
use MIME::Parser;
use MIME::WordDecoder;
use POSIX;
use lib qw(/home/vhosts/JKZ);
use JKZ::UsrWebDB;

use JKZ::TransferMail;

my $outputdir= '/home/vhosts/hp01.1mp.jp/local/tmp_pool/';

#******************************************************
#	メールの内容
#******************************************************
my $mail_from;
my $mail_date;
my $mail_subject;
my $mail_body;


sub dump_entity {
    my ($entity) = @_;

    $mail_from .= $entity->head->get('from');
    chomp ($mail_from);
    $mail_date .= $entity->head->get('date');
    $mail_subject .= $entity->head->get('subject');
	chomp ($mail_subject);

    my @parts = $entity->parts;
    if (@parts) {
    	my $i;
        foreach $i (0 .. $#parts) {       # dump each part...
            dump_entity($parts[$i]);
        }
    }
    1;
}



sub main {
    my $buf;
    {
        local $/;
        $buf= <>;
    }
    my $parser = new MIME::Parser;
    $parser->output_to_core(1);
    $parser->tmp_recycling(1);
    $parser->tmp_to_core(1);
    $parser->use_inner_files(1);

    my $entity = $parser->parse_data($buf) or die;
    dump_entity($entity);

    #####@使用テーブルのhash
    my %TABLE = (
    				#'reminder'		=>	'HP_general.tReminderLogF',
    				'member'		=>	'HP_general.tMemberM',
    				'mailconf'		=>	'HP_management.tMailConf',
    			);
	my %SQL = (
					'getidpassword' => "SELECT id, password, HPeditURL, nickname FROM $TABLE{member} WHERE mobilemailaddress=? AND status_flag=2",
					'getmailconf'	=> "SELECT from_addr, subject, header, body, footer FROM $TABLE{mailconf} WHERE type=?",
			 );

	#******************************************************
	# 共通初期設定
	#******************************************************
    # 識別番号 1＝仮登録 2=エラー 3=完了 4=お問い合わせ 5=IDパスワード忘れ 6=メールアドレス変更 7=メールアドレス変更完了 8=退会

    my $dbh = JKZ::UsrWebDB::connect ();
    $dbh->do('SET NAMES SJIS');

	my $sth = $dbh->prepare ($SQL{getidpassword});
	$sth->execute ($mail_from);
	my $memref = $sth->fetchrow_hashref ();
	$sth->finish ();

	#******************************************************
    # 一致データあり・IDとﾊﾟｽﾜｰﾄﾞ取得OK
    #******************************************************
	if (defined ($memref)) {
		$sth = $dbh->prepare ($SQL{getmailconf});
		$sth->execute (5);
		my $mailref = $sth->fetchrow_hashref ();
		$sth->finish ();


		$mailref->{body} =~ s{ %& (.*?) &% }{ exists ($memref->{$1}) ? $memref->{$1} : ""}gex;


		my $mailcontents = {
			sendmail		=> '/usr/sbin/sendmail',
			subject			=> $mailref->{subject},
			from			=> $mailref->{from_addr},
			contents_body	=>
"
$mailref->{header}
$mailref->{body}
$mailref->{footer}
",
		};


		my $myMail = JKZ::TransferMail->new ();
		$myMail->setMailContents ($mailcontents);
		$myMail->setMailAddress ($mail_from);
		$myMail->SendMailSend ();

	}
	$dbh->disconnect ();

    1;
}

exit(&main ? 0 : -1);

#------------------------------
1;
