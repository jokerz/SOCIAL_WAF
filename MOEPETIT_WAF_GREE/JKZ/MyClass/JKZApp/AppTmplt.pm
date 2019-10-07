#******************************************************
# @desc        テンプレート管理クラス
# @package   MyClass::JKZApp::AppTmplt
# @access    public
# @author    Iwahase Ryo
# @create    2009/02/23
# @update    2009/05/01        $q->charset("sjis");を追加で文字化けときちんとエスケープに対応
# @update    2009/08/26        editTmpltメソッドに不足機能処理追加 バグ修正
# @update    2009/08/26        tmpltTopMenuメソッド修正
# @update    2009/08/27        editTmpltメソッド修正
# @update    2009/08/27        updateTmpltメソッド修正
# @update    2010/09/28        キャッシュのネームスペース処理を変更
# @version    1.00
#******************************************************
package MyClass::JKZApp::AppTmplt;

use 5.008005;
our $VERSION = '1.00';

use strict;
use base qw(MyClass::JKZApp);
use MyClass::WebUtil;
use MyClass::UsrWebDB;
use MyClass::JKZDB::Tmplt;
use MyClass::JKZDB::TmpltFile;


#******************************************************
# @access    public
# @desc        コンストラクタ
# @param    
# @return    
#******************************************************
sub new {
    my ($class, $cfg) = @_;

    return $class->SUPER::new($cfg);
}


#******************************************************
# @access    public
# @desc        親クラスのメソッド
# @param    
#******************************************************
sub dispatch {
    my $self = shift;
    #$self->{q}->autoEscape(0);

    !defined($self->query->param('action')) ? $self->action('tmpltTopMenu') : $self->action();

    $self->SUPER::dispatch();
}


#******************************************************
# @access    public
# @desc        デフォルトメソッド（トップ）テンプレートIDがある場合はファイルデータを取得する
# @param    
#******************************************************
sub tmpltTopMenu {
    my $self = shift;
    my $q = $self->query();
    my $dbh = $self->getDBConnection();
    $self->setDBCharset('SJIS');

    my $obj = {};
    my $cachekey_tmpltlist  = $self->waf_name_space() . 'TmpltList';
    my $cachekey_tmpltmaxid = $self->waf_name_space() . 'TmpltMaxID';

    my $memcached = $self->initMemcachedFast();
    my $aryref = $memcached->get("$cachekey_tmpltlist");
    if (!$aryref) {
        my $myTmpltList = MyClass::JKZDB::Tmplt->new($dbh);
        $aryref = $myTmpltList->getSpecificValuesSQL({
            columnslist   => ['tmplt_id', 'tmplt_name', 'summary',],
            orderbySQL    => "tmplt_id"
        });

        ## 30分有効キャッシュ
        $memcached->add("$cachekey_tmpltlist", $aryref, 1800);

        ## 最大のIDを取得してキャッシュに入れる
        $obj->{max_tmplt_id} = $myTmpltList->maxTmpltID() + 1;
        $memcached->add("$cachekey_tmpltmaxid", $obj->{max_tmplt_id}, 1800);
    }

    $obj->{LoopTmpltMasterList} = $#{$aryref->{tmplt_id}};
    if (0 <= $obj->{LoopTmpltMasterList}) {
        map {
            my $i = $_;
            foreach my $key (keys %{ $aryref }) {
                $obj->{$key}->[$i] = $aryref->{$key}->[$i];
            }
            $obj->{IfSelectedMasterID}->[$i] = 1 if $q->param('tmplt_id') == $obj->{tmplt_id}->[$i];
            $obj->{selected_tmplt_name}      = $obj->{tmplt_name}->[$i] if $obj->{IfSelectedMasterID}->[$i];
            $obj->{selected_tmplt_summary}   = $obj->{summary}->[$i] if $obj->{IfSelectedMasterID}->[$i];
            $obj->{Encoded_selected_tmplt_summary} = $q->escape($obj->{selected_tmplt_summary});

		} 0..$obj->{LoopTmpltMasterList};
    }

    $obj->{max_tmplt_id} = $memcached->get("$cachekey_tmpltmaxid");

    ## テンプレートマスターのidが選択されている場合は、子レコードの取得を実行
    if ($q->param('tmplt_id') && 0 < $q->param('tmplt_id')) {

        $obj->{selected_tmplt_id}        = $q->param('tmplt_id');
        my ($fileobj, $max_tmpltfile_id) = $self->_fetchTmpltFileDataList($obj->{selected_tmplt_id});

        ## No data or fail fetching data
        if (!$fileobj) {
            return $obj;
        }

        $obj->{IfTmpltIDisSelected} = 1;
        $obj->{LoopTmpltFileList}   = $#{$fileobj->{tmpltfile_id}};

        map {
            my $i = $_;
            foreach my $key (keys %{ $fileobj }) {
                $obj->{$key}->[$i] = $fileobj->{$key}->[$i];
            }
            $obj->{tmpltfile_id}->[$i]    = sprintf("%06d", $obj->{tmpltfile_id}->[$i]);
            $obj->{activation_date}->[$i] = MyClass::WebUtil::formatDateTimeSeparator($obj->{activation_date}->[$i], { sepfrom => '-', septo => '/'});

        } 0..$obj->{LoopTmpltFileList};

        $obj->{max_tmpltfile_id} = sprintf("%06d", $max_tmpltfile_id);
    } else {
        $obj->{IfTmpltIDisNotSelected} = 1;
    }

    return $obj;
}


