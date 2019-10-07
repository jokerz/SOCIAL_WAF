#******************************************************
# @desc      
#            
# @package    MyClass::JKZDB::GsaUserStatus
# @access    public
# @author    Iwahase Ryo AUTO CREATE BY createClassDB
# @create    Sat Apr  9 22:30:22 2011
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
package MyClass::JKZDB::GsaUserStatus;

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
    my $table = 'dMOEPETIT.tGsaUserStatusM';
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
$self->{columnslist}->{my_gree_user_id}->[$i] = $aryref->[$i]->[0];
$self->{columnslist}->{my_power}->[$i] = $aryref->[$i]->[1];
$self->{columnslist}->{my_stopwatch_id}->[$i] = $aryref->[$i]->[2];
$self->{columnslist}->{my_stopwatch_name}->[$i] = $aryref->[$i]->[3];
$self->{columnslist}->{my_latest_flashgame_record_time}->[$i] = $aryref->[$i]->[4];
$self->{columnslist}->{my_getimage_total}->[$i] = $aryref->[$i]->[5];
$self->{columnslist}->{my_completecharacter_total}->[$i] = $aryref->[$i]->[6];
$self->{columnslist}->{my_tomemoeLv}->[$i] = $aryref->[$i]->[7];
$self->{columnslist}->{my_compmoeLv}->[$i] = $aryref->[$i]->[8];
$self->{columnslist}->{my_degree_id}->[$i] = $aryref->[$i]->[9];
$self->{columnslist}->{my_degree_name}->[$i] = $aryref->[$i]->[10];
$self->{columnslist}->{lastupdate_date}->[$i] = $aryref->[$i]->[11];
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
$self->{columns}->{my_gree_user_id},
$self->{columns}->{my_power},
$self->{columns}->{my_stopwatch_id},
$self->{columns}->{my_stopwatch_name},
$self->{columns}->{my_latest_flashgame_record_time},
$self->{columns}->{my_getimage_total},
$self->{columns}->{my_completecharacter_total},
$self->{columns}->{my_tomemoeLv},
$self->{columns}->{my_compmoeLv},
$self->{columns}->{my_degree_id},
$self->{columns}->{my_degree_name},
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

    ## ここでPrimaryKeyが設定されている場合はUpdate
    ## 設定がない場合はInsert
    #if ($self->{columns}->{gree_user_id} < 0) {
    if ($flag < 0) {
        ##1. AutoIncrementでない場合はここで最大値を取得
        ##2. 挿入 

        #************************ AUTO GENERATED COLUMNS AND PLACEHOLDERS HAS BENN COMBINED BEGIN ************************
        push( @{ $sqlref->[0] }, "gree_user_id" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{gree_user_id} ) if $param->{gree_user_id} != "";
        push( @{ $sqlref->[0] }, "my_power" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{my_power} ) if $param->{my_power} != "";
        push( @{ $sqlref->[0] }, "my_stopwatch_id" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{my_stopwatch_id} ) if $param->{my_stopwatch_id} != "";
        push( @{ $sqlref->[0] }, "my_stopwatch_name" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{my_stopwatch_name} ) if $param->{my_stopwatch_name} ne "";
        push( @{ $sqlref->[0] }, "my_latest_flashgame_record_time" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{my_latest_flashgame_record_time} ) if $param->{my_latest_flashgame_record_time} ne "";
        push( @{ $sqlref->[0] }, "my_getimage_total" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{my_getimage_total} ) if $param->{my_getimage_total} != "";
        push( @{ $sqlref->[0] }, "my_completecharacter_total" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{my_completecharacter_total} ) if $param->{my_completecharacter_total} != "";
        push( @{ $sqlref->[0] }, "my_tomemoeLv" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{my_tomemoeLv} ) if $param->{my_tomemoeLv} != "";
        push( @{ $sqlref->[0] }, "my_compmoeLv" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{my_compmoeLv} ) if $param->{my_compmoeLv} != "";
        push( @{ $sqlref->[0] }, "my_degree_id" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{my_degree_id} ) if $param->{my_degree_id} != "";
        push( @{ $sqlref->[0] }, "my_degree_name" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{my_degree_name} ) if $param->{my_degree_name} ne "";
        #push( @{ $sqlref->[0] }, "lastupdate_date" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{lastupdate_date} ) if $param->{lastupdate_date} ne "";

        #************************ AUTO GENERATED COLUMNS AND PLACEHOLDERS HAS BENN COMBINED   END ************************

        #$sqlMoji = sprintf("INSERT INTO %s (%s) VALUES (%s);", $self->{table}, join(',', @{ $sqlref->[0] }), join(',', @{ $sqlref->[1] }));
        $sqlMoji = sprintf("INSERT INTO %s (%s) VALUES (%s) ON DUPLICATE KEY UPDATE my_power='$param->{my_power}';", $self->{table}, join(',', @{ $sqlref->[0] }), join(',', @{ $sqlref->[1] }));
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
# @desc     所持パワーのチェック
# @param    gree_user_id
# @param    
# @return   所持パワー
#******************************************************
sub checkMyPower {
    my ($self, $gree_user_id) = @_;
    return if !$gree_user_id;

    my $sqlMoji = sprintf("SELECT my_power FROM %s WHERE gree_user_id=?;", $self->table);
    my $rv      = $self->dbh->selectrow_array($sqlMoji, undef, $gree_user_id);

    return $rv;
}


#******************************************************
# @desc     my_powerの更新
# @param    gree_user_id, power powerは値をそのままマイナスならマイナス値を渡す record_time
# @param    hashobj { gree_user_id, my_power, my_lastest_flashgame_record_time }
# @return   
#******************************************************
sub updatePowerAndRecordTime {
    my ($self, $param) = @_;
    return if !exists $param->{gree_user_id};

    my $sqlMoji = sprintf("UPDATE %s SET my_power=(my_power + (?)), my_latest_flashgame_record_time=? WHERE gree_user_id=?;", $self->table);
    my $rv      = $self->dbh->do($sqlMoji, undef, $param->{my_power}, $param->{my_lastest_flashgame_record_time}, $param->{gree_user_id});

    return $rv;
}


#******************************************************
# @desc     my_powerの更新 my_powerの上限を5.00に制限
# @param    hashobj { gree_user_id my_power }
# @return   
#******************************************************
sub updateMyPower {
    my ($self, $param) = @_;
    
    return if !exists($param->{gree_user_id}) || !exists($param->{my_power});

    #my $sqlMoji = sprintf("UPDATE %s SET my_power=(my_power + (?)) WHERE gree_user_id=?;", $self->table);
    #my $rv      = $self->dbh->do($sqlMoji, undef, $param->{my_power}, $param->{gree_user_id});

    my $sqlMoji = sprintf("UPDATE %s SET my_power = CASE WHEN (my_power + (?)) >= 5 THEN 5
 WHEN (my_power + (?)) < 5 THEN (my_power + (?))
 ELSE my_power END
 WHERE gree_user_id=?", $self->table);

    my $rv = $self->dbh->do($sqlMoji, undef, $param->{my_power}, $param->{my_power}, $param->{my_power}, $param->{gree_user_id});

    return $rv;
}


#******************************************************
# @desc     デフォルトSWに設定を変更する
# @param    int gree_user_id
# @param    
# @return   
#******************************************************
sub setDefaultStopWatch {
    my ($self, $gree_user_id) = @_;
    return if !$gree_user_id;

    my $sqlMoji = sprintf("UPDATE %s SET my_stopwatch_id=NULL, my_stopwatch_name=NULL WHERE gree_user_id=?;", $self->table);
    $self->executeQuery($sqlMoji, [$gree_user_id]);
}


1;
__END__
