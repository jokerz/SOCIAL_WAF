#!/usr/bin/perl -w
# ������� -----------------------------------------------#
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
#  �᡼������Υ����ȥ�
#########################
my @Mail_Title =('����᡼������', 
				 '����������������Υ᡼������',
				 '������������������Υ᡼������');


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
# ���ϻ��������
#############################
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my $today = ($year+1900) . '/' . ($mon+1) . '/' . "$mday $hour:$min:$sec";

#############################
# �ѥ�᡼�������
#############################
my ($mailkind, $id) = @ARGV;
#############################
# �ǡ����١���̾���ơ��֥�̾�����
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
	#�����Բ�
	warn '�᡼����������(�᡼����̥��顼) ' . $Mail_Title[$mailkind-1] .
	  ": ID=$id : $today\n";
	exit;
}
warn '�᡼���������� ' . $Mail_Title[$mailkind-1] .
": ID=$id : $today : " . Time::HiRes::time . "\n";

#############################
# ��������ǡ����١����إ��ͥ���
#############################

$db = MyClass::UsrWebDB::connect();
$db->do('set names sjis');
if(!defined($db)){
	$errno=17;
	goto ERR_SOKET;
}
#############################
# �᡼�����Ƥ����
# ������������᡼�붦��
#############################
$sql = "select ifnull(carrier,0), ifnull(subject,''),
 ifnull(contents,'') from $look_ref->{'body'} where
 $look_ref->{'id_field'} = $id;";

$sth=$db->prepare($sql);
$row=$sth->execute;
if(!defined($row) || 0==$row){
	#��������
	warn '�᡼����������(�������ƾ���������顼) ' .
	  $Mail_Title[$mailkind-1] . ": ID=$id \n";
	$sth->finish;
	$db->disconnect;
	undef($db);
	$errno=11;
	goto ERR_SOKET;
}

#############################
# ���������������
# ������������᡼�붦��
#############################
$sql = "select ifnull(fromaddress,''), ifnull(server,''),
 ifnull(header,'') from $look_ref->{'setting'} where
 $look_ref->{'id_field'} = $id;";
$sths=$db->prepare($sql);
$row=$sths->execute;
if(!defined($row) || $row==0){
	#��������
	$sth->finish;
	$sths->finish;
	$db->disconnect;
	undef($db);
	warn '�᡼����������(�����������������顼) ' .
	  $Mail_Title[$mailkind-1] . ": ID=$id \n";
	$errno=12;
	goto ERR_SOKET;
}


#############################
# �᡼�����Ƥ����������
#############################
my ($crr, $subject, $contents);
$sth->bind_columns(\$crr, \$subject, \$contents);
while($sth->fetch){
	#��ʸ������
	$setsubject[$crr] = $subject;
	$setcontents[$crr] = $contents;
}
$sth->finish;

#���ͥ������򤭤�ʤ������SQLʸ���ꤲ��
$db->do("select now();");

#############################
# ���������������������
#############################
my ($readfrom, $readserver, $readheader);
$sths->bind_columns(\$readfrom, \$readserver, \$readheader);
while($sths->fetch){
	if($readfrom eq "" || $readserver eq "" ){
		#��������
		$sths->finish;
		$db->disconnect;
		undef($db);
		warn '�᡼����������(����������� ���ƥ��顼) ' .
		  $Mail_Title[$mailkind-1] . ": ID=$id Server=$readserver\n";
		$errno=13;
		goto ERR_SOKET;
	}
	# SMTP�ǥ����åȤ��Ԥͤ�
	my $sp;
	unless($sp = Net::SMTP->new($readserver, Debug => 1)){
		#��³�Ǥ��ʤ���С����Υ����С�����ϻȤ�ʤ�
		next;
	}
	#@mailsetting�ϥϥå���Υ�ե���󥹤�����
	push @mailsetting, {'smtp' => $sp,
						'from' => $readfrom,
						'server' => $readserver,
						'headerbase' => $readheader};
}
$sths->finish;

unless(defined $mailsetting[0]{'smtp'}){
	#SMTP��³��1�Ĥ�ͭ���ˤʤ�ʤ��ä�
	goto ERR_SOKET;
}

#############################
# �᡼�������
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
	#��������
	$sth->finish;
	$db->disconnect;
	undef($db);
	warn '�᡼����������(���������������顼) ' .
	  $Mail_Title[$mailkind-1] . ": ID=$id \n";
	$errno=14;
    goto ERR_SOKET;
}