#******************************************************
# @access    
# @desc        テンプレートの更新 既存のテンプレート
#            ページに対してテンプレート追加処理も含む
# @param    int        $tmplt_id
# @param    int        $tmpltfile_id
# @return    
#******************************************************
sub editTmplt {
    my $self         = shift;
    my $q            = $self->query();
    my $obj          = {};
    my $tmplt_id     = $q->param('tmplt_id');
    my $tmpltfile_id = $q->param('tmpltfile_id');

    $obj->{tmplt_name} = $q->param('tmplt_name');
    $obj->{summary}    = $q->unescape($q->param('summary'));

    if (0 < $tmpltfile_id) {
        ( 'default' eq $obj->{tmplt_name} || 'member_default' eq $obj->{tmplt_name} || 'error' eq $obj->{tmplt_name} || 'FOOTER_HTML' eq $obj->{tmplt_name} || 'PANKUZU_HTML' eq $obj->{tmplt_name} )  ? $obj->{IfEditNotOK} =1 : $obj->{IfEditOK} = 1;

        my $TmpltFile = $self->_fetchTmpltData($tmplt_id, $tmpltfile_id);

        if(!$TmpltFile->{columns}) {
            $obj->{ERROR_MSG}         = MyClass::WebUtil::convertByNKF('-s', $self->ERROR_MSG("ERR_MSG11"));
            $obj->{IfNoTmpltFileData} = 1;

        } else {
            map { $obj->{$_} = $TmpltFile->{columns}->{$_} } keys %{ $TmpltFile->{columns} };
            $q->charset("sjis");
            $obj->{tmplt_docomo}   = $q->escapeHTML($TmpltFile->{columns}->{tmplt_docomo});
            $obj->{tmplt_softbank} = $q->escapeHTML($TmpltFile->{columns}->{tmplt_softbank});
            $obj->{tmplt_au}       = $q->escapeHTML($TmpltFile->{columns}->{tmplt_au});
            $obj->{ActivationDate} = $self->_createDateTimePopUP($obj->{activation_date});
            $obj->{tmpltfile_id}   = sprintf("%06d", $TmpltFile->{columns}->{tmpltfile_id});
        }
    } else {
        $obj->{tmpltm_id}    = $tmplt_id;
        $obj->{tmpltfile_id} = sprintf("%06d", $tmpltfile_id);
    }

    return $obj;
}


