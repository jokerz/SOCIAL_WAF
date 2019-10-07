#******************************************************
# @desc      
#            
# @package    MyClass::JKZDB::ContentsSwf
# @access    public
# @author    Iwahase Ryo AUTO CREATE BY ./createClassDB
# @create    Mon Apr 11 17:06:15 2011
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
package MyClass::JKZDB::ContentsSwf;

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
    my $table = 'dMOEPETIT.tContentsSwfM';
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
$self->{columnslist}->{swf_id}->[$i] = $aryref->[$i]->[0];
$self->{columnslist}->{swf}->[$i] = $aryref->[$i]->[1];
$self->{columnslist}->{mime_type}->[$i] = $aryref->[$i]->[2];
$self->{columnslist}->{file_size}->[$i] = $aryref->[$i]->[3];
$self->{columnslist}->{height}->[$i] = $aryref->[$i]->[4];
$self->{columnslist}->{width}->[$i] = $aryref->[$i]->[5];
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
$self->{columns}->{swf_id},
$self->{columns}->{swf},
$self->{columns}->{mime_type},
$self->{columns}->{file_size},
$self->{columns}->{height},
$self->{columns}->{width}
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

    $self->{columns}->{swf_id} = $param->{swf_id};

    ## ここでPrimaryKeyが設定されている場合はUpdate
    ## 設定がない場合はInsert
    #if ($self->{columns}->{swf_id} < 0) {
        ##1. AutoIncrementでない場合はここで最大値を取得
        ##2. 挿入 

        #************************ AUTO GENERATED COLUMNS AND PLACEHOLDERS HAS BENN COMBINED BEGIN ************************
        push( @{ $sqlref->[0] }, "swf_id" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{swf_id} ) if $param->{swf_id} ne "";
        push( @{ $sqlref->[0] }, "swf" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{swf} ) if $param->{swf} ne "";
        push( @{ $sqlref->[0] }, "mime_type" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{mime_type} ) if $param->{mime_type} ne "";
        push( @{ $sqlref->[0] }, "file_size" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{file_size} ) if $param->{file_size} ne "";
        push( @{ $sqlref->[0] }, "height" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{height} ) if $param->{height} ne "";
        push( @{ $sqlref->[0] }, "width" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{width} ) if $param->{width} ne "";

        #************************ AUTO GENERATED COLUMNS AND PLACEHOLDERS HAS BENN COMBINED   END ************************

        #$sqlMoji = sprintf("INSERT INTO %s (%s) VALUES (%s);", $self->{table}, join(',', @{ $sqlref->[0] }), join(',', @{ $sqlref->[1] }));

        $sqlMoji = sprintf("REPLACE INTO %s (%s) VALUES (%s);", $self->{table}, join(',', @{ $sqlref->[0] }), join(',', @{ $sqlref->[1] }));
        $rv = $self->executeQuery($sqlMoji, $sqlref->[2]);

        return $rv; # return value

    #}
=pod
     else {

        map { exists ($self->{columns}->{$_}) ? push (@{ $sqlref->[0] }, $_) && push (@{ $sqlref->[1] }, $param->{$_}) : ""} keys %$param;
        $sqlMoji = sprintf("UPDATE $self->{table} SET %s =?  WHERE swf_id= '$self->{columns}->{swf_id}';", join('=?,', @{ $sqlref->[0] }));
        $rv = $self->executeQuery($sqlMoji, $sqlref->[1]);

        return $rv; # return value

    }
=cut
}


#******************************************************
# @access    public
# @desc        レコード削除
# @param    
# @return    boolean
#******************************************************
sub deleteSwfFileSQL {
    my $self = shift;
    my $swf_id = shift;
    my $id = shift;
    #my $placeholder = shift || return undef;

    my $sql = sprintf "DELETE FROM %s WHERE swf_id=?;", $self->table;
    my $rv = $self->{this_dbh}->do($sql, undef, $swf_id);
    return $rv;
}


1;

