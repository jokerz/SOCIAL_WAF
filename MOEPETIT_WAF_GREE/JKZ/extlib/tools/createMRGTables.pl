#!/usr/bin/perl -I /home/vhosts/JKZ

#******************************************************
# @desc     �}�[�W�e�[�u���̐���
#           1�N��12�e�[�u���Ɖ��z�e�[�u��1��
#			�Ώۃe�[�u��: tBannerClickF
#						  tBannerCountF
#			--------------------------------
#						�������牺�͂܂��Ή����Ă��Ȃ��e�[�u��
#						  tLoginLogF
#						  tFriendAccessLogF
#						  tAccessLogF
#						  tBannerClickF
#						  tBannerClickF
#
#		perl createMRGTables.pl 2008
#
# @ param	int	�N �Ȃ��ꍇ�͌��݂̔N��1�N�������N�Ő���
#
# @package  createMRGTables.pl
# @access   public
# @author   Iwahase Ryo
# @create   2008/12/15
# @update	
# @version  1.00
#******************************************************

use strict;
use WebUtil;
use JKZ::UsrWebDB;


#*************************
# ��������e�[�u���̍\���z��
# $tableConditions->[$integre]-{table}
# $tableConditions->[$integre]-{columns}
#*************************
my $tableConditions = [
	{
		table=> 'tBannerClickF_',
		columns => " 
 (`owid` int(10) unsigned NOT NULL default '0' COMMENT '�����owid',
`id1` int(10) unsigned NOT NULL,
`id2` int(10) unsigned NOT NULL,
`point_click` date NOT NULL default '0000-00-00' COMMENT '�|�C���g�����������N���b�N��',
`click` int(11) unsigned NOT NULL default '0',
`last_click` datetime NOT NULL default '0000-00-00 00:00:00' COMMENT '�ŏI�N���b�N��',
PRIMARY KEY  (`owid`,`id1`,`id2`,`point_click`),
KEY `click` (`click`))
",
	},
	{
		table=> 'tBannerCountF_',
		columns => " 
 (`id1` int(10) unsigned NOT NULL COMMENT 'tBannerM.id',
`id2` int(10) unsigned NOT NULL COMMENT 'tBannerDataM.id',
`id3` int(10) unsigned NOT NULL,
`clickdate` date NOT NULL default '0000-00-00' COMMENT '�N���b�N��',
`click` int(11) unsigned NOT NULL default '0' COMMENT '�N���b�N��',
`impression` int(11) unsigned NOT NULL default '0' COMMENT '�C���v���b�V�����W',
`last_click` datetime NOT NULL default '0000-00-00 00:00:00' COMMENT '�ŏI�N���b�N����',
`last_impression` datetime NOT NULL default '0000-00-00 00:00:00' COMMENT '�ŏI�C���v���b�V����',
PRIMARY KEY  (`id1`,`id2`,`id3`,`clickdate`),
KEY `date` (`clickdate`))
",
	},
	{
		table=> 'tAccessLogF_',
		columns => " 
 (`id` int(11) unsigned NOT NULL auto_increment,
`in_datetime` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
`acd` char(6) NOT NULL default '',
`carrier` tinyint(3) unsigned NOT NULL,
`ip` char(15) NOT NULL default '',
`host` char(100) default NULL,
`useragent` char(100) NOT NULL default '',
`referer` char(100) default NULL,
PRIMARY KEY  (`id`),
KEY `in_datetime` (`in_datetime`),
KEY `acd` (`acd`))
",
	},
	{
		table=> 'tLoginLogF_',
		columns => " 
 (`id` int(11) unsigned NOT NULL auto_increment,
`owid` int(11) unsigned NOT NULL,
`in_datetime` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
`subno` char(20) default NULL COMMENT '�g�ђ[���ԍ�',
`host` char(100) default NULL COMMENT '���Ń��O�C�����������ʂ̂���HOST�����擾',
PRIMARY KEY  (`id`),
KEY `owid` (`owid`),
KEY `in_datetime` (`in_datetime`))
",
	},
	{
		table=> 'tFriendAccessLogF_',
		columns => " 
 (`my_owid` int(11) unsigned NOT NULL COMMENT 'HP�̃I�[�i�[�̉��owid',
`friend_owid` int(11) unsigned NOT NULL COMMENT 'HP�ɃA�N�Z�X���������owid',
`date` tinyint(3) unsigned NOT NULL default '0' COMMENT '�A�N�Z�X���t',
`friend_id` char(20) NOT NULL COMMENT 'HOMEPAG��ID',
`friend_nickname` char(40) NOT NULL,
`lastaccess_time` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
`firstaccess_time` time NOT NULL,
PRIMARY KEY  (`my_owid`,`friend_owid`,`date`))
",
	},
];


