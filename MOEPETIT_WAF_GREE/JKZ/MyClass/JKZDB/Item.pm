#******************************************************
# @desc      
#            
# @package    MyClass::JKZDB::Item
# @access    public
# @author    Iwahase Ryo AUTO CREATE BY ./createClassDB
# @create    Thu Mar 31 16:50:22 2011
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
package MyClass::JKZDB::Item;

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
    my $table = 'dMOEPETIT.tItemM';
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
$self->{columnslist}->{item_categorym_id}->[$i] = $aryref->[$i]->[0];
$self->{columnslist}->{item_id}->[$i] = $aryref->[$i]->[1];
$self->{columnslist}->{status_flag}->[$i] = $aryref->[$i]->[2];
$self->{columnslist}->{item_type}->[$i] = $aryref->[$i]->[3];
$self->{columnslist}->{item_name}->[$i] = $aryref->[$i]->[4];
$self->{columnslist}->{item_unit_price}->[$i] = $aryref->[$i]->[5];
$self->{columnslist}->{item_description}->[$i] = $aryref->[$i]->[6];
$self->{columnslist}->{item_detail}->[$i] = $aryref->[$i]->[7];
$self->{columnslist}->{registration_date}->[$i] = $aryref->[$i]->[8];
$self->{columnslist}->{lastupdate_date}->[$i] = $aryref->[$i]->[9];
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
$self->{columns}->{item_categorym_id},
$self->{columns}->{item_id},
$self->{columns}->{status_flag},
$self->{columns}->{item_type},
$self->{columns}->{item_name},
$self->{columns}->{item_unit_price},
$self->{columns}->{item_description},
$self->{columns}->{item_detail},
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
    my ($self, $param) = @_;

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

    $self->{columns}->{item_id} = $param->{item_id};
    $self->{columns}->{item_categorym_id} = $param->{item_categorym_id};

    ## ここでPrimaryKeyが設定されている場合はUpdate
    ## 設定がない場合はInsert
    if ($self->{columns}->{item_id} < 0) {
        ##1. AutoIncrementでない場合はここで最大値を取得
        ##2. 挿入 

        #************************ AUTO GENERATED COLUMNS AND PLACEHOLDERS HAS BENN COMBINED BEGIN ************************
        push( @{ $sqlref->[0] }, "item_categorym_id" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{item_categorym_id} ) if $param->{item_categorym_id} != "";
#        push( @{ $sqlref->[0] }, "item_id" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{item_id} ) if $param->{item_id} != "";
        push( @{ $sqlref->[0] }, "status_flag" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{status_flag} ) if $param->{status_flag} != "";
        push( @{ $sqlref->[0] }, "item_type" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{item_type} ) if $param->{item_type} != "";
        push( @{ $sqlref->[0] }, "item_name" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{item_name} ) if $param->{item_name} ne "";
        push( @{ $sqlref->[0] }, "item_unit_price" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{item_unit_price} ) if $param->{item_unit_price} ne "";
        push( @{ $sqlref->[0] }, "item_description" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{item_description} ) if $param->{item_description} ne "";
        push( @{ $sqlref->[0] }, "item_detail" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{item_detail} ) if $param->{item_detail} ne "";
        push( @{ $sqlref->[0] }, "registration_date" ), push( @{ $sqlref->[1] }, "NOW()" );#, push( @{ $sqlref->[2] }, $param->{registration_date} ) if $param->{registration_date} ne "";
        #push( @{ $sqlref->[0] }, "lastupdate_date" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{lastupdate_date} ) if $param->{lastupdate_date} ne "";

        #************************ AUTO GENERATED COLUMNS AND PLACEHOLDERS HAS BENN COMBINED   END ************************

        $sqlMoji = sprintf("INSERT INTO %s (%s) VALUES (%s);", $self->{table}, join(',', @{ $sqlref->[0] }), join(',', @{ $sqlref->[1] }));
        $rv = $self->executeQuery($sqlMoji, $sqlref->[2]);

        return $rv; # return value

    } else {

        map { exists ($self->{columns}->{$_}) ? push (@{ $sqlref->[0] }, $_) && push (@{ $sqlref->[1] }, $param->{$_}) : ""} keys %$param;
        $sqlMoji = sprintf("UPDATE $self->{table} SET %s =?  WHERE item_categorym_id= '$self->{columns}->{item_categorym_id}' AND item_id= '$self->{columns}->{item_id}';", join('=?,', @{ $sqlref->[0] }));
        $rv = $self->executeQuery($sqlMoji, $sqlref->[1]);

        return $rv; # return value

    }
}


#******************************************************
# @desc     item_category_idを条件にアイテムリストを取得
# @param    item_category_id
# @param    
# @return   arrayobj [ { item_categorym_id item_id item_name itemm_id} ]
#******************************************************
sub fetchItemByItemCategoryID {
    my ($self, $item_category_id) = @_;
    return if !$item_category_id;

    my $sqlMoji = sprintf("SELECT item_categorym_id, item_id, item_name, (item_categorym_id + item_id) AS itemm_id  FROM %s WHERE item_categorym_id=?;", $self->table);

    my $return_obj = $self->dbh->selectall_arrayref($sqlMoji, { Columns => {} }, $item_category_id);

	return $return_obj;
}


#******************************************************
# @desc     item_typeを条件にアイテムリストを取得
# @param    item_type
# @param    
# @return   arrayobj [ { item_categorym_id item_id item_name itemm_id} ]
#******************************************************
sub fetchItemByItemType {
    my ($self, $item_type) = @_;
    return if !$item_type;

    my $sqlMoji = sprintf("SELECT item_categorym_id, item_id, item_name, (item_categorym_id + item_id) AS itemm_id  FROM %s WHERE item_type=?;", $self->table);

    my $return_obj = $self->dbh->selectall_arrayref($sqlMoji, { Columns => {} }, $item_type);

	return $return_obj;
}


#******************************************************
# @desc     ｶﾞﾁｬで付与するアイテム情報。
# @param    現状は１つだけしかないので決め内で実行
# @param    
# @return   
#******************************************************
sub fetchGachaItem {
    my $self = shift;

    my $return_obj = $self->getSpecificValuesSQL({
                            columns     => ['item_categorym_id', 'item_id', 'item_type', 'item_name'],
                            whereSQL    => 'item_categorym_id=? AND item_id=? AND status_flag=2',
                            placeholder => ["12000", "1"],
                     });

    return $return_obj;
}


1;

