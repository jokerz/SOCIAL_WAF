#******************************************************
# @desc      
#            
# @package    MyClass::JKZDB::GsaUserGachaLog
# @access    public
# @author    Iwahase Ryo AUTO CREATE BY createClassDB
# @create    Sat Apr  9 20:44:27 2011
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
package MyClass::JKZDB::GsaUserGachaLog;

use 5.008005;
use strict;
our $VERSION ='1.30';

use base qw(MyClass::JKZDB);
use MyClass::WebUtil;

#******************************************************
# @access    public
# @desc      コンストラクタ
# @param     
# @return    
# @author    
#******************************************************
sub new {
    my ($class, $dbh) = @_;
    my $table = 'dMOEPETIT_LOG.tGsaUserGachaLogF';
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
$self->{columnslist}->{in_date}->[$i] = $aryref->[$i]->[1];
$self->{columnslist}->{my_item_id}->[$i] = $aryref->[$i]->[2];
$self->{columnslist}->{itemm_id}->[$i] = $aryref->[$i]->[3];
$self->{columnslist}->{item_name}->[$i] = $aryref->[$i]->[4];
$self->{columnslist}->{registration_date}->[$i] = $aryref->[$i]->[5];
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
$self->{columns}->{in_date},
$self->{columns}->{my_item_id},
$self->{columns}->{itemm_id},
$self->{columns}->{item_name},
$self->{columns}->{registration_date}
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
    $self->{columns}->{in_date}	     = $param->{in_date};

    ## ここでPrimaryKeyが設定されている場合はUpdate
    ## 設定がない場合はInsert
    #if ($self->{columns}->{in_date} < 0) {
    if ($flag < 0) {
        ##1. AutoIncrementでない場合はここで最大値を取得
        ##2. 挿入 

        #************************ AUTO GENERATED COLUMNS AND PLACEHOLDERS HAS BENN COMBINED BEGIN ************************
        push( @{ $sqlref->[0] }, "gree_user_id" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{gree_user_id} ) if $param->{gree_user_id} != "";
        push( @{ $sqlref->[0] }, "in_date" ), push( @{ $sqlref->[1] }, "DATE_FORMAT(NOW(), '%Y%m%d')" );#, push( @{ $sqlref->[2] }, $param->{in_date} ) if $param->{in_date} ne "";
        push( @{ $sqlref->[0] }, "my_item_id" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{my_item_id} ) if $param->{my_item_id} ne "";
        push( @{ $sqlref->[0] }, "itemm_id" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{itemm_id} ) if $param->{itemm_id} != "";
        push( @{ $sqlref->[0] }, "item_name" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{item_name} ) if $param->{item_name} ne "";
        push( @{ $sqlref->[0] }, "registration_date" ), push( @{ $sqlref->[1] }, "NOW()" );#, push( @{ $sqlref->[2] }, $param->{registration_date} ) if $param->{registration_date} ne "";

        #************************ AUTO GENERATED COLUMNS AND PLACEHOLDERS HAS BENN COMBINED   END ************************

        $sqlMoji = sprintf("INSERT INTO %s (%s) VALUES (%s);", $self->{table}, join(',', @{ $sqlref->[0] }), join(',', @{ $sqlref->[1] }));
        $rv = $self->executeQuery($sqlMoji, $sqlref->[2]);

        return $rv; # return value

    } else {
        map { exists ($self->{columns}->{$_}) ? push (@{ $sqlref->[0] }, $_) && push (@{ $sqlref->[1] }, $param->{$_}) : ""} keys %$param;
        $sqlMoji = sprintf("UPDATE $self->{table} SET %s =?  WHERE gree_user_id= '$self->{columns}->{gree_user_id}' AND in_date= '$self->{columns}->{in_date}';", join('=?,', @{ $sqlref->[0] }));
        $rv = $self->executeQuery($sqlMoji, $sqlref->[1]);

        return $rv; # return value

    }
}


#******************************************************
# @access    public
# @desc      本日ガチャを実行したか
# @desc      ガチャ済みは1
# @param     int gree_user_id
# @return    beelan 1
#******************************************************
sub checkGachaToday {
	my ($self, $gree_user_id) = @_;
	return undef if !$gree_user_id || 0 > $gree_user_id;

	#my $sqlMoji = sprintf("SELECT 1 FROM %s WHERE gree_user_id=? AND in_date=DATE_FORMAT(NOW(), '%Y%m%d');", $self->switchMRG_MyISAMTableSQL({ separater => '_', value => MyClass::WebUtil::GetTime("5") }));
	my $sqlMoji = sprintf("SELECT 1 FROM %s", $self->switchMRG_MyISAMTableSQL({ separater => '_', value => MyClass::WebUtil::GetTime("5") }));
    $sqlMoji .= " WHERE gree_user_id=? AND in_date=DATE_FORMAT(NOW(), '%Y%m%d');";

	my $rv      = $self->dbh->selectrow_array($sqlMoji, undef, $gree_user_id);

	return $rv;
}


1;

