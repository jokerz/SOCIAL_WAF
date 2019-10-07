#!/usr/bin/perl

#******************************************************
# 
# �މ���i�󃁁[���j
# 2008/06/03
#******************************************************

use strict;
use MIME::Parser;
use MIME::WordDecoder;
use POSIX;
use lib qw(/home/vhosts/JKZ);
use JKZ::UsrWebDB;
use WebUtil;

#########################################
#	���[���̓��e
my $mail_from;
my $mail_date;
my $mail_subject;
my $mail_body;
#########################################

sub dump_entity {
    my ($entity) = @_;

    $mail_from .= $entity->head->get('from');
    chomp ($mail_from);
    $mail_date .= $entity->head->get('date');
    $mail_subject .= $entity->head->get('subject');

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

##################################################
#
#	���ʏ����ݒ�
#

    #####@�g�pSQL
    my $SQL = {
				'check_id'		=>	"SELECT id_no,mailaddr FROM $HASHTB->{MEMBER} WHERE mailaddr=? AND del_flg=?",
				'update_flg'	=>	"UPDATE $HASHTB->{MEMBER} SET del_flg=?, del_date=NOW() WHERE id_no=? AND mailaddr=?",
				'insert_id'		=>	"INSERT INTO $HASHTB->{WITHDRAW} (id_no,withdraw_date) VALUES (?,NOW())",
    		  };
#
##################################################

	my $dbh = UsrWebDB::connect ('kensho');
    $dbh->do('SET NAMES SJIS');
	
	#####id�ƃ����A�h�����݂��������`�F�b�N
	my ($id_no_mem,$mailaddr_mem) = $dbh->selectrow_array ($SQL->{check_id}, undef,$mail_from,1);
	unless (defined ($id_no_mem)) { die "no data $! \n"; }
	#	�g�����U�N�V��������
	my $attr_ref = UsrWebDB::TransactInit ($dbh);
	eval {
		$dbh->do ($SQL->{update_flg}, undef, "0", $id_no_mem, $mailaddr_mem);
		$dbh->do ($SQL->{insert_id}, undef, $id_no_mem);
    	$dbh->commit ();
	};
	UsrWebDB::TransactFin ($dbh,$attr_ref,$@);

	$dbh->disconnect ();

    1;
}

exit(&main ? 0 : -1);

#------------------------------
1;
