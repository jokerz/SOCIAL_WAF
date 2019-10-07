#******************************************************
# @desc      
#            
# @package    MyClass::JKZDB::GsaUserFlashGameLog
# @access    public
# @author    Iwahase Ryo AUTO CREATE BY ./createClassDB
# @create    Thu Mar 31 16:51:22 2011
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
package MyClass::JKZDB::GsaUserFlashGameLog;

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
    my $table = 'dMOEPETIT.tGsaUserFlashGameLogF';
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
$self->{columnslist}->{contentsm_id}->[$i] = $aryref->[$i]->[1];
$self->{columnslist}->{categorym_id}->[$i] = $aryref->[$i]->[2];
$self->{columnslist}->{result_flag}->[$i] = $aryref->[$i]->[3];
$self->{columnslist}->{record_time}->[$i] = $aryref->[$i]->[4];
$self->{columnslist}->{gree_user_nickname}->[$i] = $aryref->[$i]->[5];
$self->{columnslist}->{contents_name}->[$i] = $aryref->[$i]->[6];
$self->{columnslist}->{registration_date}->[$i] = $aryref->[$i]->[7];
$self->{columnslist}->{lastupdate_date}->[$i] = $aryref->[$i]->[8];
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
$self->{columns}->{contentsm_id},
$self->{columns}->{categorym_id},
$self->{columns}->{result_flag},
$self->{columns}->{record_time},
$self->{columns}->{gree_user_nickname},
$self->{columns}->{contents_name},
$self->{columns}->{registration_date},
$self->{columns}->{lastupdate_date}
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
    $self->{columns}->{contentsm_id} = $param->{contentsm_id};
    $self->{columns}->{categorym_id} = $param->{categorym_id};

    ## ここでPrimaryKeyが設定されている場合はUpdate
    ## 設定がない場合はInsert
    #if ($self->{columns}->{categorym_id} < 0) {
        ##1. AutoIncrementでない場合はここで最大値を取得
        ##2. 挿入 
    if ( 0 > $flag ) {
        #************************ AUTO GENERATED COLUMNS AND PLACEHOLDERS HAS BENN COMBINED BEGIN ************************
        push( @{ $sqlref->[0] }, "gree_user_id" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{gree_user_id} ) if $param->{gree_user_id} != "";
        push( @{ $sqlref->[0] }, "contentsm_id" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{contentsm_id} ) if $param->{contentsm_id} != "";
        push( @{ $sqlref->[0] }, "categorym_id" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{categorym_id} ) if $param->{categorym_id} != "";
        push( @{ $sqlref->[0] }, "result_flag" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{result_flag} ) if $param->{result_flag} != "";
        push( @{ $sqlref->[0] }, "record_time" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{record_time} ) if $param->{record_time} ne "";
        push( @{ $sqlref->[0] }, "gree_user_nickname" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{gree_user_nickname} ) if $param->{gree_user_nickname} ne "";
        push( @{ $sqlref->[0] }, "contents_name" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{contents_name} ) if $param->{contents_name} ne "";
        push( @{ $sqlref->[0] }, "registration_date" ), push( @{ $sqlref->[1] }, "NOW()" );#, push( @{ $sqlref->[2] }, $param->{registration_date} ) if $param->{registration_date} ne "";
     #   push( @{ $sqlref->[0] }, "lastupdate_date" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{lastupdate_date} ) if $param->{lastupdate_date} ne "";

        #************************ AUTO GENERATED COLUMNS AND PLACEHOLDERS HAS BENN COMBINED   END ************************

        $sqlMoji = sprintf("INSERT INTO %s (%s) VALUES (%s);", $self->{table}, join(',', @{ $sqlref->[0] }), join(',', @{ $sqlref->[1] }));
        $rv = $self->executeQuery($sqlMoji, $sqlref->[2]);

        return $rv; # return value

    } else {

        map { exists ($self->{columns}->{$_}) ? push (@{ $sqlref->[0] }, $_) && push (@{ $sqlref->[1] }, $param->{$_}) : ""} keys %$param;
        $sqlMoji = sprintf("UPDATE $self->{table} SET %s =?  WHERE gree_user_id= '$self->{columns}->{gree_user_id}' AND contentsm_id= '$self->{columns}->{contentsm_id}' AND categorym_id= '$self->{columns}->{categorym_id}';", join('=?,', @{ $sqlref->[0] }));
        $rv = $self->executeQuery($sqlMoji, $sqlref->[1]);

        return $rv; # return value

    }
}


