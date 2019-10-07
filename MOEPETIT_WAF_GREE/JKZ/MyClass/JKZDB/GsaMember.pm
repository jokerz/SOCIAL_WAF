#******************************************************
# @desc      
#            
# @package    MyClass::JKZDB::GsaMember
# @access    public
# @author    Iwahase Ryo AUTO CREATE BY ./createClassDB
# @create    Fri Feb  4 17:44:08 2011
# @version    1.30
# @update    2008/05/30 executeUpdate処理の戻り値部分
# @update    2008/03/31 JKZ::DB::JKZDBのサブクラス化
# @update    2009/02/02 ディレクトリ構成をJKZ::JKZDBに変更
# @update    2009/02/12 リスティング処理を追加
# @update    2009/09/28 executeUpdateメソッドの処理変更
# @version   1.10
# @version   1.20
# @version   1.30
#******************************************************
package MyClass::JKZDB::GsaMember;

use 5.008005;
use strict;
our $VERSION ='1.30';

use base qw(MyClass::JKZDB);


#******************************************************
# @access    public
# @desc      コンストラクタ
# @param     
# @return    
# @author    
#******************************************************
sub new {
    my ($class, $dbh) = @_;
    my $table = 'dMOEPETIT.tGsaMemberM';
    return $class->SUPER::new($dbh, $table);
}


#******************************************************
# @access    
# @desc        SQLを実行します。
# @param    $sql
#            @placeholder
# @return    
#******************************************************
sub executeQuery {
    my ($self, $sqlMoji, $placeholder) = @_;

    my ($package, $filename, $line, $subroutine) = caller(1);

    if ($subroutine =~ /executeSelectList/) {
        my $aryref = $self->{this_dbh}->selectall_arrayref($sqlMoji, undef, @$placeholder);

        $self->{reccnt} = $#{$aryref};
        for (my $i = 0; $i <= $self->{reccnt}; $i++) {
#************************ AUTO GENERATED BEGIN ************************
$self->{columnslist}->{gree_user_id}->[$i] = $aryref->[$i]->[0];
$self->{columnslist}->{status_flag}->[$i] = $aryref->[$i]->[1];
$self->{columnslist}->{user_hash}->[$i] = $aryref->[$i]->[2];
$self->{columnslist}->{carrier}->[$i] = $aryref->[$i]->[3];
$self->{columnslist}->{invite_from_id}->[$i] = $aryref->[$i]->[4];
#************************ AUTO  GENERATED  END ************************
        }
    }
    elsif ($subroutine =~ /executeSelect$/) {
        my $sth = $self->{this_dbh}->prepare($sqlMoji);
        my $row = $sth->execute(@$placeholder);
        if (0==$row || !defined($row)) {
            return 0;
        } else {
#************************ AUTO GENERATED BEGIN ************************
            (
$self->{columns}->{gree_user_id},
$self->{columns}->{status_flag},
$self->{columns}->{user_hash},
$self->{columns}->{carrier},
$self->{columns}->{invite_from_id}
            ) = $sth->fetchrow_array();
#************************ AUTO  GENERATED  END ************************
        }
        $sth->finish();
    } else {
        my $rc = $self->{this_dbh}->do($sqlMoji, undef, @$placeholder);
        return $rc;
    }
}


#******************************************************
# @access    public
# @desc        レコード更新処理
#            プライマリキー条件によってINSERTないしはUPDATEの処理を行ないます。
# @param    
# @return    
#******************************************************
sub executeUpdate {
    my ($self, $param, $flag) = @_;

    my $sqlMoji;
    #******************************************************
    # TYPE    : arrayreference
    #            [
    #             [ columns name array],        0
    #             [ placeholder array ],        1
    #             [ values array      ],        2
    #            ]
    #******************************************************
    my $sqlref;
    my $rv;

    if ($self->{this_dbh} == "") {
        #エラー処理
    }

    $self->{columns}->{gree_user_id} = $param->{gree_user_id};

    ## ここでPrimaryKeyが設定されている場合はUpdate
    ## 設定がない場合はInsert
    #if ($self->{columns}->{gree_user_id} < 0) {}
    if ($flag < 0) {
        ##1. AutoIncrementでない場合はここで最大値を取得
        ##2. 挿入 

        #************************ AUTO GENERATED COLUMNS AND PLACEHOLDERS HAS BENN COMBINED BEGIN ************************
        push( @{ $sqlref->[0] }, "gree_user_id" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{gree_user_id} ) if $param->{gree_user_id} != "";
        push( @{ $sqlref->[0] }, "status_flag" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{status_flag} ) if $param->{status_flag} != "";
        push( @{ $sqlref->[0] }, "user_hash" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{user_hash} ) if $param->{user_hash} ne "";
        push( @{ $sqlref->[0] }, "carrier" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{carrier} ) if $param->{carrier} != "";
        push( @{ $sqlref->[0] }, "invite_from_id" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{invite_from_id} ) if $param->{invite_from_id} != "";

        #************************ AUTO GENERATED COLUMNS AND PLACEHOLDERS HAS BENN COMBINED   END ************************

        $sqlMoji = sprintf("INSERT INTO %s (%s) VALUES (%s);", $self->{table}, join(',', @{ $sqlref->[0] }), join(',', @{ $sqlref->[1] }));
        $rv = $self->executeQuery($sqlMoji, $sqlref->[2]);

        return $rv; # return value

    } else {

        map { exists ($self->{columns}->{$_}) ? push (@{ $sqlref->[0] }, $_) && push (@{ $sqlref->[1] }, $param->{$_}) : ""} keys %$param;
        $sqlMoji = sprintf("UPDATE $self->{table} SET %s =?  WHERE gree_user_id= '$self->{columns}->{gree_user_id}';", join('=?,', @{ $sqlref->[0] }));
        $rv = $self->executeQuery($sqlMoji, $sqlref->[1]);

        return $rv; # return value

    }
}


#******************************************************
# @desc     アプリ登録ユーザーIDの削除
# @param    
# @param    
# @return   
#******************************************************
sub removeGreeUser {
    my ($self, $gree_user_id) = @_;

    return if @{$gree_user_id} < 0;

    my $sqlMoji = sprintf("DELETE FROM %s WHERE gree_user_id IN(%s)", $self->table, @{$gree_user_id});
    my $rv      = $self->dbh->do($sqlMoji);
    return $rv;
}


#******************************************************
# @desc     アプリ登録ユーザー利用開始チェック
#           status_flagが１かどうか
# @param    gree_user_id
# @param    
# @return   boolean ステータスが１のばあいは1を返す
#******************************************************
sub chechGreeUserStatus {
    my ($self, $gree_user_id) = @_;
    return if !$gree_user_id;

    my $sqlMoji = sprintf("SELECT 1 FROM %s WHERE gree_user_id=? AND status_flag=1;", $self->table);
    my $rv      = $self->dbh->selectrow_array($sqlMoji, undef, $gree_user_id);

    return $rv
}


#******************************************************
# @desc     アプリ登録ユーザー利用開始チェック
#           status_flagが１の場合は２に更新して利用開始済みにする
# @param    
# @param    
# @return   
#******************************************************
sub startGreeUserStatus {
    my ($self, $gree_user_id) = @_;
    return if !$gree_user_id;

    my $sqlMoji = sprintf(" UPDATE %s
 SET status_flag = CASE WHEN status_flag=1
                            THEN 2
                        ELSE status_flag END
 WHERE gree_user_id=?;", $self->{table});

    my $rc      = $self->dbh->do($sqlMoji, undef, $gree_user_id);
    return $rc;
}


1;

