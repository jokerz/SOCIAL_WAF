#!/usr/bin/perl

#******************************************************
# @desc		�މ���i�󃁁[���j
# @package	withdraw_qmail.pl
# @access	public
# @author	Iwahase Ryo
# @create	2008/09/19
# @version	1.00
#******************************************************

use strict;
use MIME::Parser;
use MIME::WordDecoder;
use POSIX;
use lib qw(/home/vhosts/JKZ);
use JKZ::UsrWebDB;
use WebUtil;

use JKZ::DB::Member;

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

	## ���[�����M�҂̃V�X�e��id���擾
	my $owid = getUserInfo ($mail_from);
	chomp ($owid);

    my @parts = $entity->parts;
    if (@parts) {
    	my $i;
        foreach $i (0 .. $#parts) {       # dump each part...
            dump_entity($parts[$i]);
        }
    }
    else {
## �މ�ɂ͕����e�[�u���̑��삪�K�v 2008/10/07
## tMemberM, tUserImageF
## tComunityM, tCommunityMemberM
##
## tFriendF, tFriendAgreementF
=pod
-- STEP1) --
UPDATE tMemberM SET status_flag=4 WHERE owid=1;
-- STEP2) --
DELETE FROM tUserImageF WHERE owid=1;
-- STEP3) ��Ƀ����o�[���������B���̌�Ƀf�[�^�폜 --
UPDATE tCommunityM SET community_total_member = (community_total_member-1)
 WHERE community_id IN (SELECT community_id FROM tCommunityMemberM WHERE community_member_owid=1);
-- STEP4) �f�[�^���폜 --
DELETE FROM tCommunityMemberM community_member_owid=1 AND status_flag=2

-- STEP5) --
DELETE FROM tFriendAgreementF WHERE my_owid=1 OR friend_owid=1;
-- STEP6) --
DELETE FROM tFriendF WHERE my_owid=1 OR friend_owid=1;
=cut

    	#my $sql = "UPDATE $HASHTB->{MEMBER} SET status_flag=?, withdraw_date=NOW() WHERE owid=? AND mobilemailaddress=?";
    	my $sql = "UPDATE HP_general.tMemberM SET status_flag=?, withdraw_date=NOW() WHERE owid=? AND mobilemailaddress=?";
		my $dbh = JKZ::UsrWebDB::connect ();
    	$dbh->do('SET NAMES SJIS');

		#	�g�����U�N�V��������
		my $attr_ref = JKZ::UsrWebDB::TransactInit ($dbh);
		eval {
			$dbh->do ($sql, undef, 4, $owid, $mail_from);
    		$dbh->commit ();
		};
		if ($@) {
			$dbh->rollback ();
		}
		JKZ::UsrWebDB::TransactFin ($dbh,$attr_ref,$@);

		$dbh->disconnect ();
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

    1;
}

exit(&main ? 0 : -1);

#------------------------------
1;