#******************************************************
# @access    public
# @desc        テンプレートの更新・TmpltM TmpltFileF
# @param    
# @return    
# @return    
#******************************************************
sub updateTmplt {
    my $self = shift;
    my $q    = $self->query();
    my $obj  = {};
    my $activation_date = sprintf("%4d-%02d-%02d %02d:%02d", $q->param('year'), $q->param('month'), $q->param('date'), $q->param('hour'), $q->param('min'));

    my $tmplt_id   = $q->param('tmplt_id');
    my $tmplt_name = $q->param('tmplt_name');
    my $summary    = $q->param('summary');

    my $updateMasterData = {
        tmplt_id   => $tmplt_id,
        tmplt_name => $tmplt_name,
        summary    => $summary,
    };

    my $updateFileData   = {
        tmpltfile_id    => $q->param('tmpltfile_id'),
        tmpltm_id       => $tmplt_id,
        activation_date => $activation_date,
        tmplt_docomo    => $q->param('tmplt_docomo'),
        tmplt_softbank  => $q->param('tmplt_softbank'),
        tmplt_au        => $q->param('tmplt_au'),
    };


    my $dbh = $self->getDBConnection();
    $self->setDBCharset('SJIS');
    my $Tmplt     = MyClass::JKZDB::Tmplt->new($dbh);
    my $TmpltFile = MyClass::JKZDB::TmpltFile->new($dbh);
    my $attr_ref  = MyClass::UsrWebDB::TransactInit($dbh);
    eval {
        $Tmplt->executeUpdate($updateMasterData);
        $TmpltFile->executeUpdate($updateFileData);
        $dbh->commit();
    };
    ## 失敗のロールバック
    if ($@) {
        $dbh->rollback();
        $obj->{ERROR_MSG} = $self->_ERROR_MSG('ERR_MSG8');
        $obj->{IfUpdateTmpltFileFail} = 1;
    } else {

    ## キャッシュから古いデータをなくすため全て削除 2009/06/08
        $self->flushAllFromCache();
        $obj->{IfUpdateTmpltFileSuccess} = 1;
    }
    MyClass::UsrWebDB::TransactFin($dbh,$attr_ref,$@);

    $self->action('tmpltTopMenu');
    return $self->tmpltTopMenu();
    #return $obj;
}


#******************************************************
# @access    
# @desc      ページとテンプレートの新規登録
#            ページに新規テンプレート追加の場合パラメータとしてtmplt_id
# @param     
# @return    
#******************************************************
sub registTmplt {
    my $self = shift;
    my $q    = $self->query();
    my $obj  = {};

#**************************************
# 暫定的にむりやり修正→そのうちに書き直すこと 2009/08/27
#**************************************

    my $insertID = undef;

    if ($q->param('tmplt_id') && 0 < $q->param('tmplt_id')) {
        $insertID = $q->param('tmplt_id');
    }

    my $dbh = $self->getDBConnection();
    $self->setDBCharset('SJIS');

    my $Tmplt     = MyClass::JKZDB::Tmplt->new($dbh);
    my $TmpltFile = MyClass::JKZDB::TmpltFile->new($dbh);
    ## トランザクション開始
    my $attr_ref  = MyClass::UsrWebDB::TransactInit($dbh);

    my $activation_date = sprintf("%4d-%02d-%02d %02d:%02d", $q->param('year'), $q->param('month'), $q->param('date'), $q->param('hour'), $q->param('min'));
    my $insertDataF = {
        tmpltfile_id    => -1,
        status_flag     => 2,
        activation_date => $activation_date,
        tmplt_docomo    => $q->param('tmplt_docomo'),
        tmplt_softbank  => $q->param('tmplt_softbank'),
        tmplt_au        => $q->param('tmplt_au'),
    };

    eval {

        if ( defined($insertID) ) {
            $insertDataF->{tmpltm_id} = $insertID;
        } else {

            my $insertDataM = {
                tmplt_id    => -1,
                status_flag => 2,
                tmplt_name  => $q->param('tmplt_name'),
                summary     => $q->param('summary'),
            };

            $Tmplt->executeUpdate($insertDataM);
            $insertDataF->{tmpltm_id} = $Tmplt->mysqlInsertIDSQL();
        }

        $TmpltFile->executeUpdate($insertDataF);

        $dbh->commit();
    };

    ## 失敗のロールバック
    if ($@) {
        $dbh->rollback();
        $obj->{ERROR_MSG}         = $self->_ERROR_MSG('ERR_MSG8');
        $obj->{IfRegistTmpltFail} = 1;
    } else {
        $obj->{IfRegistTmpltSuccess} = 1;
        ## テンプレートのキャッシュデータの更新が必要だから削除しておく
        my $cachekey_tmpltlist  = $self->waf_name_space() . 'TmpltList';
        my $cachekey_tmpltmaxid = $self->waf_name_space() . 'TmpltMaxID';
        my $memcached           = $self->initMemcachedFast();
        $memcached->delete("$cachekey_tmpltlist");
        $memcached->delete("$cachekey_tmpltmaxid");

    }

    MyClass::UsrWebDB::TransactFin($dbh,$attr_ref,$@);

    return $obj;
}


