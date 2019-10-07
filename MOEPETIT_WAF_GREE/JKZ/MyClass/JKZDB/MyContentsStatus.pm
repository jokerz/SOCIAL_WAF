#******************************************************
# @desc      
#            
# @package    MyClass::JKZDB::MyContentsStatus
# @access    public
# @author    Iwahase Ryo AUTO CREATE BY ./createClassDB
# @create    Sat Apr 30 17:08:27 2011
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
package MyClass::JKZDB::MyContentsStatus;

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
    my $table = 'dMOEPETIT.tMyContentsStatusF';
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
$self->{columnslist}->{sum_category_id}->[$i] = $aryref->[$i]->[2];
$self->{columnslist}->{stopwatch_id}->[$i] = $aryref->[$i]->[3];
$self->{columnslist}->{contents_name}->[$i] = $aryref->[$i]->[4];
$self->{columnslist}->{registration_date}->[$i] = $aryref->[$i]->[5];
$self->{columnslist}->{lastupdate_date}->[$i] = $aryref->[$i]->[6];
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
$self->{columns}->{sum_category_id},
$self->{columns}->{stopwatch_id},
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


    ## 設定がない場合はInsert
    if ($flag < 0) {
        ##1. AutoIncrementでない場合はここで最大値を取得
        ##2. 挿入 

        #************************ AUTO GENERATED COLUMNS AND PLACEHOLDERS HAS BENN COMBINED BEGIN ************************
        push( @{ $sqlref->[0] }, "gree_user_id" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{gree_user_id} ) if $param->{gree_user_id} != "";
        push( @{ $sqlref->[0] }, "contentsm_id" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{contentsm_id} ) if $param->{contentsm_id} != "";
        push( @{ $sqlref->[0] }, "sum_category_id" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{sum_category_id} ) if $param->{sum_category_id} != "";
        push( @{ $sqlref->[0] }, "stopwatch_id" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{stopwatch_id} ) if $param->{stopwatch_id} != "";
        push( @{ $sqlref->[0] }, "contents_name" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{contents_name} ) if $param->{contents_name} ne "";
        push( @{ $sqlref->[0] }, "registration_date" ), push( @{ $sqlref->[1] }, "NOW()" );#, push( @{ $sqlref->[2] }, $param->{registration_date} ) if $param->{registration_date} ne "";
        #push( @{ $sqlref->[0] }, "lastupdate_date" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{lastupdate_date} ) if $param->{lastupdate_date} ne "";

        #************************ AUTO GENERATED COLUMNS AND PLACEHOLDERS HAS BENN COMBINED   END ************************

        #$sqlMoji = sprintf("INSERT INTO %s (%s) VALUES (%s);", $self->{table}, join(',', @{ $sqlref->[0] }), join(',', @{ $sqlref->[1] }));
        # Modified 2011/05/10 既にデータがある場合はsum_categorym_idを更新
        $sqlMoji = sprintf("INSERT INTO %s (%s) VALUES (%s) ON DUPLICATE KEY UPDATE sum_category_id=(sum_category_id + '$param->{sum_category_id}');", $self->{table}, join(',', @{ $sqlref->[0] }), join(',', @{ $sqlref->[1] }));

        $rv = $self->executeQuery($sqlMoji, $sqlref->[2]);

        return $rv; # return value

    }

    else {

        map { exists ($self->{columns}->{$_}) ? push (@{ $sqlref->[0] }, $_) && push (@{ $sqlref->[1] }, $param->{$_}) : ""} keys %$param;
        $sqlMoji = sprintf("UPDATE $self->{table} SET %s =?  WHERE gree_user_id= '$self->{columns}->{gree_user_id}' AND contentsm_id= '$self->{columns}->{contentsm_id}';", join('=?,', @{ $sqlref->[0] }));
        $rv = $self->executeQuery($sqlMoji, $sqlref->[1]);

        return $rv; # return value

    }
}



#******************************************************
# @desc    コンテンツのカテゴリの合計値からカテゴリIDをカンマで返す
# @param   カテゴリIDは6までだからsetは6までしか生成しない
# @param   { gree_user_id contentsm_id}
# @return  
#******************************************************
sub makeSetOfCategoryID {
    my $self = shift;
    unless (@_) {
        ## 引数がない場合はエラー
        return;
    }
    my $param = shift;
    my $sqlMoji = sprintf ("SELECT MAKE_SET(sum_category_id, %s) ", join ' , ', map { 2**$_ } (0..6));
       $sqlMoji .= " FROM " . $self->table
                    . " WHERE gree_user_id=? AND contentsm_id=?;"
                    ;
    my $sets = $self->dbh->selectrow_array($sqlMoji, undef, $param->{gree_user_id}, $param->{contentsm_id});

    return ($sets);
}


#******************************************************
# @desc     存在するコンテンツのカテゴリ合計値からカテゴリのビット値をカンマ区切りで取得
#           要するに全てのゲット画像IDを取得できる
# @param    int gree_user_id
# @param    
# @return   arrayobj [ { cotentsm_id, [ sum_category_id by comma ] } ]
#******************************************************
sub getAllSetOfCategoryID {
    my $self = shift;
    unless (@_) {
        return;
    }
    
    my $gree_user_id    = shift;
    my $sqlMoji         = sprintf("SELECT contentsm_id, MAKE_SET(sum_category_id, %s) AS sum_category_id  FROM %s WHERE gree_user_id=? GROUP BY contentsm_id;", (join ' , ', map { 2**$_ } (0..6)), $self->table);
    my $aryref          = $self->dbh->selectall_arrayref($sqlMoji, { Columns => {} } , $gree_user_id);

    return $aryref;
}


#******************************************************
# @desc     コンテンツIDから未取得のカテゴリIDのセットを取得
# @param    hash  { gree_user_id, contensm_id, (2**categorym_id) }
# @param    引数にcategorym_idがある場合はその値もふくめての処理を実行
# @return   sclar   (カンマ区切りの値)
#******************************************************
sub getNotCompletedSetOfCategoryIDByContentsID {
    my $self = shift;
    unless (@_) {
        ## 引数がない場合はエラー
        return;
    }
    my $param   = shift;
    my $pow_my_category = exists($param->{categorym_id}) ? (2 ** $param->{categorym_id}) : 0;
    my $sqlMoji = sprintf("SELECT (MAKE_SET((126 - (sum_category_id + %s)), %s)) ", $pow_my_category, join ' , ', map { 2**$_ } (0..6));
       $sqlMoji .= " FROM " . $self->table
                    . " WHERE gree_user_id=? AND contentsm_id=?;"
                    ;
    my $sets = $self->dbh->selectrow_array($sqlMoji, undef, $param->{gree_user_id}, $param->{contentsm_id});

    return ($sets);
}


#******************************************************
# @desc     コンプリートしたキャラクタを取得する
#           コンプリートの条件sum_category_idが126であること
# @param    gree_user_id
# @param    
# @return   array
#******************************************************
sub fetchCompleteContents {
    my $self = shift;
    unless (@_) {
        ## 引数がない場合はエラー
        return;
    }
    my $gree_user_id = shift;

    my $sqlMoji = sprintf("SELECT contentsm_id FROM %s WHERE gree_user_id=? AND sum_category_id=126;", $self->table);
    my $aryref = $self->dbh->selectall_arrayref($sqlMoji, { Slice => {} }, $gree_user_id);
    my @ret;
   map { push @ret, $aryref->[$_]->{contentsm_id} } 0..$#{ $aryref };
    #my $ret = $self->dbh->selectall_arrayref($sqlMoji, undef, $gree_user_id);
    return (@ret);
}




1;
