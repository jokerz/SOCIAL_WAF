#******************************************************
# @desc      DataBaseを扱う基底クラス
# @package   MyClass::JKZDB
# @access    public
# @author    Iwahase Ryo
# @create    2008/03/31
# @update    2008/05/27    抽出条件にhaving句対応に
# @update    2008/06/04    memcachedを実装
# @update    2008/07/03    appendColumnRecordメソッド追加
# @update    2008/12/16    switchMRG_MyISAMTableメソッド追加
# @update    2009/02/03    メソッド名の最後は***SQLで終わるように統一
# @update    2009/02/12    リスティング処理も追加してJKZDBListクラスの削除
#                          getSpecificValuesSQLをリスティング処理を追加
# @update    2009/02/19    モジュールのコンパイルを必要なときだけのrequireに変更読み込み
# @update    2009/02/24    newの引数にテーブルが無い場合はDBハンドルだけをブレスする そのため
# @update    2009/02/24    上記の仕様変更のためにcreateCalenderTableメソッドが可能
# @update    2009/03/02    table名を返すtableメソッド追加
#
#
# @update    2009/09/29    version    1.04
# @update    2009/09/29    col_accessorを追加 アクセサ（現状はリスティングはまだ。）
# @update    2010/01/13    テーブル結合にちょっとだけ対応
# @update    2010/01/13    memcahcedアクセッサ追加
# @update    2010/07/09    dbhアクセッサ追加
# @update    2010/07/21    make_Setメソッド追加
# @version    1.02
# @version    1.03
# @version    1.04
# @version    1.05
#******************************************************
package MyClass::JKZDB;
use 5.008005;
use strict;
our $VERSION ='1.05';


#******************************************************
# @access    public
# @desc        コンストラクタ
# @param    
# @return    
# @author    
#******************************************************
sub new {
    my $class = shift;
    my $dbh   = shift;

    ## 取り合えづdbhandleだけは設定
    my $self = {
        this_dbh         => $dbh,
        table            => undef,
        table_join       => undef,
        sqlMoji          => "",
        columns          => {},
        columnslist      => {},
        columns_join     => {},
        columnslist_join => {},
        memcached        => undef,
        reccnt           => undef,
    };

    ## 引数がなければ上記ハッシュだけを返す
    my $table = shift || return (bless($self, $class));

    ## hashの順の保障
    require Tie::IxHash;
    tie %{$self->{columns}}, 'Tie::IxHash';
    tie %{$self->{columnslist}}, 'Tie::IxHash';

    ## memcachedの使用して高速化
    require MyClass::UsrWebDB;
    #my $memcached = MyClass::UsrWebDB::MemcacheInit();
    $self->{memcached} = MyClass::UsrWebDB::MemcacheInit();

    ## 先に結合テーブルの処理を実行
	if ('HASH' eq ref $table) {
        $self->{table}      = $table->{table};
        $self->{table_join} = $table->{table_join};

        tie %{$self->{columns_join}}, 'Tie::IxHash';
        tie %{$self->{columnslist_join}}, 'Tie::IxHash';

        #my $obj_join = $memcached->get("table:$self->{table_join}");
        my $obj_join = $self->{memcached}->get("table:$self->{table_join}");
        if (!$obj_join) {
            $obj_join = $dbh->selectcol_arrayref("SHOW COLUMNS FROM " . $self->{table_join} . ";");
            #$memcached->set("table:$self->{table_join}", $obj_join);
            $self->{memcached}->set("table:$self->{table_join}", $obj_join);
        }

        foreach my $column_join_key (@{ $obj_join }) {
            $self->{columns_join}->{$column_join_key}     = undef;
            $self->{columnslist_join}->{$column_join_key} = [];
        }
    }
    else {
        $self->{table} = $table;
    }

    #my $obj = $memcached->get("table:$self->{table}");
    my $obj = $self->{memcached}->get("table:$self->{table}");

    ## キャッシュが無ければ新規にDB接続してキャッシュオブジェクト入れる
    if (!$obj) {
        ## get table column name and set it
        $obj = $dbh->selectcol_arrayref("SHOW COLUMNS FROM " . $self->{table} . ";") ;
        ## キャッシュにセット
        #$memcached->set("table:$self->{table}", $obj);
        $self->{memcached}->set("table:$self->{table}", $obj);
    }

    foreach my $column_key (@{ $obj }) {
        $self->{columns}->{$column_key}     = undef;
        $self->{columnslist}->{$column_key} = [];
    }

    return (bless ($self, $class));
}


