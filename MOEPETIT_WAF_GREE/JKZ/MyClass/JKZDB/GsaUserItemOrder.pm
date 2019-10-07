#******************************************************
# @desc      
#            
# @package    MyClass::JKZDB::GsaUserItemOrder
# @access    public
# @author    Iwahase Ryo AUTO CREATE BY ./createClassDB
# @create    Tue Apr 26 12:31:14 2011
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
package MyClass::JKZDB::GsaUserItemOrder;

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
    my $table = 'dMOEPETIT.tGsaUserItemOrderF';
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
$self->{columnslist}->{paymentId}->[$i] = $aryref->[$i]->[0];
$self->{columnslist}->{status}->[$i] = $aryref->[$i]->[1];
$self->{columnslist}->{orderTime}->[$i] = $aryref->[$i]->[2];
$self->{columnslist}->{gree_user_id}->[$i] = $aryref->[$i]->[3];
$self->{columnslist}->{itemm_id}->[$i] = $aryref->[$i]->[4];
$self->{columnslist}->{item_type}->[$i] = $aryref->[$i]->[5];
$self->{columnslist}->{item_categorym_id}->[$i] = $aryref->[$i]->[6];
$self->{columnslist}->{item_name}->[$i] = $aryref->[$i]->[7];
$self->{columnslist}->{qty}->[$i] = $aryref->[$i]->[8];
$self->{columnslist}->{item_unit_price}->[$i] = $aryref->[$i]->[9];
$self->{columnslist}->{registration_date}->[$i] = $aryref->[$i]->[10];
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
$self->{columns}->{paymentId},
$self->{columns}->{status},
$self->{columns}->{orderTime},
$self->{columns}->{gree_user_id},
$self->{columns}->{itemm_id},
$self->{columns}->{item_type},
$self->{columns}->{item_categorym_id},
$self->{columns}->{item_name},
$self->{columns}->{qty},
$self->{columns}->{item_unit_price},
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

    $self->{columns}->{paymentId} = $param->{paymentId};

    ## flag値が0より小さいときはインサート
    if ($flag < 0) {
        ##1. AutoIncrementでない場合はここで最大値を取得
        ##2. 挿入 

        #************************ AUTO GENERATED COLUMNS AND PLACEHOLDERS HAS BENN COMBINED BEGIN ************************
        push( @{ $sqlref->[0] }, "paymentId" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{paymentId} ) if $param->{paymentId} ne "";
        push( @{ $sqlref->[0] }, "status" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{status} ) if $param->{status} != "";
        push( @{ $sqlref->[0] }, "orderTime" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{orderTime} ) if $param->{orderTime} ne "";
        push( @{ $sqlref->[0] }, "gree_user_id" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{gree_user_id} ) if $param->{gree_user_id} != "";
        push( @{ $sqlref->[0] }, "itemm_id" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{itemm_id} ) if $param->{itemm_id} != "";
        push( @{ $sqlref->[0] }, "item_type" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{item_type} ) if $param->{item_type} != "";
        push( @{ $sqlref->[0] }, "item_categorym_id" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{item_categorym_id} ) if $param->{item_categorym_id} != "";
        push( @{ $sqlref->[0] }, "item_name" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{item_name} ) if $param->{item_name} ne "";
        push( @{ $sqlref->[0] }, "qty" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{qty} ) if $param->{qty} != "";
        push( @{ $sqlref->[0] }, "item_unit_price" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{item_unit_price} ) if $param->{item_unit_price} ne "";
        push( @{ $sqlref->[0] }, "registration_date" ), push( @{ $sqlref->[1] }, "NOW()" );#, push( @{ $sqlref->[2] }, $param->{registration_date} ) if $param->{registration_date} ne "";

        #************************ AUTO GENERATED COLUMNS AND PLACEHOLDERS HAS BENN COMBINED   END ************************

        $sqlMoji = sprintf("INSERT INTO %s (%s) VALUES (%s);", $self->{table}, join(',', @{ $sqlref->[0] }), join(',', @{ $sqlref->[1] }));
        $rv = $self->executeQuery($sqlMoji, $sqlref->[2]);

        return $rv; # return value

    } else {

        map { exists ($self->{columns}->{$_}) ? push (@{ $sqlref->[0] }, $_) && push (@{ $sqlref->[1] }, $param->{$_}) : ""} keys %$param;
        $sqlMoji = sprintf("UPDATE $self->{table} SET %s =?  WHERE paymentId= '$self->{columns}->{paymentId}';", join('=?,', @{ $sqlref->[0] }));
        $rv = $self->executeQuery($sqlMoji, $sqlref->[1]);

        return $rv; # return value

    }
}


#******************************************************
# @desc     決済IDをキーに決済ステータスの更新
# @param    string paymentID
# @param    int    status
# @return   boolean 
#******************************************************
sub updateOrderStatusByPaymentID {
    my ($self, $paymentId, $status) = @_;
    return if !$paymentId || !$status;

    my $sqlMoji = sprintf("UPDATE %s SET status=? WHERE paymentId=?;", $self->table);
    my $rv      = $self->dbh->do($sqlMoji, undef, $status, $paymentId);

    return $rv;
}


#******************************************************
# @desc     決済IDをキーに注文アイテム情報を取得
# @param    string paymentID
# @param    int    status
# @return   戻り値のstatusを確認すること 3, 4の場合は決済キャンセルもしくは期限切れ
# @return  hashobj
#******************************************************
sub fetchItemOrderDataByPaymentID {
    my ($self, $paymentId) = @_;
    return if !$paymentId;

    my $sqlMoji = sprintf("SELECT
 paymentId,
 status,
 orderTime,
 gree_user_id,
 itemm_id,
 item_type,
 item_categorym_id,
 item_name,
 qty,
 item_unit_price
 FROM %s WHERE paymentId=?;", $self->table);

    my $return_obj;
    (
      $return_obj->{paymentId},
      $return_obj->{status},
      $return_obj->{orderTime},
      $return_obj->{gree_user_id},
      $return_obj->{itemm_id},
      $return_obj->{item_type},
      $return_obj->{item_categorym_id},
      $return_obj->{item_name},
      $return_obj->{qty},
      $return_obj->{item_unit_price}
    ) = $self->dbh->selectrow_array($sqlMoji, undef, $paymentId);

#    my $return_obj  = $self->dbh->selectall_arrayref( $sqlMoji, { Columns => {} }, $paymentId );
    return $return_obj;
}


1;
__END__