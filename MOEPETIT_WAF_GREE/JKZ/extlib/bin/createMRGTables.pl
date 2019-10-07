#!/usr/bin/perl -I /home/vhosts/MOEPETIT/JKZ

#******************************************************
# @desc     マージテーブルの生成
#           1年で12テーブルと仮想テーブル1つ
#           tXxyyyF_01からtXxyyyF_12 とtXxyyyFの計13個生成
#            --------------------------------
#   tAccessLogF 
#   tPageViewLogF
#   tBannerClickF
#   tBannerCountF
#   tLoginLogF
#
#        perl createMRGTables.pl
#
#
# @package  createMRGTables.pl
# @access   public
# @author   Iwahase Ryo
# @create   2009/12/15
# @update   2010/10/26
# @version  1.00
#******************************************************

use strict;
#use MyClass::WebUtil;
use MyClass::UsrWebDB;


#*************************
# 生成するテーブルの構造配列
# $tableConditions->[$integre]-{table}
# $tableConditions->[$integre]-{columns}
#*************************
=pod
    {
        table    => 'tBannerClickF',
        columns => "
 (
  `owid` int(10) unsigned NOT NULL default '0',
  `bannerm_id` int(10) unsigned NOT NULL COMMENT 'tBannerM.id',
  `bannerdatam_id` int(10) unsigned NOT NULL COMMENT 'tBannerDataM.id',
  `point_click` date NOT NULL default '0000-00-00',
  `click` int(11) unsigned NOT NULL default '0',
  `last_click` datetime NOT NULL default '0000-00-00 00:00:00',
  PRIMARY KEY  (`owid`,`bannerm_id`,`bannerdatam_id`,`point_click`),
  KEY `click` (`click`)
 )
",
    },
    {
        table    => 'tBannerCountF',
        columns => " 
 (
  `bannerm_id` int(10) unsigned NOT NULL COMMENT 'tBannerM.id',
  `bannerdatam_id` int(10) unsigned NOT NULL COMMENT 'tBannerDataM.id',
  `bannerdataf_id` int(10) unsigned NOT NULL COMMENT 'tBannerdataF.id',
  `clickdate` date NOT NULL default '0000-00-00' COMMENT 'クリック日',
  `click` int(11) unsigned NOT NULL default '0' COMMENT 'クリック数',
  `impression` int(11) unsigned NOT NULL default '0' COMMENT 'インプレッション集',
  `last_click` datetime NOT NULL default '0000-00-00 00:00:00' COMMENT '最終クリック時間',
  `last_impression` datetime NOT NULL default '0000-00-00 00:00:00' COMMENT '最終インプレッション',
  PRIMARY KEY  (`bannerm_id`,`bannerdatam_id`,`bannerdataf_id`,`clickdate`),
  KEY `date` (`clickdate`)
 )
",
    },
=cut
my $tableConditions = [
    {
        table    => 'tAccessLogF',
        columns => "
 (
 `id` int(11) unsigned NOT NULL auto_increment,
 `in_datetime` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
 `acd` char(6) NOT NULL default '',
 `carrier` tinyint(3) unsigned NOT NULL,
 `guid` char(30),
 `ip` char(15) NOT NULL default '',
 `host` char(100) default NULL,
 `useragent` char(100) NOT NULL default '',
 `referer` char(100) default NULL,
 PRIMARY KEY  (`id`),
 KEY `in_datetime` (`in_datetime`),
 KEY `acd` (`acd`)
 )
",
    },
    {
        table    => 'tPageViewLogF',
        columns => " 
 (
 `in_date` DATE NOT NULL COMMENT '日付 yyyy-mm',
 `in_time` char(2) COMMENT '時間 HH 0-23',
 `carrier` tinyint(1) unsigned NOT NULL,
 `tmplt_name` char(30) NOT NULL,
 `pvcount` int(10) unsigned default '0',
 `last_pv` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
 PRIMARY KEY  (`in_date`,`in_time`, `carrier`, `tmplt_name`)
 )
",
    },
    {
        table    => 'tLoginLogF',
        columns => " 
 (
  `gree_user_id` int(11) unsigned NOT NULL,
  `in_datehour` char(10) NOT NULL COMMENT '2010年11月5日16時は-> 2010110516としてあらわす',
  `last_login_datetime` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  PRIMARY KEY  (`gree_user_id`, `in_datehour`)
 )
",
    },
];

my @errmsg;
## 実行したSQL文
my @msg;

my %engine = (
    isam => ' ENGINE=MyISAM',
    mrg  => ' ENGINE=MRG_MyISAM',
);
#my $charset = ' DEFAULT CHARSET=sjis';

my $dbh = MyClass::UsrWebDB::connect();

#*************************
# HP_logdateにスイッチ
#*************************
$dbh->do('USE dMOEPETIT_LOG');
#$dbh->do('SET NAMES SJIS');

#*************************
# 12ヶ月のテーブルを作成 1グループごとに実行
#*************************
foreach my $table (@{$tableConditions}) {
    my (@tablenames, @tablestocreate);
    #*************************
    # 12ヶ月分のCREAT文を生成
    #*************************
    @tablestocreate = map {
        'CREATE TABLE IF NOT EXISTS ' . $table->{table} . sprintf("_%02d", $_+1)
        . $table->{columns}
        . $engine{isam}
        . $charset
        . ";"
    } (0..11);

    @tablenames = map { $table->{table} . sprintf("_%02d", $_+1) } (0..11);

    #*************************
    # マージを作成
    #*************************
    my $mrgsql = 'CREATE TABLE IF NOT EXISTS ' . $table->{table}
           . $table->{columns}
           . $engine{mrg}
           . $charset
           . ' INSERT_METHOD=LAST UNION=('
           . sprintf "%s", join (',', @tablenames)
           . ");"
           ;
    push (@tablestocreate, $mrgsql);

    #*******************************
    # ここで@tablestocreate配列のループ処理で
    # DBのcreateSQLを実行 
    #*******************************
    eval {
        map { $dbh->do($_); } @tablestocreate;
    };
    push @tablenames, $table->{table};
    push(@msg, @tablenames);

    push(@errmsg, $@) if $@;
}

$dbh->disconnect();

printf("TOTAL : %d TABLES HAS BEEN CREATED \n -- table lists below -- \n", $#msg);
print map { $_, "\n" } @msg;

print $#errmsg, "SQL FAIL \n" if 0 < $#errmsg;
print @errmsg;


exit();

