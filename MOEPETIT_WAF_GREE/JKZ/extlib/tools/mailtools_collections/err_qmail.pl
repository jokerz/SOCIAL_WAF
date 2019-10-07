#!/usr/bin/perl

#########################
#
#	エラーメール処理
#	2005-07-18
#   err_qmail.pl
#########################

use strict;
use MIME::Parser;
use MIME::WordDecoder;
use POSIX;
use lib qw(/home/httpd/WebDB);
use UsrWebDB;

#########################################
#
#	メールの内容
my $mail_from;
my $mail_date;
my $mail_subject;
my $mail_body;
#
#########################################

sub dump_entity {
    my ($entity) = @_;

  # HEAD
    $mail_from .= $entity->head->get('from');
    chomp ($mail_from);
    $mail_date .= $entity->head->get('date');
    $mail_subject .= $entity->head->get('subject');

  # BODY
    my @parts = $entity->parts;
    if (@parts) { foreach my $i (0 .. $#parts) { dump_entity($parts[$i]); } }
    else {
        my ($type, $subtype) = split('/', $entity->head->mime_type);
        my $body = $entity->bodyhandle;
        if ($type =~ /^(text|message)$/) { $mail_body .= $body->as_string; }
    }
    1;
}
#------------------------------
# main
sub main {
  # read STDIN
    my $buf;
    {
        local $/;
        $buf= <>;
    }
  # Parse setting...
    my $parser = new MIME::Parser;
    $parser->output_to_core(1);
    $parser->tmp_recycling(1);
    $parser->tmp_to_core(1);
    $parser->use_inner_files(1);

    my $entity = $parser->parse_data($buf) or die;

    dump_entity($entity);

	my $err_mailaddr;
	if ($mail_body =~ /\<([\w\-+\.]+\@[\w\-+\.]+)\>:/) { $err_mailaddr = $1; }
    
    #####@使用SQL
    #######エラー挿入テーブルはMRGで月ごとに変更
    my $err_table = 'errormail_' . strftime("%Y%m", localtime);
    my @sql = (
				#####以前にエラーを出してる場合はカウントアップ
				"UPDATE logdata.$err_table SET count=count+1, date=NOW() WHERE error_mailaddr=?",
				#####初めての場合は挿入
				"INSERT INTO logdata.$err_table (error_mailaddr,count,date) VALUES (?,1,NOW())",
    		  );

	my $dbh = UsrWebDB::connect ("kensho");
	$dbh->do('SET NAMES SJIS');
	my $sth = $dbh->prepare($sql[0]);
	if ($sth->execute ($err_mailaddr) < 1) {
		$sth = $dbh->prepare($sql[1]);
		$sth->execute ($err_mailaddr);
	}
	$sth->finish ();
	$dbh->disconnect ();

	########for debug-------------->
	my $now = strftime("%Y-%m-%d %I:%M:%S", localtime);
	my $tmpfile = '/home/ryo/local/tmp_pool/test.log';
    open (FF,">>$tmpfile");
	print FF "\n<----" . $now . "\n" . $err_mailaddr . '------>';
	close (FF);
	########for debug-------------->
    1;
}

exit(&main ? 0 : -1);

1;