#******************************************************
# @access    private
# @desc        テンプレートマスターのテンプレートIDからファイル情報を取得
# @param    string        $tmplt_id
# @return    listobject  @$array
# @return    int            $max_id
#******************************************************
sub _fetchTmpltFileDataList {
    my $self            = shift;
    my $tmplt_id        = shift || return undef;
    my $dbh             = $self->getDBConnection();
    my $myTmpltFileList = MyClass::JKZDB::TmpltFile->new($dbh);

    my $obj = $myTmpltFileList->getSpecificValuesSQL({
        columnslist => ['tmpltfile_id', 'activation_date',],
        whereSQL    => "tmpltm_id=?",
        orderbySQL  => "tmpltfile_id DESC",
        placeholder => [$tmplt_id],
    });
    my $max_tmpltfile_id = $myTmpltFileList->maxTmpltFileID() + 1;

    return ($obj, $max_tmpltfile_id);
}


#******************************************************
# @access   private
# @desc     テンプレートファイル情報を取得
# @param    string        $tmplt_id
# @param    string        $tmpltfile_id
# @return   object        $hash
#******************************************************
sub _fetchTmpltData {
    my $self = shift;
    my ($tmplt_id, $tmpltfile_id) = @_;

    $self->setDBCharset('SJIS');
    my $dbh = $self->getDBConnection();
    my $myTmpltFile = MyClass::JKZDB::TmpltFile->new($dbh);

    if (
        !$myTmpltFile->executeSelect({
            whereSQL    => "tmpltfile_id=? AND tmpltm_id=?",
            placeholder => [$tmpltfile_id, $tmplt_id],
        })
        ) {
            return undef;
        }

    return $myTmpltFile;
}


#******************************************************
# @access    private
# @desc        yyyy-nn-dd HH:MMをばらしてHTMLﾎﾟｯﾌﾟアップﾒﾆｭｰにする
# @param    string        $datetime
# @return    
#******************************************************
sub _createDateTimePopUP {
    my $self = shift;
    my $datetime = shift;
    my ($yyyymmdd,$hhmim) = split(/ /,$datetime);
    my ($yyyy,$mm,$dd) = split(/-/, $yyyymmdd);
    my ($hh,$mim) = split(/:/, $hhmim);
    my @YEAR = (2009..2020);
    my @MON  = ('01'..'12');
    my @DATE = ('01'..'31');
    my @HOUR = ('01'..'23');
    my $MIM  = ['00','15','30','45'];
    my $ret;

    $ret .= $self->query->popup_menu(-name=>'year',-values=>[@YEAR],-default=>$yyyy)
         . '&nbsp;/&nbsp;'
         .    $self->query->popup_menu(-name=>'month',-values=>[@MON],-default=>$mm)
         . '&nbsp;/&nbsp;'
         .    $self->query->popup_menu(-name=>'date',-values=>[@DATE],-default=>$dd)
         . '&nbsp;&nbsp;'
         .    $self->query->popup_menu(-name=>'hour',-values=>[@HOUR],-default=>$hh)
         . '&nbsp;:&nbsp;'
         .    $self->query->popup_menu(-name=>'min',-values=>[@{$MIM}],-default=>$mim)
         ;

    return ($ret);
}


1;

__END__
