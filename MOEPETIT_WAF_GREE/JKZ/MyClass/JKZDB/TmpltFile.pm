#******************************************************
# @desc		
#			
# @package	MyClass::JKZDB::TmpltFile
# @access	public
# @author	Iwahase Ryo AUTO CREATE BY ./createClassDB
# @create	Wed Jan 13 12:30:10 2010
# @version	1.30
# @update	2008/05/30 executeUpdate処理の戻り値部分
# @update	2008/03/31 JKZ::DB::JKZDBのサブクラス化
# @update	2009/02/02 ディレクトリ構成をJKZ::JKZDBに変更
# @update	2009/02/12 リスティング処理を追加
# @update	2009/09/28 executeUpdateメソッドの処理変更
# @update	2010/01/13  テーブル結合対応にnewメソッド引数追加
# @version	1.10
# @version	1.20
# @version	1.30
#******************************************************
package MyClass::JKZDB::TmpltFile;

use 5.008005;
use strict;
our $VERSION ='1.30';

use base qw(MyClass::JKZDB);


#******************************************************
# @access	public
# @desc		コンストラクタ
# @param	
# @return	
# @author	
#******************************************************
sub new {
	my $class = shift;
	my $dbh   = shift;
    my $arg   = shift if @_ > 0;

    my $table =
       !$arg              ? 'dMOEPETIT.tTmpltFileF'
                          :
       'HASH' eq ref $arg ? { table => 'dMOEPETIT.tTmpltFileF', table_join => $arg->{join_table} }
                          : { table => 'dMOEPETIT.tTmpltFileF', table_join => 'dMOEPETIT.tTmpltM' }
                          ;

	return $class->SUPER::new($dbh, $table);
}


#******************************************************
# @access	
# @desc		SQLを実行します。
# @param	$sql
#			@placeholder
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
$self->{columnslist}->{tmpltfile_id}->[$i] = $aryref->[$i]->[0];
$self->{columnslist}->{tmpltm_id}->[$i] = $aryref->[$i]->[1];
$self->{columnslist}->{status_flag}->[$i] = $aryref->[$i]->[2];
$self->{columnslist}->{activation_date}->[$i] = $aryref->[$i]->[3];
$self->{columnslist}->{tmplt_docomo}->[$i] = $aryref->[$i]->[4];
$self->{columnslist}->{tmplt_softbank}->[$i] = $aryref->[$i]->[5];
$self->{columnslist}->{tmplt_au}->[$i] = $aryref->[$i]->[6];
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
$self->{columns}->{tmpltfile_id},
$self->{columns}->{tmpltm_id},
$self->{columns}->{status_flag},
$self->{columns}->{activation_date},
$self->{columns}->{tmplt_docomo},
$self->{columns}->{tmplt_softbank},
$self->{columns}->{tmplt_au},
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
# @access	public
# @desc		レコード更新処理
#			プライマリキー条件によってINSERTないしはUPDATEの処理を行ないます。
# @param	
# @return	
#******************************************************
sub executeUpdate {
    my ($self, $param) = @_;

    my $sqlMoji;
    #******************************************************
    # TYPE	: arrayreference
    #			[
    #			 [ columns name array],		0
    #			 [ placeholder array ],		1
    #			 [ values array		],		2
    #			]
    #******************************************************
    my $sqlref;
    my $rv;

    if ($self->{this_dbh} == "") {
        #エラー処理
    }

    $self->{columns}->{tmpltfile_id} = $param->{tmpltfile_id};

    ## ここでPrimaryKeyが設定されている場合はUpdate
    ## 設定がない場合はInsert
    if ($self->{columns}->{tmpltfile_id} < 0) {
        ##1. AutoIncrementでない場合はここで最大値を取得
        ##2. 挿入 

        #************************ AUTO GENERATED COLUMNS AND PLACEHOLDERS HAS BENN COMBINED BEGIN ************************
        #push( @{ $sqlref->[0] }, "tmpltfile_id" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{tmpltfile_id} ) if $param->{tmpltfile_id} != "";
        push( @{ $sqlref->[0] }, "tmpltm_id" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{tmpltm_id} ) if $param->{tmpltm_id} != "";
        push( @{ $sqlref->[0] }, "status_flag" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{status_flag} ) if $param->{status_flag} != "";
        push( @{ $sqlref->[0] }, "activation_date" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{activation_date} ) if $param->{activation_date} ne "";
        push( @{ $sqlref->[0] }, "tmplt_docomo" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{tmplt_docomo} ) if $param->{tmplt_docomo} ne "";
        push( @{ $sqlref->[0] }, "tmplt_softbank" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{tmplt_softbank} ) if $param->{tmplt_softbank} ne "";
        push( @{ $sqlref->[0] }, "tmplt_au" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{tmplt_au} ) if $param->{tmplt_au} ne "";
        push( @{ $sqlref->[0] }, "registration_date" ), push( @{ $sqlref->[1] }, "NOW()" );#, push( @{ $sqlref->[2] }, $param->{registration_date} ) if $param->{registration_date} ne "";
        #push( @{ $sqlref->[0] }, "lastupdate_date" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{lastupdate_date} ) if $param->{lastupdate_date} ne "";

        #************************ AUTO GENERATED COLUMNS AND PLACEHOLDERS HAS BENN COMBINED   END ************************

        $sqlMoji = sprintf("INSERT INTO %s (%s) VALUES (%s);", $self->{table}, join(',', @{ $sqlref->[0] }), join(',', @{ $sqlref->[1] }));
        $rv = $self->executeQuery($sqlMoji, $sqlref->[2]);

        return $rv; # return value

    } else {

        map { exists ($self->{columns}->{$_}) ? push (@{ $sqlref->[0] }, $_) && push (@{ $sqlref->[1] }, $param->{$_}) : ""} keys %$param;
        $sqlMoji = sprintf("UPDATE $self->{table} SET %s =?  WHERE tmpltfile_id= '$self->{columns}->{tmpltfile_id}';", join('=?,', @{ $sqlref->[0] }));
        $rv      = $self->executeQuery($sqlMoji, $sqlref->[1]);

        return $rv; # return value
    }
}