my @errmsg;
## ���s����SQL��
my @msg;
## ���N�x�̃e�[�u���𐶐�����
#my $baseyear = ($ARGV[0] =~ /\d\d\d\d/) ? chomp ($ARGV[0]) : WebUtil::GetTime (9);
my $baseyear = $ARGV[0] ? $ARGV[0] : WebUtil::GetTime (9);
$baseyear += 1;

my %engine = (
	isam => ' ENGINE=MyISAM',
	mrg  => ' ENGINE=MRG_MyISAM',
);
my $charset = ' DEFAULT CHARSET=sjis';

my $dbh = JKZ::UsrWebDB::connect();

#*************************
# HP_logdate�ɃX�C�b�`
#*************************
#$dbh->do('USE HP_logdata');
$dbh->do('USE test');
$dbh->do('SET NAMES SJIS');

#*************************
# 12�����̃e�[�u�����쐬 1�O���[�v���ƂɎ��s
#*************************
foreach my $table (@{$tableConditions}) {
	my (@tablenames, @tablestocreate);
	#*************************
	# 12��������CREAT���𐶐�
	#*************************
	foreach (0..11) {
		my $tableyyyymm = $table->{table} . $baseyear . sprintf "%02d", $_+1;
		my $createsql = 'CREATE TABLE IF NOT EXISTS ' . $tableyyyymm
				  . $table->{columns}
				  . $engine{isam}
				  . $charset
				  . ';'
				  ;
		push (@tablestocreate, $createsql);
		push (@tablenames, $tableyyyymm);
	}

	#*************************
	# �}�[�W���쐬
	#*************************
	my $mrgsql = 'CREATE TABLE IF NOT EXISTS ' . $table->{table} . $baseyear
		   . $table->{columns}
		   . $engine{mrg}
		   . $charset
		   . ' INSERT_METHOD=LAST UNION=('
		   . sprintf "%s", join (',', @tablenames)
		   . ');'
		   ;
	push (@tablestocreate, $mrgsql);

	#*******************************
	# ������@tablestocreate�z��̃��[�v������
	# DB��createSQL�����s 
	#*******************************
	foreach my $sql (@tablestocreate) {
		if (!$dbh->do($sql)) {
			push (@errmsg ,'SQL Failed : ' . $sql . "\n");
			last;
		}
		push (@msg ,'SQL Executed : ' . $sql . "\n");
=pod
		my $rc = $dbh->do($sql);
		# �}�[�W�e�[�u���Ȃ̂ŁA���s������I�����ĒE�o�B���̃O���[�v�����s
		push (@errmsg ,'SQL Failed : ' . $sql . "\n") && last if $rc eq '0E0';
		push (@msg ,'SQL Executed : ' . $sql . "\n");
=cut
	}
}

$dbh->disconnect();

print $#msg, "SQL SUCCESS \n";
print @msg;

print $#errmsg, "SQL FAIL \n";
print @errmsg;

=pod
if (1 < $errmsg[-1]) {
	print @tablestocreate,"\n\n","ALL tables success\n\n";
}
else { print @errmsg; }
=cut

exit ();