#******************************************************
# @desc      アクセッサ
# @return    データベースハンドル
#******************************************************
sub dbh {
    return shift->{this_dbh};
    #my $self = shift;
    #return $self->{dbh};
}

#******************************************************
# @desc      アクセッサ
# @return    memchaced
#******************************************************
sub memcached {
    my $self = shift;

    return $self->{memcached};
}


#******************************************************
# @desc        アクセッサ
# @return    現在のテーブル名を返す
#******************************************************
sub table {
    my $self = shift;

    return $self->{table};
}


#******************************************************
# @desc      アクセッサ
# @return    結合テーブル名を返す
#******************************************************
sub table_join {
    my $self = shift;

    return $self->{table_join};
}

=pod
sub serialize {
    my $self = shift;

    my $colname = shift;


    

require Storable;
Storable->import(qw( nfreeze thaw ));
    $self->{data} = thaw(unpack("u", $self->{columns}->{data}));
    $self->{serialized} = pack("u", nfreeze($self->attrData()));

}

sub thawColums {
    my $self = shift;

    require Storable;
    Storable->import(qw( thaw ));

    thaw(unpack("u", $self->col_accessor($_[0])));
}
=cut



#******************************************************
# @access   
# @desc     アクセッサ 引数にカラムを指定することで取得. 引数無しは全データを返す スカラ/ハッシュのレファレンス
# @desc     executeSelect実行後に呼び出すことが条件
# @param    str 
# @param    
# @return   scalar / hash referrence
#******************************************************
sub col_accessor {
    my $self = shift;

    return ($self->{columns}) unless @_;

    $self->{columns}->{$_[0]} = $_[1] if @_ > 1;

    return ($self->{columns}->{$_[0]});
}


#******************************************************
# @access   public
# @desc     任意条件によるレコード抽出処理
#           WhereStrに入った任意の条件によるSELECT処理を行ないます。
# @param    $WhereStr = 抽出条件 whereSQL, orderbySQL, limitSQL
# @return   レコードをhashで返します。(ハッシュのキーのカラム順ではないため、配列処理はNG)
#******************************************************
sub executeSelect {
    my $self      = shift;
    my $condition = shift;

    my @tablecolums;
    map { push(@tablecolums, $self->{table} . '.' . $_) } keys %{ $self->{columns} };
    my $sqlMoji = sprintf("SELECT %s FROM $self->{table}", join(",\n ", @tablecolums));

    ## if there is any condition reqired
    $sqlMoji .= " WHERE "    . $condition->{whereSQL}   if exists($condition->{whereSQL})   && $condition->{whereSQL} ne '';
    $sqlMoji .= " HAVING "   . $condition->{havingSQL}  if exists($condition->{havingSQL})  && $condition->{havingSQL} ne '';
    $sqlMoji .= " ORDER BY " . $condition->{orderbySQL} if exists($condition->{orderbySQL}) && $condition->{orderbySQL} ne '';
    $sqlMoji .= " LIMIT "    . $condition->{limitSQL}   if exists($condition->{limitSQL})   && $condition->{limitSQL} ne '';

    $self->executeQuery($sqlMoji, $condition->{placeholder});
}


#
# リスティング処理と通常処理の区別をつけるだけのダミーメソッド
#
sub executeSelectList {
    my $self      = shift;
    my $condition = shift;

    my @tablecolums;
    map { push(@tablecolums, $self->{table} . '.' . $_) } keys %{ $self->{columns} };
    my $sqlMoji = sprintf("SELECT %s FROM $self->{table}", join(",\n ", @tablecolums));

    $sqlMoji .= " WHERE "    . $condition->{whereSQL}   if exists($condition->{whereSQL})   && $condition->{whereSQL} ne '';
    $sqlMoji .= " HAVING "   . $condition->{havingSQL}  if exists($condition->{havingSQL})  && $condition->{havingSQL} ne '';
    $sqlMoji .= " ORDER BY " . $condition->{orderbySQL} if exists($condition->{orderbySQL}) && $condition->{orderbySQL} ne '';
    $sqlMoji .= " LIMIT "    . $condition->{limitSQL}   if exists($condition->{limitSQL})   && $condition->{limitSQL} ne '';

    $self->executeQuery($sqlMoji, $condition->{placeholder});
}


