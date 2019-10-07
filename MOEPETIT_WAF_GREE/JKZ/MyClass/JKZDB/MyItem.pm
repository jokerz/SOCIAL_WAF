#******************************************************
# @desc      
#            
# @package    MyClass::JKZDB::MyItem
# @access    public
# @author    Iwahase Ryo AUTO CREATE BY createClassDB
# @create    Thu Apr  7 20:12:49 2011
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
package MyClass::JKZDB::MyItem;

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
    my $table = 'dMOEPETIT.tMyItemF';
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
$self->{columnslist}->{my_item_id}->[$i] = $aryref->[$i]->[0];
$self->{columnslist}->{gree_user_id}->[$i] = $aryref->[$i]->[1];
$self->{columnslist}->{status_flag}->[$i] = $aryref->[$i]->[2];
$self->{columnslist}->{item_type}->[$i] = $aryref->[$i]->[3];
$self->{columnslist}->{item_categorym_id}->[$i] = $aryref->[$i]->[4];
$self->{columnslist}->{itemm_id}->[$i] = $aryref->[$i]->[5];
$self->{columnslist}->{item_name}->[$i] = $aryref->[$i]->[6];
$self->{columnslist}->{registration_date}->[$i] = $aryref->[$i]->[7];
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
$self->{columns}->{my_item_id},
$self->{columns}->{gree_user_id},
$self->{columns}->{status_flag},
$self->{columns}->{item_type},
$self->{columns}->{item_categorym_id},
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

    $self->{columns}->{my_item_id} = $param->{my_item_id};

    ## ここでPrimaryKeyが設定されている場合はUpdate
    ## 設定がない場合はInsert
    #if ($self->{columns}->{my_item_id} < 0) {
    if ($flag < 0) {
        ##1. AutoIncrementでない場合はここで最大値を取得
        ##2. 挿入 

        #************************ AUTO GENERATED COLUMNS AND PLACEHOLDERS HAS BENN COMBINED BEGIN ************************
        push( @{ $sqlref->[0] }, "my_item_id" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{my_item_id} ) if $param->{my_item_id} ne "";
        push( @{ $sqlref->[0] }, "gree_user_id" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{gree_user_id} ) if $param->{gree_user_id} != "";
        push( @{ $sqlref->[0] }, "status_flag" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{status_flag} ) if $param->{status_flag} != "";
        push( @{ $sqlref->[0] }, "item_type" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{item_type} ) if $param->{item_type} != "";
        push( @{ $sqlref->[0] }, "item_categorym_id" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{item_categorym_id} ) if $param->{item_categorym_id} != "";
        push( @{ $sqlref->[0] }, "itemm_id" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{itemm_id} ) if $param->{itemm_id} != "";
        push( @{ $sqlref->[0] }, "item_name" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{item_name} ) if $param->{item_name} ne "";
        push( @{ $sqlref->[0] }, "registration_date" ), push( @{ $sqlref->[1] }, "NOW()" );#, push( @{ $sqlref->[2] }, $param->{registration_date} ) if $param->{registration_date} ne "";

        #************************ AUTO GENERATED COLUMNS AND PLACEHOLDERS HAS BENN COMBINED   END ************************

        $sqlMoji = sprintf("INSERT INTO %s (%s) VALUES (%s);", $self->{table}, join(',', @{ $sqlref->[0] }), join(',', @{ $sqlref->[1] }));
        $rv = $self->executeQuery($sqlMoji, $sqlref->[2]);

        return $rv; # return value

    } else {

        map { exists ($self->{columns}->{$_}) ? push (@{ $sqlref->[0] }, $_) && push (@{ $sqlref->[1] }, $param->{$_}) : ""} keys %$param;
        $sqlMoji = sprintf("UPDATE $self->{table} SET %s =?  WHERE my_item_id= '$self->{columns}->{my_item_id}';", join('=?,', @{ $sqlref->[0] }));
        $rv = $self->executeQuery($sqlMoji, $sqlref->[1]);

        return $rv; # return value

    }
}


#******************************************************
# @desc     itemm_idで所持しているｱｲﾃﾑデータを取得
# @param    { gree_user_id, itemm_id, status_flag }
# @return   arrayobj  [ {my_item_id item_name } ]
#******************************************************
sub fetchMyItemByItemID {
    my ($self, $param)  = @_;
    return if !exists($param->{gree_user_id}) || !exists($param->{itemm_id});

    ## status_flagが指定されていなければstatus_flagを検索条件にしない
    my $condition = exists($param->{status_flag}) ? " AND status_flag= $param->{status_flag}" : "";

    my $sqlMoji = sprintf("SELECT my_item_id, item_name FROM %s WHERE gree_user_id=? AND itemm_id= ? %s;", $self->table, $condition);

    my $return_obj = $self->dbh->selectall_arrayref($sqlMoji, { Columns => {} }, $param->{gree_user_id}, $param->{itemm_id});
    
    return $return_obj;
}


