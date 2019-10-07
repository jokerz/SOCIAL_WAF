#!/usr/bin/perl -I /home/vhosts/JKZ

#******************************************************
# @desc     マージテーブルの生成
#           1年で12テーブルと仮想テーブル1つ
#			対象テーブル: tBannerClickF
#						  tBannerCountF
#			--------------------------------
#						ここから下はまだ対応していないテーブル
#						  tLoginLogF
#						  tFriendAccessLogF
#						  tAccessLogF
#						  tBannerClickF
#						  tBannerClickF
#
#		perl createMRGTables.pl 2008
#
# @ param	int	年 ない場合は現在の年に1年足した年で生成
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
# 生成するテーブルの構造配列
# $tableConditions->[$integre]-{table}
# $tableConditions->[$integre]-{columns}
#*************************
my $tableConditions = [
	{
		table=> 'tBannerClickF_',
		columns => " 
 (`owid` int(10) unsigned NOT NULL default '0' COMMENT '会員のowid',
`id1` int(10) unsigned NOT NULL,
`id2` int(10) unsigned NOT NULL,
`point_click` date NOT NULL default '0000-00-00' COMMENT 'ポイントが発生したクリック日',
`click` int(11) unsigned NOT NULL default '0',
`last_click` datetime NOT NULL default '0000-00-00 00:00:00' COMMENT '最終クリック日',
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
`clickdate` date NOT NULL default '0000-00-00' COMMENT 'クリック日',
`click` int(11) unsigned NOT NULL default '0' COMMENT 'クリック数',
`impression` int(11) unsigned NOT NULL default '0' COMMENT 'インプレッション集',
`last_click` datetime NOT NULL default '0000-00-00 00:00:00' COMMENT '最終クリック時間',
`last_impression` datetime NOT NULL default '0000-00-00 00:00:00' COMMENT '最終インプレッション',
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
`subno` char(20) default NULL COMMENT '携帯端末番号',
`host` char(100) default NULL COMMENT '何でログインしたか判別のためHOST情報も取得',
PRIMARY KEY  (`id`),
KEY `owid` (`owid`),
KEY `in_datetime` (`in_datetime`))
",
	},
	{
		table=> 'tFriendAccessLogF_',
		columns => " 
 (`my_owid` int(11) unsigned NOT NULL COMMENT 'HPのオーナーの会員owid',
`friend_owid` int(11) unsigned NOT NULL COMMENT 'HPにアクセスした会員のowid',
`date` tinyint(3) unsigned NOT NULL default '0' COMMENT 'アクセス日付',
`friend_id` char(20) NOT NULL COMMENT 'HOMEPAGのID',
`friend_nickname` char(40) NOT NULL,
`lastaccess_time` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
`firstaccess_time` time NOT NULL,
PRIMARY KEY  (`my_owid`,`friend_owid`,`date`))
",
	},
];


my @errmsg;
## 実行したSQL文
my @msg;
## 次年度のテーブルを生成する
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
# HP_logdateにスイッチ
#*************************
#$dbh->do('USE HP_logdata');
$dbh->do('USE test');
$dbh->do('SET NAMES SJIS');

#*************************
# 12ヶ月のテーブルを作成 1グループごとに実行
#*************************
foreach my $table (@{$tableConditions}) {
	my (@tablenames, @tablestocreate);
	#*************************
	# 12ヶ月分のCREAT文を生成
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
	# マージを作成
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
	# ここで@tablestocreate配列のループ処理で
	# DBのcreateSQLを実行 
	#*******************************
	foreach my $sql (@tablestocreate) {
		if (!$dbh->do($sql)) {
			push (@errmsg ,'SQL Failed : ' . $sql . "\n");
			last;
		}
		push (@msg ,'SQL Executed : ' . $sql . "\n");
=pod
		my $rc = $dbh->do($sql);
		# マージテーブルなので、失敗したら終了して脱出。次のグループを実行
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

