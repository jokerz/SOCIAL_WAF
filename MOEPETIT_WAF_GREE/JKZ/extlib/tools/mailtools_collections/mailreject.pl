#!/usr/bin/perl

#########################
#
#	�����}�K���ۏ���
#	2005-06-05
#
#########################

use strict;
use MIME::Parser;
use MIME::WordDecoder;
#use POSIX;
#use Jcode;
use lib qw(/home/kensho/WebDB);
use UsrWebDB;
#use WebUtil;

my $outputdir= '/home/kensho/local/tmp_pool/';

#########################################
#
#	���[���̓��e
#
my $mail_from;
my $mail_date;
my $mail_subject;
my $mail_body;
#
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
    if (@parts) {
    	my $i;
        foreach $i (0 .. $#parts) {       # dump each part...
            dump_entity($parts[$i]);
        }
    }
    1;
}
#------------------------------
#
# main
#

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

##################################################
#
#	���ʏ����ݒ�
#
	my $dev_flg;
	 if ($mail_from =~ /^[^@]+\@docomo\.ne\.jp/) {$dev_flg = 'd';}
	elsif ($mail_from =~ /\@ezweb\.ne\.jp/) {$dev_flg = 'e'; }
	elsif ($mail_from =~ /vodafone\.ne\.jp/) {$dev_flg = 'v'; }
	else {$dev_flg = 'pc';}# if $mail_from !~ /\@docomo\.ne\.jp/ || $mail_from !~ /\@ezweb\.ne\.jp/ || $mail_from !~ /vodafone\.ne\.jp/;


    #####@�g�p�e�[�u����hash
	my $Table = 'mail_reject';
    #####@�g�pSQL
    my %SQL = (
				'inert_reject'	=>	"REPLACE INTO $Table ( mailaddr, dev_flg, regdate ) VALUES( ?, ?, NOW())",
    		  );
#
##################################################

	my $dbh = UsrWebDB::connect ();
    $dbh->do('SET NAMES SJIS');

	##############################3
	#
	#	�g�����U�N�V��������
	#
	my $attr_ref = WebDB::TransactInit ($dbh);
	eval {
    	$dbh->do ($SQL{inert_reject},undef,$mail_from,$dev_flg);
    	$dbh->commit ();
	};
	WebDB::TransactFin ($dbh,$attr_ref,$@);

	$dbh->disconnect ();

    1;
}

exit(&main ? 0 : -1);

#------------------------------
1;