warn $Mail_Title[$mailkind-1] . ": ID=$id " . ' �����롼�׳��� ' .
"($$) " . Time::HiRes::time . "\n";
# Modified 2010/02/01
#my ($userid, $password, $cryptpwd, $dstmail);
#$sth->bind_columns(\$userid, \$password, \$cryptpwd, \$crr, \$dstmail);
my ($userid, $dstmail);
$sth->bind_columns(\$userid, \$crr, \$dstmail);
#$send�ν���ͤ�1
my $sv; #@mailsetting��ź����
my $sendcnt = 0; #��������
while($sth->fetch){
	#ñ��˥饦��ɥ�ӥ�¸����뤿��ν���
	$sendcnt++;
	#���������򥵡��С��ο��ǳ�äơ����Τ��ޤ��ź�����˻Ȥ�
	$sv = $sendcnt % ($#mailsetting + 1);
# Modified 2010/02/01
	#if($userid eq "" || $password eq "" || $dstmail eq "" ||
	if($userid eq "" || $dstmail eq "" ||
	   ($setsubject[$crr] eq "" && $setcontents[$crr] eq "") ){
		#���ID���ѥ���ɡ��᡼�륢�ɥ쥹�Τ����줫����ʸ���ξ��
		#�⤷���Ϸ�̾����ʸ��ξ������ʸ���ξ���,���β���򥨥顼�ˤ���
		$send=0;
		goto SENDERR;
	}

	#��ʸ���ɤ߽Ф�
	$body=$setcontents[$crr];

	#ID�Ȏʎߎ��܎��Ďޤ��ִ�
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

	#�����ʷ�����ʸ�ˤ���
	# 2 == 2 ** 1; 8 == 2 **3
	#DoCoMo,AU�� Base64
	my $num_crr = (log $crr) / (log 2); #numeric carrier
	$body = Goku::StrConv::GetMailBody($body,$num_crr);

	#�����ʷ��Υإå����ˤ���
	$Header = Goku::StrConv::GetMailHeader(
		$setsubject[$crr], #Suject
		$mailsetting[$sv]{'from'}, #From
		$dstmail, #To
		$num_crr, #������numeric���ߤ���
		$mailsetting[$sv]{'headerbase'} #�ղåإå���
		);

    # MAIL���ޥ�ɤκ���������
	unless( $mailsetting[$sv]{'smtp'}->mail($mailsetting[$sv]{'from'}) ){
		$mailsetting[$sv]{'smtp'}->reset();
		$send = 0;
		goto SENDERR;
	}
	# RCPT TO:������
	unless($mailsetting[$sv]{'smtp'}->to("$dstmail") ){
		$mailsetting[$sv]{'smtp'}->reset();
		$send=0;
		goto SENDERR;
	}
	# DATA ���ޥ�ɤ�����
	unless($mailsetting[$sv]{'smtp'}->data() ){
		$mailsetting[$sv]{'smtp'}->reset();
		$send=0;
		goto SENDERR;
	}
	# Header������
	unless($mailsetting[$sv]{'smtp'}->datasend($Header) ){
		$mailsetting[$sv]{'smtp'}->reset();
		$send=0;
		goto SENDERR;
	}
	# body������
	unless($mailsetting[$sv]{'smtp'}->datasend($body."\n") ){
		$mailsetting[$sv]{'smtp'}->reset();
		$send=0;
		goto SENDERR;
	}
	# �ǡ��������������ޤ�
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
		#����ͤ��᤹
		$send=1;
	}
}

$db->disconnect;
undef($db);

warn $Mail_Title[$mailkind-1] . ": ID=$id " . ' �����롼�׽�λ ' .
"($$) " . Time::HiRes::time . "\n";

ERR_SOKET:
if($errno==0){
	# �᡼�����������Ԥ��Ƥ��������������å�
	if($#lostid>=0){
		#�����褢��
		warn $Mail_Title[$mailkind-1] . ": ID=$id " .
		  ' �����ե饰����' . "\n";

		$db = JKZ::UsrWebDB::connect ();
		$db->do('set names sjis');
		#�����ơ��֥���Ф��ơ��������ԥե饰��Ω�Ƥ�Τߡ�
		#memberɽ���Ф��ƤϽ������ʤ�
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
	#���顼��ȯ�������Τǡ���ȥ饤������
	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	warn '�᡼���������� (Error Code=' . $errno . ") " . $Mail_Title[$mailkind-1] . ": ID=$id : " . ($year+1900) . '/' . ($mon+1) . '/' . "$mday $hour:$min:$sec : " . Time::HiRes::time . "\n";
=pod
  #�����Ǥϡ���ȥ饤�����Ȥ��ơ��ƥ�ץ졼�ȥơ��֥��̾���ѹ����뤳�Ȥ�
  #���٥�ȥ饤�оݤȤʤ롣
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

### QUIT���ޥ�ɤ�����
foreach (@mailsetting) {
	$_->{'smtp'}->quit();
}

if($errno==0){
	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$today = ($year+1900) . '/' . ($mon+1) . '/' . "$mday $hour:$min:$sec";
	
	warn '�᡼��������λ ' . $Mail_Title[$mailkind-1] . ": ID=$id " .
	  ($year+1900) . '/' . ($mon+1) . '/' . "$mday $hour:$min:$sec : " .
		Time::HiRes::time . "\n";
}

exit;
