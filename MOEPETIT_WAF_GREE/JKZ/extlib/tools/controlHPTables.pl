#!/usr/bin/perl -I /home/vhosts/JKZ

#******************************************************
# @desc     database �e�[�u���̃N���A
#           3�������Ƃ̂��܂����f�[�^���N���A����B
# ��荇���Âc�a�����I�ɑ|�����鏈����S���L�q
# �{����cron�Ŏ��Ԃ��ƕ�����
#
# @package  controlHPTable
# @access   public
# @author   Iwahase Ryo
# @create   2008/06/02
# @update	2008/10/01 �摜Ұٗp�ꎞ�e�[�u���̑|��
# @update	2008/12/03 �f�ڏI���o�i�[�f�[�^�̍X�V
# @version  1.00
#******************************************************

use strict;
use Getopt::Long;
use Term::ANSIColor qw(:constants);
$Term::ANSIColor::AUTORESET = 1;

use JKZ::UsrWebDB;


use constant USAGEMSG   =>  <<USAGE;
Usage: controlHPTable [options] action1 action2 ...
Actions:
	updatebanner
	cleanimagedata
	cleanaccesslog

Options:
        --checkonly		only check data
        --verbose		verbose
USAGE

my ($CHECKONLY, $VERBOSE);
GetOptions (
    'checkonly'	=> \$CHECKONLY,
    'verbose'	=> \$VERBOSE,
);


my @actions;
die USAGEMSG unless  @actions = @ARGV;

my $method = {
	updatebanner	=> \&updateExpiredBannerFlag,
	cleanimagedata	=> \&cleanTempImageData,
	cleanaccesslog	=> \&cleanAccessLog,
};

my $dbh = JKZ::UsrWebDB::connect();
foreach (@actions) {
	chomp;
	$method->{$_}->($dbh);
}

$dbh->disconnect();


exit ();

#******************************************************
# @access	public
# @desc		�f�ڊ��Ԃ��I�������o�i�[�f�[�^�̃t���O���X�V
#******************************************************
sub updateExpiredBannerFlag {
	my $dbh = shift;
	my $sql = "UPDATE HP_management.tBannerDataM SET status_flag=4 WHERE (valid_date <= NOW() AND expire_date <= NOW()) AND status_flag=2;";
	my $rc = $dbh->do($sql);
	#my $rows = $dbh->rows;

	unless ('0E0' eq $rc) {
		print "Error while Execution\n";
		print "abroated \n";
	}
	else {
		print " ==== SQL EXEQUTE: ==== \n", YELLOW $sql, "\n" if $VERBOSE;
	}

}


#******************************************************
# @access	public
# @desc		�摜�t���[���̊��ǃ��R�[�h��24���ԑO�̃��R�[�h�폜
#******************************************************
sub cleanTempImageData {
my $dbh = shift;
	my $sql = "DELETE FROM tTempImageF WHERE registration_date > DATE_SUB(registration_date, INTERVAL 24 HOUR)"
			. " AND message_id IN (SELECT message_id FROM tMessageInBoxF WHERE image_flag=2 AND status_flag IS NOT NULL)"
			;
	print "  ==== SQL Execute: ==== \n",YELLOW  $sql,"\n" if $VERBOSE
}


#******************************************************
# @access	public
# @desc		3�����O�̗F�B�̃A�N�Z�X���O������
# @param	$WhereStr = ���o���� column, wherestr, orderbystr, limitstr
#******************************************************
sub cleanAccessLog {
	my $dbh = shift;

#my @tables = ('tFriendAccessLogF', 'tLoginLogF', 'tAccessLogF',);
	my @base_tables = ('tFriendAccessLogF',);
	my $connecter = '_';
	my $sql;
	## 3�����O�̌����擾
	$sql = "SELECT DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 3 MONTH), '%m');";
	#my $dbh = JKZ::UsrWebDB::connect ();
	my $month = $dbh->selectrow_array ($sql);
	if ($month) {
    	foreach (@base_tables) {
	print WHITE "\n Going to Flush Tables \n" if $VERBOSE;
        	$dbh->do ("FLUSH TABLES");
	print WHITE "  Done with Flushing Tables \n" if $VERBOSE;
    	    my $table = $_ . $connecter . $month;
	print WHITE "  Going to Truncate Table : $table \n" if $VERBOSE;
    	    $sql = "TRUNCATE TABLE " . $table;
   	print "  ==== SQL Execute: ==== \n", YELLOW $sql,"\n" if $VERBOSE;
	        my $rc = $dbh->do ($sql);
    	    if ($rc eq '0E0') {
       	    print "\n ---------------------------\n", " [ $table ] has been not been TRUNCATED ", "\n ---------------------------\n";
	        }
    	}
	}
}
