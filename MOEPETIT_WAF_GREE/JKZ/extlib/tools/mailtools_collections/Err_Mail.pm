package Err_Mail;
### #/usr/bin/perl -w

use strict;
#use DBI;

use lib qw(/home/ryo/WebDB);
use UsrWebDB;

#########################
#  �����ȼ���
#########################
my $SITE_common=0;
my $SITE_kensho=1;
my $SITE_melo=2;

#########################
#  �������
#########################
my $MEMSTS_nomem = -1;	#����
my $MEMSTS_tempmem = 0;	#�����
my $MEMSTS_member = 1;	#���
my $MEMSTS_leave = 9;	#���

#########################
#  ����ꥢ����
#########################
my $TERM_docomo = 1;
my $TERM_jphone = 2;
my $TERM_astel = 3;
my $TERM_h		= 4;
my $TERM_ezweb = 5;
my $TERM_other = 0;
my $TERM_common = 9;

#########################
#  �᡼�����
#########################
my $Mail_kind_regok=1;		#�����Ͽ��λ�᡼������
my $Mail_kind_regng=2;		#�����Ͽ���ԥ᡼������
my $Mail_kind_temp=3;		#����Ͽ��λ�᡼������
#// my $Mail_kind_apply=3;		#�ѥ�����䤤��碌�ֿ��᡼������
my $Mail_kind_memid=4;		#���ID�䤤��碌�ֿ��᡼������
my $Mail_kind_vote=5;		#��ɼ���մ�λ�᡼������
my $Mail_kind_intro=6;		#ͧã�Ҳ����Υ᡼��(ͧã¦������
my $Mail_kind_login=7;		#ͧã�Ҳ���������Υ᡼������
my $Mail_kind_win=8;		#���������Υ᡼������
my $Mail_kind_chkwin=9;	#�����Գ�ǧ�᡼������
#// my $Mail_kind_chkpwd=10;	#�ѥ�����ѹ����Υ᡼������
my $Mail_kind_chgml=11;	#�᡼�륢�ɥ쥹�ѹ����Υ᡼������
my $Mail_kind_adml=12;		#����᡼������
my $Mail_kind_point=13;	#�ݥ���ȥץ쥼��ȥ᡼������
my $Mail_kind_voteurl=14;	#��ɼURL���Υ᡼������
my $Mail_kind_voteurlng=15;	#��ɼURL�����Բĥ᡼������
my $Mail_kind_scratch=16;	#������å���������������Υ᡼������
my $Mail_kind_chkscr=17;	#������å�����������Գ�ǧ�᡼������
my $Mail_kind_memidng=18;	#�ѥ�����䤤��碌�ֿ��Բĥ᡼������
my $Mail_kind_win2=19;		#���������Υ᡼������(2��)
my $Mail_kind_chkwin2=20;	#�����Գ�ǧ�᡼������(2��)
my $Mail_kind_win3=21;		#���������Υ᡼������(3��)
my $Mail_kind_chkwin3=22;	#�����Գ�ǧ�᡼������(3��)
my $Mail_kind_qregok=23;	#�������Ѳ����Ͽ��λ�᡼������
my $Mail_kind_qregng=24;	#�������Ѳ����Ͽ���ԥ᡼������
my $Mail_kind_qwin=25;		#�����������������Υ᡼������
my $Mail_kind_qchkwin=26;	#�������������Գ�ǧ�᡼������
my $Mail_kind_qlose=27;		#�����������������Υ᡼������
my $Mail_kind_pctotel=28;	#PC������Ӥؤ�URL�����᡼������
my $Mail_kind_max=28;

###############################################
# �᡼���������顼
#	input:
#		mailaddress : �᡼�륨�顼�Ȥ���᡼�륢�ɥ쥹
#		mailinfo  : �᡼���ۿ�����
#		serverkind: �����С�����
#
#	output :
#		 1 : ���ｪλ
#		 0 : ���顼
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
	# DB�򥪡��ץ�
	#############################

	# �᡼�륵���С���
	if($serverkind == 1) {
		unless($db=DBI->connect("DBI:mysql:mail;host=kensho-ML1;port=3306","mysql","mysql",
								 {RaiseError => 0, PrintError => 1})){
			sleep 1;
		}
	}
	# �᡼�륵���С���
	elsif($serverkind == 2) {
		unless($db=DBI->connect("DBI:mysql:mail;host=kensho-ML2;port=3306","mysql","mysql",
								 {RaiseError => 0, PrintError => 1})){
			sleep 1;
		}
	}
	# �᡼�륵���С���
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
	# �᡼�륵���С���
	elsif($serverkind == 5) {
		unless($db=DBI->connect("DBI:mysql:mail;host=kensho-ML5;port=3306","mysql","mysql",
								 {RaiseError => 0, PrintError => 1})){
			sleep 1;
		}
	}
	# �᡼�륵���С�6
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
	# �᡼��إå������������
	#############################
	if($mailinfo ne ""){
		### �����ȼ���;�᡼�����;�᡼���ֹ�
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
	# �᡼�륨�顼����򹹿�
	#############################
	eval{
		$db->do("SET AUTOCOMMIT=0") || die "�ȥ�󥶥�����󳫻ϼ���\n";
		$db->do("BEGIN") || die "�ȥ�󥶥�����󳫻ϼ���\n";

		#�᡼�륨�顼����ι���
		$db->do("INSERT INTO errmail(mailkind, mailno, class, serialno, mailaddress, sitekind, errdate) 
		         VALUES($mailkind, $mailno, $class, $serialno, '$mailaddress', $sitekind, NOW());") ||  die "Error\n";
	};

	if ($@) {
	    # �⤷��DBI��RaiseError��die�����顢$@ �ˤ�$DBI::errstr�����äƤ��ޤ���
		# ��Ͽ����
		$db->do("ROLLBACK");
	}
	else {
		$db->do("COMMIT");
		$ret=1;
	}
	$db->do("SET AUTOCOMMIT=0") || die "�ȥ�󥶥�����󳫻ϼ���\n";
	$db->disconnect;
	undef($db);
	return $ret;
}1;