#******************************************************
# @access   public
# @desc     任意条件によるレコードのカウント
# @param    $WhereStr = 抽出条件 {columns,whereSQL,placeholder,}
# @return   integer
#******************************************************
sub getCountSQL {
    my $self      = shift;
    my $condition = shift;

    my $column  = exists($condition->{columns}) && $condition->{columns} ne '' ? $condition->{columns} : '*';
    my $sqlMoji = sprintf("SELECT COUNT(%s) FROM %s", $column, $self->{table});
    $sqlMoji    .= " WHERE " . $condition->{whereSQL} if exists($condition->{whereSQL}) && $condition->{whereSQL} ne '';

    my $records = $self->{this_dbh}->selectrow_array($sqlMoji, undef, @{ $condition->{placeholder} });

    return $records;
}


#******************************************************
# @access   public
# @desc     任意条件によるレコードの1カラム抽出処理
#           WhereStrに入った任意の条件によるSELECT処理を行ないます。
# @param    $WhereStr = 抽出条件 column, whereSQL, orderbySQL, limitSQL
# @return   レコードをhashで返します。(ハッシュのキーのカラム順ではないため、配列処理はNG)
#******************************************************
sub getOneValueSQL {
    my $self      = shift;
    my $condition = shift;
    unless (exists($condition->{column})) { warn "one column return must be selected \n"; return 0; }
    my $column = $self->{table} . '.' . $condition->{column} if exists $condition->{column};

    my $sqlMoji = sprintf("SELECT %s FROM $self->{table}", $column);
    $sqlMoji .= " WHERE "    . $condition->{whereSQL}   if exists($condition->{whereSQL})   && $condition->{whereSQL} ne '';
    $sqlMoji .= " HAVING "   . $condition->{havingSQL}  if exists($condition->{havingSQL})  && $condition->{havingSQL} ne '';
    $sqlMoji .= " ORDER BY " . $condition->{orderbySQL} if exists($condition->{orderbySQL}) && $condition->{orderbySQL} ne '';
    $sqlMoji .= " LIMIT "    . $condition->{limitSQL}   if exists($condition->{limitSQL})   && $condition->{limitSQL} ne '';

    $self->{columns}->{$condition->{column}} = $self->{this_dbh}->selectrow_array($sqlMoji, undef, @{ $condition->{placeholder} });

    return ($self->{columns}->{$condition->{column}});
}


#******************************************************
# @access   public
# @desc     任意条件によるレコードの指定したカラム抽出処理
#           WhereStrに入った任意の条件によるSELECT処理を行ないます。
# @param    columns | columnslist [1レコードの任意のカラム | 複数レコードの任意のカラム]
# @param    whereSQL
# @param    orderbySQL
# @param    limitSQL
# @return   レコードをhashで返します。(ハッシュのキーのカラム順ではないため、配列処理はNG)
# @return   レコードをhashの配列でかえします。$ref->{column_name}->[n]
#******************************************************
sub getSpecificValuesSQL {
    my $self      = shift;
    my $condition = shift;

    unless ( exists($condition->{columns}) || exists($condition->{columnslist}) ) { return 0; }

    my $keyref = exists($condition->{columns}) ? 'columns' : 'columnslist';

    my $sqlMoji = sprintf("SELECT %s FROM $self->{table}", join(",", @{ $condition->{$keyref} }));
    $sqlMoji .= " WHERE "    . $condition->{whereSQL}   if exists($condition->{whereSQL})   && $condition->{whereSQL} ne '';
    $sqlMoji .= " ORDER BY " . $condition->{orderbySQL} if exists($condition->{orderbySQL}) && $condition->{orderbySQL} ne '';
    $sqlMoji .= " LIMIT "    . $condition->{limitSQL}   if exists($condition->{limitSQL})   && $condition->{limitSQL} ne '';

    my $sth = $self->{this_dbh}->prepare($sqlMoji);
    if ($sth->execute(@{ $condition->{placeholder} }) < 1) { return undef; }

    ## Modified ここでリスティングとの処理分岐
    if (exists($condition->{columnslist})) {
        while ( my $ref = $sth->fetchrow_hashref ()) {
            map { push @{ $self->{columnslist}->{$_} }, $ref->{$_} } @{ $condition->{columnslist} };
        }
        $sth->finish();

        return $self->{columnslist};
    }

    $self->{columns} = $sth->fetchrow_hashref();
    $sth->finish();

    return ($self->{columns});
}


