#******************************************************
# @desc     アクセスログ・ページログデータベースにデータを格納する
# @package  MyClass::JKZGsaLogger
# @access   public
# @author   Iwahase Ryo
# @create   2010/01/12
# @update   2010/01/26 saveAccessLog savePageViewLogを追加
# @update   2010/10/26 ページビューをとるときにtmplt_nameに変更(もともとはtmplt_id)
# @update   2010/10/26 コンテンツログ追加
#
# @update   2011/04/09 グリーサイト用に中身を変更。軽量化のため不要なhashをなくし、ログインログだけをとる
# @version  1.00
#******************************************************
package MyClass::JKZGsaLogger;

use 5.008005;
our $VERSION = '1.00';

use strict;

use MyClass::WebUtil;
use MyClass::UsrWebDB;
use MyClass::JKZDB::LoginLog;


#******************************************************
# @access   public
# @desc     コンストラクタ
# @param    obj owid carrier, guid, acd,  tmplt_name contents_id contents_name
#******************************************************
sub new {
    my $class = shift;
    my $hash  = shift if @_;
    my $self  = {};
    my $dbh   = MyClass::UsrWebDB::connect();
    $self = {
        dbh           => $dbh,
        gree_user_id  => undef,
    };

    bless($self, $class);

    $self->{gree_user_id}          = $hash->{gree_user_id};
#    $self->_initialize();

    return($self);
}


#******************************************************
# @access    private
# @desc        
#******************************************************
=pod
sub _initialize {
    my $self = shift;

    my $remoteinfo      = MyClass::WebUtil::getIP_Host();
    $self->{ip}         = $remoteinfo->{ip};
    $self->{host}       = $remoteinfo->{host};
    $self->{useragent}  = $remoteinfo->{agent};
    $self->{referer}    = $remoteinfo->{referer};

    return $self;
}
=cut

#******************************************************
# @access    
# @desc        会員ログインログをとります。
# @param    
# @return    ログのインサートに失敗しても続行
#******************************************************
sub saveLoginLog {
    my $self = shift;

    my $insertData  = {
        gree_user_id => $self->{gree_user_id},
    };

    my $dbh = $self->{dbh};
    my $myLoginLog = MyClass::JKZDB::LoginLog->new($dbh);
    # tablename_yyyymmの場合は下記
    $myLoginLog->switchMRG_MyISAMTableSQL( { separater => '_', value => MyClass::WebUtil::GetTime("5") } );
    # tablename_mmの場合は下記
    #$myLoginLog->switchDataBaseSQL(MyClass::WebUtil::GetTime("11"));
    $myLoginLog->executeUpdate($insertData);

}

#******************************************************
# @access    
# @desc        最終処理を実施
# @desc        データベース切断
# @param    
# @return    
#******************************************************
sub closeLogger {
    my $self = shift;
    $self->{dbh}->disconnect();
}


1;

__END__
