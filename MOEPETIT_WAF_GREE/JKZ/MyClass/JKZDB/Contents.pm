#******************************************************
# @desc        
#            
# @package    MyClass::JKZDB::GsaContents
# @access    public
# @author    Iwahase Ryo AUTO CREATE BY ./createClassDB
# @create    Thu Jan  7 12:48:08 2010
# @version    1.30
# @update    2008/05/30 executeUpdate処理の戻り値部分
# @update    2008/03/31 JKZ::DB::JKZDBのサブクラス化
# @update    2009/02/02 ディレクトリ構成をJKZ::JKZDBに変更
# @update    2009/02/12 リスティング処理を追加
# @update    2009/09/28 executeUpdateメソッドの処理変更
# @update    2010/10/07 is_Valid_Contentsメソッド追加
# @version    1.10
# @version    1.20
# @version    1.30
#******************************************************
package MyClass::JKZDB::Contents;

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
    my $table = 'dMOEPETIT.tContentsM';
    return $class->SUPER::new($dbh, $table);
}


#******************************************************
# @access    
# @desc     SQLを実行します。
# @param    $sql
#           @placeholder
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
$self->{columnslist}->{contents_id}->[$i] = $aryref->[$i]->[0];
$self->{columnslist}->{status_flag}->[$i] = $aryref->[$i]->[1];
$self->{columnslist}->{latest_flag}->[$i] = $aryref->[$i]->[2];
$self->{columnslist}->{recommend_flag}->[$i] = $aryref->[$i]->[3];
$self->{columnslist}->{sum_xy_value}->[$i] = $aryref->[$i]->[4];
$self->{columnslist}->{name}->[$i] = $aryref->[$i]->[5];
$self->{columnslist}->{name_kana}->[$i] = $aryref->[$i]->[6];
$self->{columnslist}->{personality}->[$i] = $aryref->[$i]->[7];
$self->{columnslist}->{appearance}->[$i] = $aryref->[$i]->[8];
$self->{columnslist}->{grade}->[$i] = $aryref->[$i]->[9];
$self->{columnslist}->{bloodtype}->[$i] = $aryref->[$i]->[10];
$self->{columnslist}->{year_of_birth}->[$i] = $aryref->[$i]->[11];
$self->{columnslist}->{month_of_birth}->[$i] = $aryref->[$i]->[12];
$self->{columnslist}->{date_of_birth}->[$i] = $aryref->[$i]->[13];
$self->{columnslist}->{constellation}->[$i] = $aryref->[$i]->[14];
$self->{columnslist}->{hobby}->[$i] = $aryref->[$i]->[15];
$self->{columnslist}->{message}->[$i] = $aryref->[$i]->[16];
$self->{columnslist}->{contentsimage_id}->[$i] = $aryref->[$i]->[17];
$self->{columnslist}->{painter}->[$i] = $aryref->[$i]->[18];
$self->{columnslist}->{stopwatch_id}->[$i] = $aryref->[$i]->[19];
$self->{columnslist}->{registration_date}->[$i] = $aryref->[$i]->[20];
$self->{columnslist}->{lastupdate_date}->[$i] = $aryref->[$i]->[21];
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
$self->{columns}->{contents_id},
$self->{columns}->{status_flag},
$self->{columns}->{latest_flag},
$self->{columns}->{recommend_flag},
$self->{columns}->{sum_xy_value},
$self->{columns}->{name},
$self->{columns}->{name_kana},
$self->{columns}->{personality},
$self->{columns}->{appearance},
$self->{columns}->{grade},
$self->{columns}->{bloodtype},
$self->{columns}->{year_of_birth},
$self->{columns}->{month_of_birth},
$self->{columns}->{date_of_birth},
$self->{columns}->{constellation},
$self->{columns}->{hobby},
$self->{columns}->{message},
$self->{columns}->{contentsimage_id},
$self->{columns}->{painter},
$self->{columns}->{stopwatch_id},
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
    #             [ values array        ],        2
    #            ]
    #******************************************************
    my $sqlref;
    my $rv;

    if ($self->{this_dbh} == "") {
        #エラー処理
    }

    $self->{columns}->{contents_id} = $param->{contents_id};

    ## ここでPrimaryKeyが設定されている場合はUpdate
    ## 設定がない場合はInsert
    if ($self->{columns}->{contents_id} < 0) {
        ##1. AutoIncrementでない場合はここで最大値を取得
        ##2. 挿入 

        #************************ AUTO GENERATED COLUMNS AND PLACEHOLDERS HAS BENN COMBINED BEGIN ************************
        #push( @{ $sqlref->[0] }, "contents_id" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{contents_id} ) if $param->{contents_id} != "";
        push( @{ $sqlref->[0] }, "status_flag" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{status_flag} ) if $param->{status_flag} != "";
        push( @{ $sqlref->[0] }, "latest_flag" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{latest_flag} ) if $param->{latest_flag} != "";
        push( @{ $sqlref->[0] }, "recommend_flag" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{recommend_flag} ) if $param->{recommend_flag} != "";
        push( @{ $sqlref->[0] }, "sum_xy_value" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{sum_xy_value} ) if $param->{sum_xy_value} != "";
        push( @{ $sqlref->[0] }, "name" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{name} ) if $param->{name} ne "";
        push( @{ $sqlref->[0] }, "name_kana" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{name_kana} ) if $param->{name_kana} ne "";
        push( @{ $sqlref->[0] }, "personality" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{personality} ) if $param->{personality} ne "";
        push( @{ $sqlref->[0] }, "appearance" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{appearance} ) if $param->{appearance} ne "";
        push( @{ $sqlref->[0] }, "grade" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{grade} ) if $param->{grade} ne "";
        push( @{ $sqlref->[0] }, "bloodtype" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{bloodtype} ) if $param->{bloodtype} != "";
        push( @{ $sqlref->[0] }, "year_of_birth" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{year_of_birth} ) if $param->{year_of_birth} ne "";
        push( @{ $sqlref->[0] }, "month_of_birth" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{month_of_birth} ) if $param->{month_of_birth} ne "";
        push( @{ $sqlref->[0] }, "date_of_birth" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{date_of_birth} ) if $param->{date_of_birth} ne "";
        push( @{ $sqlref->[0] }, "constellation" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{constellation} ) if $param->{constellation} ne "";
        push( @{ $sqlref->[0] }, "hobby" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{hobby} ) if $param->{hobby} ne "";
        push( @{ $sqlref->[0] }, "message" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{message} ) if $param->{message} ne "";
        push( @{ $sqlref->[0] }, "contentsimage_id" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{contentsimage_id} ) if $param->{contentsimage_id} != "";
        push( @{ $sqlref->[0] }, "painter" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{painter} ) if $param->{painter} ne "";
        push( @{ $sqlref->[0] }, "stopwatch_id" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{stopwatch_id} ) if $param->{stopwatch_id} != "";
        push( @{ $sqlref->[0] }, "registration_date" ), push( @{ $sqlref->[1] }, "NOW()" );#, push( @{ $sqlref->[2] }, $param->{registration_date} ) if $param->{registration_date} ne "";
        #push( @{ $sqlref->[0] }, "lastupdate_date" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{lastupdate_date} ) if $param->{lastupdate_date} ne "";

        #************************ AUTO GENERATED COLUMNS AND PLACEHOLDERS HAS BENN COMBINED   END ************************

        $sqlMoji = sprintf("INSERT INTO %s (%s) VALUES (%s);", $self->{table}, join(',', @{ $sqlref->[0] }), join(',', @{ $sqlref->[1] }));
        $rv = $self->executeQuery($sqlMoji, $sqlref->[2]);

        return $rv; # return value

    } else {

        map { exists ($self->{columns}->{$_}) ? push (@{ $sqlref->[0] }, $_) && push (@{ $sqlref->[1] }, $param->{$_}) : ""} keys %$param;
        $sqlMoji = sprintf("UPDATE $self->{table} SET %s =?  WHERE contents_id= '$self->{columns}->{contents_id}';", join('=?,', @{ $sqlref->[0] }));
        $rv = $self->executeQuery($sqlMoji, $sqlref->[1]);

        return $rv; # return value
    }
}


#******************************************************
# @desc     コンテンツIDからコンテンツが存在するか、もしくはステータスが有効か判定
# @param    int contents_id
# @return   contents_name
#******************************************************
sub is_Valid_Contents {
    my $self = shift;
    my $contents_id = shift || return undef;

    my $sqlMoji = sprintf("SELECT name FROM %s WHERE contents_id=? AND status_flag=2;", $self->table);
    my $rv      = $self->dbh->selectrow_array($sqlMoji, undef, $contents_id);

    return $rv;
}


#******************************************************
# @desc     キャラクタコンプで取得できるSWのIDとｷｬﾗ名
# @param    /
# @param    
# @return   arrayobj   [ {name, stopwatch_id } ]
#******************************************************
sub fetchStopWatchID {
    my $self        = shift;
    my $sqlMoji     = sprintf("SELECT name, stopwatch_id FROM %s WHERE status_flag=2;", $self->table);
    my $return_obj  = $self->dbh->selectall_arrayref($sqlMoji, { Columns => {} });

    return $return_obj
}


1;
__END__