#******************************************************
# @desc     ﾌﾗｯｼｭゲーム用アイテム取得
# @param    int gree_user_id
# @return   arrayobj  [ {my_item_id itemm_id item_name } ]
#******************************************************
sub fetchMyItemForFlashGame {
    my ($self, $gree_user_id)  = @_;
    return if !$gree_user_id;

    my $sqlMoji = sprintf("SELECT my_item_id, itemm_id, item_name FROM %s
 WHERE gree_user_id=?
 AND item_categorym_id IN(2000,3000,4000,5000)
 AND status_flag=2
 ORDER BY itemm_id;", $self->table);

    my $return_obj = $self->dbh->selectall_arrayref($sqlMoji, { Columns => {} }, $gree_user_id);

    return $return_obj;
}


#******************************************************
# @desc     図鑑用アイテムの取得(額縁) item_category_id 7000番台
# @param    int gree_user_id
# @return   arrayobj  [ {my_item_id itemm_id item_name } ]
#******************************************************
sub fetchMyItemForMyLibrary {
    my ($self, $gree_user_id)  = @_;
    return if !$gree_user_id;

    my $sqlMoji = sprintf("SELECT my_item_id, itemm_id, item_name FROM %s
 WHERE gree_user_id=?
 AND item_categorym_id=?
 AND status_flag=2
 ORDER BY itemm_id;", $self->table);

    my $return_obj = $self->dbh->selectall_arrayref($sqlMoji, { Columns => {} }, $gree_user_id, 7000);

    return $return_obj;
}


#******************************************************
# @desc     ガチャ取得アイテム (交換用ｱｲﾃﾑ)item_category_id 12000番台
#           の交換チケット専用
# @param    int gree_user_id
# @return   arrayobj  [ {my_item_id itemm_id item_name } ]
#******************************************************
sub fetchMyItemForItemExchange {
    my ($self, $gree_user_id)  = @_;
    return if !$gree_user_id;

    my $sqlMoji = sprintf("SELECT my_item_id, itemm_id, item_name FROM %s
 WHERE gree_user_id=?
 AND itemm__id=?
 AND status_flag=2;", $self->table);

    my $return_obj = $self->dbh->selectall_arrayref($sqlMoji, { Columns => {} }, $gree_user_id, 12001);

    return $return_obj;
}


#******************************************************
# @desc     指定しアイテムの所持数とアイテム名の取得
#           
# @param    hashobj { gree_user_id item_id status_flag }
# @return   hashobj   {itemm_id item_name item_qty }
#******************************************************
sub getCountOfMyItemByItemId {
    my ($self, $param) = @_;
    return if !exists($param->{gree_user_id}) || !exists($param->{itemm_id});

    my $return_obj;
    my $sqlMoji = sprintf("SELECT itemm_id, item_name, COUNT(my_item_id) AS item_qty FROM %s WHERE gree_user_id=? AND itemm_id=? AND status_flag=?;", $self->table);
    ($return_obj->{itemm_id}, $return_obj->{item_name}, $return_obj->{item_qty}) = $self->dbh->selectrow_array($sqlMoji, undef, $param->{gree_user_id}, $param->{itemm_id}, $param->{status_flag});

    return $return_obj;
}


#******************************************************
# @desc     アイテムステータス更新
# @param    hashobj my_item_id status_flag
# @return  
#******************************************************
sub updateMyItemStatus {
    my ($self, $param) = @_;
    return if !exists($param->{my_item_id});

    my $sqlMoji = sprintf("UPDATE %s SET status_flag=? WHERE my_item_id=?;", $self->table);
    my $rv = $self->dbh->do($sqlMoji, undef, $param->{staus_flag}, $param->{my_item_id});
    
    return $rv;
}


#******************************************************
# @desc     アイテムステータス確認 有効であれば1を返す。以外はなし
# @param    hashobj gree_user_id my_item_id
# @return   boolean 1/
#******************************************************
sub checkMyItemIfValid {
    my ($self, $param) = @_;
    return if !exists($param->{gree_user_id}) || !exists($param->{my_item_id});

    my $sqlMoji = sprintf("SELECT 1 FROM %s WHERE my_item_id=? AND status_flag=2 AND gree_user_id=?;", $self->table);
    my $rv = $self->dbh->selectrow_array($sqlMoji, undef, $param->{my_item_id}, $param->{gree_user_id});

    return $rv;
}


#******************************************************
# @desc     SWを設定する 所持SWのsutaus_flagの値が4は一つしかあってはいけない
#           設定するSWのstatus_flagは4にUPDATE
#           対象のSW以外はstatus_flagを2にUPDATE
# @param    char my_item_id
# @param    int  gree_user_id
# @return   return code
#******************************************************
sub setMyStopWatch {
    my ($self, $my_item_id, $gree_user_id) = @_;
    return if !$my_item_id || !$gree_user_id;

    my $sqlMoji = sprintf(" UPDATE %s
 SET status_flag = CASE WHEN my_item_id =? AND item_categorym_id IN (6000, 11000)
                            THEN 4
                        WHEN  my_item_id !=? AND item_categorym_id IN (6000, 11000)
                            THEN 2
                        ELSE status_flag END
 WHERE gree_user_id=?;", $self->{table});

    my $rv = $self->dbh->do($sqlMoji, undef, $my_item_id, $my_item_id, $gree_user_id);
    return $rv;
    #return (($rv eq '0E0') ? undef : 1);
}


#******************************************************
# @desc     SWを外す。 対象のアイテムのstatus_flagを2にする。
# @param    char my_item_id
# @param    int  gree_user_id
# @return   
#******************************************************
sub unsetMyStopWatch {
    my ($self, $my_item_id, $gree_user_id) = @_;
    return if !$my_item_id || !$gree_user_id;

    my $sqlMoji = sprintf(" UPDATE %s SET status_flag=2 WHERE my_item_id=? AND gree_user_id=? AND item_categorym_id IN (6000, 11000);", $self->table);
    my $rv      = $self->dbh->do($sqlMoji, undef, $my_item_id, $gree_user_id);

    return $rv;
}


1;

