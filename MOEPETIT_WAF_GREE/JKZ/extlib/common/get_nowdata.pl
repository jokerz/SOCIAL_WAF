########################################################
#		���t������ϊ��֐�
#
#     ���̓p�����[�^
#				DBI�n���h��
#     �o�̓p�����[�^
#               ���t�̕�����
#
######################################################
##### #/usr/bin/perl

use strict;
use DBI;

sub GetNowDateTime{
my $db;
my $sth;
my $rec;
my $date;
my $time;
my $today;

	($db) = @_;

	$sth=$db->prepare("SELECT CURDATE(), CURTIME();");
	$sth->execute;
	
	$rec=$sth->fetchrow_arrayref;
	$date=$rec->[0];
	$time=$rec->[1];
	
	$today=$date . " " . $time;
	
#	
#	#############################
#	# ���݂̎������擾
#	#############################
#	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
#	
#	#############################
#	# ���t�̌`���ɕϊ�
#	#############################
#	$year  = sprintf("%02d",$year + 1900);
#	$month = sprintf("%02d",$mon + 1);
#	$mday  = sprintf("%02d",$mday);
#	$hour  = sprintf("%02d",$hour);
#	$min   = sprintf("%02d",$min);
#	$sec   = sprintf("%02d",$sec);
#	$today = "$year/$month/$mday $hour:$min:$sec";
	return $today;
}1;