sub maxTmpltFileID {
    my $self = shift;
    my $maxid = $self->{this_dbh}->selectrow_array("SELECT MAX(tmpltfile_id) FROM $self->{table};");
    return ($maxid);
}


#******************************************************
# @desc		テンプレート名を条件にテンプレートコードを取得
#           デバッグモード用に明示的にテンプレートファイルのID指定対応 20100304
# @param	obj    {}
# @param	
# @return	
#******************************************************
sub fetchTmpltCodeByTmpltName {
    my ($self, $arg) = @_;

    my $tmplt_name;

    if (!$arg) {
        $tmplt_name = 'error';
    }
    else {
        $tmplt_name = ( "" eq $arg->{tmplt_name} ) ? 'error' : $arg->{tmplt_name};
    }

    my $column =
        ( 1 == $arg->{carrier} ) ? 'tmplt_docomo'   :
        ( 2 == $arg->{carrier} ) ? 'tmplt_softbank' :
        ( 3 == $arg->{carrier} ) ? 'tmplt_au'       :
                                   'tmplt_docomo'   ;

    my $obj;

    if ($arg->{debug} && $arg->{tmpltfile_id}) {
        my $tmpltfile_id = $arg->{tmpltfile_id};
        my $tmpobj = $self->getSpecificValues_LEFTJOINSQL(
                {
                    columns     => [$column,],
                    joinonSQL   => ['tmpltm_id', 'tmplt_id'],
                    whereSQL    => 'tmplt_name=? AND tmpltfile_id=?',
                    orderbySQL  => 'activation_date DESC',
                    limitSQL    => 1,
                    placeholder => [$tmplt_name, $tmpltfile_id],
                }
            );
         $obj = $tmpobj->{$column};
    }
    else {
        ## Modified memcachedのkeyを修正 2010/10/14
        my $cached_key = sprintf("%s%s_byName", $self->table, $column);
        $obj = $self->memcached()->get("$cached_key:$tmplt_name");

        if (!$obj) {
            my $tmpobj = $self->getSpecificValues_LEFTJOINSQL(
                {
                    columns     => [$column,],
                    joinonSQL   => ['tmpltm_id', 'tmplt_id'],
                    whereSQL    => 'tmplt_name=? AND activation_date <= NOW()',
                    orderbySQL  => 'activation_date DESC',
                    limitSQL    => 1,
                    placeholder => [$tmplt_name],
                }
            );
            $obj = $tmpobj->{$column};
            $self->memcached()->add("$cached_key:$tmplt_name", $obj);
        }
    }
    return $obj;
}


#******************************************************
# @desc		テンプレートIDを条件にテンプレートコードを取得
#           テンプレートのIDが無い場合は決め打ちでエラーページのID：：2を設定
# @param	arrayref    [ tmpltm_id carrier ]
# @param	
# @return	
#******************************************************
sub fetchTmpltCodeByTmpltID {
    my ($self, $arg) = @_;

    my $tmpltm_id;

    if (!$arg) {
        $tmpltm_id = 2;
    }
    else {
        $tmpltm_id = ( 0 < $arg->{tmpltm_id} ) ? $arg->{tmpltm_id} : 2;
    }

    my $column =
        ( 1 == $arg->{carrier} ) ? 'tmplt_docomo'   :
        ( 2 == $arg->{carrier} ) ? 'tmplt_softbank' :
        ( 3 == $arg->{carrier} ) ? 'tmplt_au'       :
                                   'tmplt_docomo'   ;

    ## Modified memcachedのkeyを修正 2010/10/14
    #my $cached_key = $column . '_byID';
    my $cached_key = sprintf("%s%s_byID", $self->table, $column);

    my $obj = $self->memcached()->get("$cached_key:$tmpltm_id");

    if (!$obj) {
        $obj = $self->getOneValueSQL(
            {
                column      => $column,
                whereSQL    => 'tmpltm_id=? AND activation_date <= NOW()',
                orderbySQL  => 'activation_date DESC',
                placeholder => [$tmpltm_id,],
            }
	    );
        $self->memcached()->add("$cached_key:$tmpltm_id", $obj);
    }

    return $obj;
}



1;
__END__