#******************************************************
# @desc     任意条件によりテーブル結合で指定したカラムレコードを抽出
# @param    columns | columnslist [1レコードの任意のカラム | 複数レコードの任意のカラム]
# @param    whereSQL
# @param    orderbySQL
# @param    limitSQL
# @return   レコードをhashで返します。(ハッシュのキーのカラム順ではないため、配列処理はNG)
# @return   レコードをhashの配列でかえします。$ref->{column_name}->[n]
#******************************************************
sub getSpecificValues_LEFTJOINSQL {
    my $self      = shift;
    my $condition = shift;

    unless ( exists($condition->{columns}) || exists($condition->{columnslist}) ) { return 0; }

    my $keyref = exists($condition->{columns}) ? 'columns' : 'columnslist';

    my $sqlMoji = sprintf("SELECT %s FROM %s LEFT JOIN %s ", join(",", @{ $condition->{$keyref} }), $self->table, $self->table_join);
    $sqlMoji   .= sprintf(" ON %s", join("=", @{ $condition->{joinonSQL} })) if exists($condition->{joinonSQL});
    $sqlMoji   .= " WHERE "    . $condition->{whereSQL}   if exists($condition->{whereSQL})   && $condition->{whereSQL} ne '';
    $sqlMoji   .= " ORDER BY " . $condition->{orderbySQL} if exists($condition->{orderbySQL}) && $condition->{orderbySQL} ne '';
    $sqlMoji   .= " LIMIT "    . $condition->{limitSQL}   if exists($condition->{limitSQL})   && $condition->{limitSQL} ne '';

    my $sth = $self->{this_dbh}->prepare($sqlMoji);
    if ($sth->execute(@{ $condition->{placeholder} }) < 1) { return undef; }

    ## Modified ここでリスティングとの処理分岐
    if (exists($condition->{columnslist})) {
        while ( my $ref = $sth->fetchrow_hashref ()) {
            map { push @{ $self->{columnslist}->{$_} }, $ref->{$_} } @{ $condition->{columnslist} };
        }
        $sth->finish();

        return $self->{columnslist};
    }

    $self->{columns} = $sth->fetchrow_hashref();
    $sth->finish();

    return ($self->{columns});
}


#******************************************************
# @access   public
# @desc     既存データを取得せずにカラム指定だけで
#           現在のデータに新データを追記する
# @param    obj
#           $condition->{column}
#           $condition->{value}
#           $condition->{whereSQL}
#           @{$condition->{placeholder}}
# @return   boolean
#******************************************************
sub appendColumnRecordSQL {
    my $self = shift;
    unless (@_) {
        ## 引数がない場合はエラー
        return;
    }
    ## メッセージのIDと更新ステータス
    my $condition = shift;

    my $sqlMoji = 'UPDATE ' 
                . $self->{table}
                . ' SET '
                . $condition->{column}
                . '=CONCAT('
                . $condition->{column}
                . ', "' .  $self->{this_dbh}->quote ($condition->{value}) . '")'
                ;
       $sqlMoji .= " WHERE " . $condition->{whereSQL} if exists($condition->{whereSQL}) && $condition->{whereSQL} ne '';

    my $rv = $self->executeQuery($sqlMoji);
    if ($rv eq '0E0') {

        return;
    }

    return 1;
}