#******************************************************
# @desc     result_flagの確認(ゲーム挑戦履歴)
# @param    hashobj  { gree_user_id, contentsm_id, categorym_id }
# @return   1 2 undef
#******************************************************
sub checkResultFlag {
    my ($self, $param) = @_;
    return if ( !exists( $param->{gree_user_id} ) || !exists( $param->{contentsm_id} ) || !exists( $param->{categorym_id} ) );

    my $sqlMoji = sprintf("SELECT result_flag FROM %s WHERE gree_user_id=? AND contentsm_id=? AND categorym_id=?", $self->table);
    my $rv      = $self->dbh->selectrow_array($sqlMoji, undef, $param->{gree_user_id}, $param->{contentsm_id}, $param->{categorym_id});

    return $rv;
}


#******************************************************
# @desc     ゲーム挑戦履歴の更新
# @param    hashobj  { gree_user_id, contentsm_id, categorym_id, result_flag, record_time }
# @return   0E0 == 更新なし
#******************************************************
sub updateUserFlashGameLog {
    my ($self, $param) = @_;
    return if !$param;

    my $sqlMoji = sprintf("UPDATE %s SET result_flag=pow(2, ?), record_time=?  WHERE gree_user_id=? AND contentsm_id=? AND categorym_id=?;", $self->table);
    my $rc      = $self->dbh->do($sqlMoji, undef, $param->{result_flag}, $param->{record_time}, $param->{gree_user_id}, $param->{contentsm_id}, $param->{categorym_id});

    return $rc;
}


#******************************************************
# @desc     ユーザーがゲットした画像総数取得
# @param    gree_user_id
# @param    
# @return   int (total images)
#******************************************************
sub getUserGetImageTotal {
    my $self = shift;
    unless (@_) {
        ## 引数がない場合はエラー
        return;
    }
    my $gree_user_id    = shift;
    my $sqlMoji         = sprintf("SELECT COUNT(gree_user_id) AS my_getimage_total FROM %s WHERE gree_user_id=? AND result_flag=2;", $self->table);
    my $rv              = $self->dbh->selectrow_array($sqlMoji, undef, $gree_user_id);

    return $rv;
}


#******************************************************
# @desc     ユーザーの取得画像
# @param    { gree_user_id, limtSQL, orderbySQL }
# @param    
# @return   array
#******************************************************
sub getUserGetImages {
    my $self = shift;
    unless (@_) {
        return;
    }
    my $param = shift;

    my $orderBySQL  = exists($param->{orderbySQL}) ? sprintf("ORDER BY %s", $param->{orderbySQL}) : "";
    my $limitSQL    = exists($param->{limitSQL})   ? sprintf("limit %s", $param->{limitSQL}) : "";

    my $sqlMoji = sprintf("SELECT CONCAT(contentsm_id, ':', categorym_id) AS character_id FROM %s WHERE gree_user_id=? AND result_flag=2 %s %s", $self->table, $orderBySQL, $limitSQL);
    my $aryref  = $self->dbh->selectall_arrayref($sqlMoji, { Slice => {} }, $param->{gree_user_id});
    my @ret;
    map { push @ret, $aryref->[$_]->{character_id} } 0..$#{ $aryref };

    return (@ret);
}


#******************************************************
# @desc     ゲーム挑戦回数だけの更新
# @param    hashobj  { gree_user_id, contentsm_id, categorym_id }
# @return   0E0 == 更新なし
#******************************************************
=pod
sub updateGameCount {
    my ($self, $param) = @_;
    return if !$param;

    my $sqlMoji = sprintf("UPDATE %s SET game_count=game_count+1 WHERE owid=? AND contentsm_id=? AND categorym_id=?;", $self->table);
    my $rc      = $self->dbh->do($sqlMoji, undef, $param->{gree_user_id}, $param->{contentsm_id}, $param->{categorym_id});

    return $rc;
}
=cut


1;

