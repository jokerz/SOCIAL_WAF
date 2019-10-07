#******************************************************
# @desc        
#            
# @package    MyClass::JKZDB::ContentsImage
# @access    public
# @author    Iwahase Ryo AUTO CREATE BY ./createClassDB
# @create    Thu Jan  7 12:48:05 2010
# @version    1.30
# @update    2008/05/30 executeUpdate処理の戻り値部分
# @update    2008/03/31 JKZ::DB::JKZDBのサブクラス化
# @update    2009/02/02 ディレクトリ構成をJKZ::JKZDBに変更
# @update    2009/02/12 リスティング処理を追加
# @update    2009/09/28 executeUpdateメソッドの処理変更
# @update   2010/01/22 checkRecordメソッドに機能追加
# @version    1.10
# @version    1.20
# @version    1.30
#******************************************************
package MyClass::JKZDB::ContentsImage;

use 5.008005;
use strict;
our $VERSION ='1.30';

use base qw(MyClass::JKZDB);


#******************************************************
# @access    public
# @desc        コンストラクタ
# @param    
# @return    
# @author    
#******************************************************
sub new {
    my ($class, $dbh) = @_;
    my $table = 'dMOEPETIT.tContentsImageM';
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
$self->{columnslist}->{contentsm_id}->[$i] = $aryref->[$i]->[0];
$self->{columnslist}->{categorym_id}->[$i] = $aryref->[$i]->[1];
$self->{columnslist}->{contentsm_name}->[$i] = $aryref->[$i]->[2];
$self->{columnslist}->{categorym_name}->[$i] = $aryref->[$i]->[3];
$self->{columnslist}->{image}->[$i] = $aryref->[$i]->[4];
$self->{columnslist}->{resized_image}->[$i] = $aryref->[$i]->[5];
$self->{columnslist}->{sample_image}->[$i] = $aryref->[$i]->[6];
$self->{columnslist}->{resized_sample_image}->[$i] = $aryref->[$i]->[7];
$self->{columnslist}->{mime_type}->[$i] = $aryref->[$i]->[8];
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
$self->{columns}->{contentsm_id},
$self->{columns}->{categorym_id},
$self->{columns}->{contentsm_name},
$self->{columns}->{categorym_name},
$self->{columns}->{image},
$self->{columns}->{resized_image},
$self->{columns}->{sample_image},
$self->{columns}->{resized_sample_image},
$self->{columns}->{mime_type}
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
    #             [ values array        ],        2
    #            ]
    #******************************************************
    my $sqlref;
    my $rv;

    if ($self->{this_dbh} == "") {
        #エラー処理
    }

    $self->{columns}->{contentsm_id} = $param->{contentsm_id};
    $self->{columns}->{categorym_id} = $param->{categorym_id};

    if (0 > $flag) {
    ## ここでPrimaryKeyが設定されている場合はUpdate
    ## 設定がない場合はInsert
#    if ($self->{columns}->{contentsm_id} < 0) {
        ##1. AutoIncrementでない場合はここで最大値を取得
        ##2. 挿入 

        #************************ AUTO GENERATED COLUMNS AND PLACEHOLDERS HAS BENN COMBINED BEGIN ************************
        push( @{ $sqlref->[0] }, "contentsm_id" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{contentsm_id} ) if $param->{contentsm_id} != "";
        push( @{ $sqlref->[0] }, "categorym_id" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{categorym_id} ) if $param->{categorym_id} != "";
        push( @{ $sqlref->[0] }, "contentsm_name" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{contentsm_name} ) if $param->{contentsm_name} ne "";
        push( @{ $sqlref->[0] }, "categorym_name" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{categorym_name} ) if $param->{categorym_name} ne "";
        push( @{ $sqlref->[0] }, "image" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{image} ) if $param->{image} ne "";
        push( @{ $sqlref->[0] }, "resized_image" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{resized_image} ) if $param->{resized_image} ne "";
        push( @{ $sqlref->[0] }, "sample_image" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{sample_image} ) if $param->{sample_image} ne "";
        push( @{ $sqlref->[0] }, "resized_sample_image" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{resized_sample_image} ) if $param->{resized_sample_image} ne "";
        push( @{ $sqlref->[0] }, "mime_type" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{mime_type} ) if $param->{mime_type} ne "";
        #************************ AUTO GENERATED COLUMNS AND PLACEHOLDERS HAS BENN COMBINED   END ************************

        $sqlMoji = sprintf("REPLACE INTO %s (%s) VALUES (%s);", $self->{table}, join(',', @{ $sqlref->[0] }), join(',', @{ $sqlref->[1] }));
        $rv = $self->executeQuery($sqlMoji, $sqlref->[2]);

        return $rv; # return value
    }
}


#******************************************************
# @access    public
# @desc        レコード削除
# @param    
# @return    boolean
#******************************************************
sub deleteImageSQL {
    my $self = shift;
    my $ref = shift;
    #my $placeholder = shift || return undef;

    my $sql = sprintf "DELETE FROM %s WHERE contentsm_id=?;", $self->table;
    my $rv = $self->{this_dbh}->do($sql, undef, $ref->{contentsm_id});
    return $rv;
}


#******************************************************
# @access    public
# @desc        primary_keyを条件にレコードの検索
# @param    primary key $contentsm_id 
# @param    anything 1
# @return    return value depends on case  1 or count of records
#******************************************************
sub checkRecord {
    my $self = shift;
    my ($contentsm_id, $id, $opt) = @_;

    return if !$contentsm_id;

    my $sql = sprintf("SELECT %s FROM %s WHERE contentsm_id=? AND id=?", ( $opt ? "COUNT(contentsm_id)" : "1" ), $self->table);

    my $rv = $self->{this_dbh}->selectrow_array($sql, undef, $contentsm_id, $id);
}


#******************************************************
# @desc     画像のmime_typeを取得
# @param    contentsm_id
# @param    
# @return   mime_type
#******************************************************
sub fetchMimeType {
    my ($self, $contentsm_id, $id) = @_;
    return if !$contentsm_id;

    my $sqlMoji = sprintf("SELECT mime_type FROM %s WHERE contentsm_id=? AND id=?;", $self->table);
    my $rv      = $self->dbh->selectrow_array($sqlMoji, undef, $contentsm_id, $id);
    return $rv;
}


1;
__END__