#******************************************************
# @access   public
# @desc     bits に指定されたビットに対応する文字列のセットを返します
#           MAKE_SET($BITS, @LISTS)を自動生成する。
# @param    $bitは必須 $range対象とする最大値（64)デフォルトでは10。
#           eg都道府県なら47
# @return   複数の場合はカンマ区切りで返します。
#******************************************************
sub getSetLogValueSQL {
    my ($self, $bits) = @_;
    my $range = @_ ? shift : 10;
    ## Modified 2008/08/12
    #my $sqlMoji = sprintf ("SELECT MAKE_SET(%s, %s) ", $bits, join ' , ', map { log(2**$_)/log(2) } (0..$range));
    my $sqlMoji = sprintf("SELECT MAKE_SET(%s, %s) ", $bits, join ' , ', map { 2 ** $_ } (0..$range));
    my $sets    = $self->{this_dbh}->selectrow_array($sqlMoji);

    return ($sets);
}


#******************************************************
# @access   public
# @desc     指定したカラム値をmake_setしてカンマ区切りで返す
# @param    hashobj { columns => $column_name, whereSQL => "id=? AND xxx=?", placeholder => @{ $placeholder } }
# @return   
#******************************************************
sub make_Set {
    my ($self, $condition) = @_;

    my $sqlMoji = sprintf ("SELECT MAKE_SET(profile_bit, %s) FROM %s", join ' , ', map { 2**$_ } (0..10), $self->table );
       $sqlMoji .= " WHERE " . $condition->{whereSQL}   if exists($condition->{whereSQL}) && $condition->{whereSQL} ne '';

    my $sets    = $self->{this_dbh}->selectrow_array($sqlMoji, undef, @{ $condition->{placeholder} });

    return ($sets);
}


#******************************************************
# @access   
# @desc     レコード数を返します リスティング処理実行時に限る
# @param    
# @return   Count of Records
#******************************************************
sub countRecSQL {
    my $self = shift;

    return ($self->{reccnt});
}


#******************************************************
# @access   public
# @desc     データベースを変更ないし選択します。
# @param    %02d 月 つきの指定が無い場合全体になる。
# @return   
#******************************************************
sub switchDataBaseSQL {
    my $self = shift;
    unless (@_) {
        return;
    }
    my $month = shift;

    return $self->{table} .= sprintf("_%02d", $month);
}


#******************************************************
# @access   public
# @desc     MySQLマージテーブル利用時
# @param    obj {separater,value}
#           セパレータ、値
# @return   
#******************************************************
sub switchMRG_MyISAMTableSQL {
    my $self = shift;
    unless (@_) {

        return;
    }
    my $obj = shift;

    my ($s, $v);
    $s = exists($obj->{separater}) ? $obj->{separater} : "";
    $v = exists($obj->{value}) ? $obj->{value} : "";

    return $self->{table} .= sprintf("%s%d", $s, $v);
}

#******************************************************
# @access   public
# @desc     
# @param    
# @return   
#******************************************************
sub mysqlInsertIDSQL {
    my $self = shift;

    return $self->{this_dbh}->{mysql_insertid};
}


#******************************************************
# @access    public
# @desc        月のテーブルを生成
# @param    year month
# @return    lisitobject [1, '月'], [2, '火'], [3, '水']
#******************************************************
sub createCalenderTableSQL {
    my ($self, $sYear, $sMonth) = @_;

    my $obj = {};
    #*********************************
    # 対象月の日・曜日の生成
    #*********************************
    my $targetPeriod = sprintf("%04d-%02s-01", $sYear, $sMonth);
    my $getmonthsql = "SELECT DATE_FORMAT(LAST_DAY(?), '%d'), DAYOFWEEK(CONCAT(DATE_FORMAT(?, '%Y%m' ), '01')), DAYOFMONTH(?);";

    my ($last_day, $dayofweek, $thismonth) = $self->{this_dbh}->selectrow_array($getmonthsql, undef, $targetPeriod, $targetPeriod, $targetPeriod);
    my @YOBI = ('<font color=red>日</font>', '月', '火', '水', '木', '金', '<font color=blue>土</font>', );
    for (my $i = 0; $i < $last_day; $i++) {
        $obj->{yobi}->[$i] = $YOBI[(($dayofweek + ($i - 1))%7)];
    }
    my @tmpday = (1..$last_day);
    @ { $obj->{day} } = @tmpday;
    $obj->{LoopMONTH} = ($last_day-1);
    $obj->{MONTH} = $thismonth;

    return $obj;
}


1;
__END__
