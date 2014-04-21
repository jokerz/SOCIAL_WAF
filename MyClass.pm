#******************************************************
# @desc       フレームワークの基底クラス
#             サイト基本処理を実行
#             run.mpl→MyClass   account.mpl→MyClass::JKZAccount rg.mpl→MyClass::JKZRegistMember
# @package    MyClass
# @access     public
# @author     Iwahase Ryo
# @create     2009/11/02
# @version    1.04
# @update     2009/10/29 プラグイン機構導入
#                        mk_accesssor追加
#                        アクセッサメソッド削除
#                        getCgiQuery getAction
#                        bootstrapメソッド追加 
#             2009/11/05 メソッドnewをinitialize変更()
#                        run bootstrap dispatchの処理をプログラム実行コードに移行(Plugin機構の動作の問題)
# @update     2009/12/21 connectDBメソッド時のデバッグモード自動読み込み処理追加
# @update     2009/12/21 インデントのタブ停止。スペース4つに変更
# @update     2010/01/07 WebUtil→MyClass::WebUtil
# @update     2010/01/20 action_objを追加→やっぱやめ
# @update     2010/02/02 newにてmemcachedをイニシャライズ。initMemcachedFastはたんなるアクセッサに変更
# @update     2010/03/04 デバッグ用にテンプレートファイルを明示的に選択できるように修正
# @update     2010/06/10 waf_name_space追加
# @update     2010/10/06 fetchTmpltSummaryByTmpltName追加
# @update     2010/10/08 memcachedメソッド。$self->memcached->get $self->memcached->add $self->memcached->delete になる
# @update     2010/10/14 _getDBTmpltFileByNameメソッドにてのデータ取得部分をmemcachedの導入。以前のやり方だとDBHアクセスが発生していた。
# @update     2011/01/31 会員認証メソッド群をMyClass::JKZに移行 (Greeアプリの基底クラスとしても使用するため不要勝手サイト認証関連は勝手サイトクラスに移行)
# @update     2011/01/31 MyClass::JKZDB::Memberを削除 理由は会員認証自体がなくなっため
# @update     2011/05/26 778行目付近からステージング専用メソッド追加
#                        StprocessHtml
#                        _StgetDBTmpltFile
#                        _StgetDBTmpltFileByName
#                        _StgetTmpltFile
#                        StfetchTmpltSummaryByTmpltName
# @update     2011/11/21 createMonthTableを追加
# @update     2011/11/25 MyClass::JKZMemcachedクラスの導入
#******************************************************
package MyClass;
use 5.008005;
our $VERSION = '1.00';
use strict;

#******************************************************
# MyClass::Plugin  機構部分
# このクラスでuse Class::Componentしているから、PluginはMyClass::Pluginに設置する
#******************************************************
use Class::Component;
use base qw( Class::Accessor::Fast );
__PACKAGE__->mk_accessors( qw( cfg config query dbh ) ); ## bless するhashのキー ## memcachedを追加 2010/10/08
__PACKAGE__->load_components(qw/ Autocall::Autoload /);
__PACKAGE__->class_component_reinitialize( reload_plugin => 1 );

use CGI;
use YAML;

use MyClass::UsrWebDB;
use MyClass::JKZHtml;
use MyClass::WebUtil;
use MyClass::JKZSession;
use MyClass::JKZMobile;
use MyClass::JKZMemcached;

#use MyClass::JKZDB::Tmplt;
#use MyClass::JKZDB::TmpltFile;


use Data::Dumper;



#******************************************************
# @access    public
# @desc        コンストラクタ
# @param    
# @return    
#******************************************************
sub new {
    my ($class, $cfg) = @_;

    my $config  = $class->setup_configuration($cfg->param('PLUGIN_CONF'));
    my $q       = CGI->new();
    my $action  = defined($q->param('o')) ? $q->param('a') . '_' . $q->param('o') : $q->param('a');
=pod
    my $self    = $class->SUPER::new(
        {
            config     => delete $config->{plugin_config},
            cfg        => $cfg,
            query      => $q,
            action     => $action,
            memcached  => undef,
            dbh        => undef,
        }
    );
=cut
#=pod
    my $dbh     = MyClass::UsrWebDB::connect({ dbaccount => $cfg->param('DATABASE_USER'), dbpasswd => $cfg->param('DATABASE_PASSWORD'), dbname => $cfg->param('DATABASE_NAME'), });
    my $self    = $class->SUPER::new(
        {
            config     => delete $config->{plugin_config},
            cfg        => $cfg,
            query      => $q,
            action     => $action,
            memcached  => undef,
            dbh        => $dbh,
        }
    );
#=cut

    $self->config($config);
    $self->setup_plugins();

    return $self;
}


#******************************************************
# do nothing
#******************************************************
sub run {
}


#******************************************************
# @access    public
# @desc      memcacheなどに利用。複数のフレームがインストールされている場合に必要
# @param     データベース名と統一しておく
# @return    
#******************************************************
sub waf_name_space {
    my $self = shift;
    $self->{waf_name_space} = $self->cfg->param('WAF_NAME_SPACE');
    return $self->{waf_name_space};
}


#******************************************************
# @access    public
# @desc        携帯・環境変数セット
# @param
# @return    
#******************************************************
sub setAccessUserData {
    my $self  = shift;
    my $agent = MyClass::JKZMobile->new();
    $self->attrAccessUserData("carriercode", $agent->getCarrierCode());
    my $xhtmlflag = 1;
    0 < $xhtmlflag ? $self->attrAccessUserData("xhtml", $agent->xhtmlCapable()) : $self->attrAccessUserData("xhtml", undef);
}


#******************************************************
# アクセスしてる端末のキャリアコード 1 docomo 2 softbank 3 au
#******************************************************
sub user_carriercode {
    my $self = shift;
    $self->{carriercode} = $self->attrAccessUserData("carriercode");
    return ($self->{carriercode});
}


#******************************************************
# 会員
#******************************************************
sub user_is_member {
    my $self = shift;
    $self->{user_is_member} = $self->attrAccessUserData("user_is_member") || 0;
    return ($self->{user_is_member});
}


#******************************************************
# @access    
# @desc        アクセッサ 引数があれば値をセット
#
#******************************************************
sub action {
    my $self = shift;

    $self->{action} = $_[0] if @_ > 0;

    return $self->{action};
}


#******************************************************
# @desc      get tmplt_id from query or default is 1
# @param    
# @return   
#******************************************************
sub getTmpltID {
    my $self = shift;
    $self->{t} = $self->query->param('t') || 1;

    return $self->{t};
}


#******************************************************
# @desc     set tmplt_id to query
# @param    
# @return   
#******************************************************
sub setTmpltID {
    my ($self, $id) = @_;
    # Modified 2010/11/29
    #(1 > $id) ? $id = 24 : $id;
    $id ||= 24;

    $self->query->param(-name=>"t",-value=>$id);

    return $self->query->param('t');
}


#******************************************************
# @access  
# @desc    hook処理を追加
# @param   hash obj
# @param   hash obj { charset, cookie }
# @return  
#******************************************************
sub processHtml {
    my $self = shift;
    my $obj  = shift;
    my $opt  = shift; # 2011/11/21 追加
    my $q    = $self->query();

    ## 暫定処理 [ 0 : File system ] [ 1 : DB by ID] [2 : DB by Name ]
    my $TMPLT_BY_DATABASE = $self->cfg->param('DBTMPLT');
    #my $TMPLT_BY_DATABASE = 2;

    my $tmplt = 
        ( 1 == $TMPLT_BY_DATABASE ) ? $self->_getDBTmpltFile()       :
        ( 2 == $TMPLT_BY_DATABASE ) ? $self->_getDBTmpltFileByName() :
                                      $self->_getTmpltFile()         ;

    my $databaseflg = (0 < $TMPLT_BY_DATABASE) ? 1 : 0;

    my $myHtml = MyClass::JKZHtml->new($q, $tmplt, $databaseflg, 0);
    $myHtml->setfile() unless 0 < $databaseflg;

## PLUGIN HOOK 処理 BEGIN
    my @hooks = keys %{ $self->class_component_hooks };
    my $hook_regex = qr/If./;

    if ($databaseflg) {
        foreach my $hook (@hooks) {
            if ($tmplt =~ /__(?:$hook_regex$hook)__/) {
                my $tmpobj = $self->run_hook($hook);
                map { $obj->{$_} = $tmpobj->[0]->{$_} } keys %{ $tmpobj->[0] };
            }
        }
    } else {
        my $source_code = $myHtml->load_source_code();
        foreach my $hook (@hooks) {
            if ($source_code =~ /__(?:$hook_regex$hook)__/) {
                my $tmpobj = $self->run_hook($hook);
                map { $obj->{$_} = $tmpobj->[0]->{$_} } keys %{ $tmpobj->[0] };
            }
        }
    }
## PLUGIN HOOK 処理 END

    my $benchref = {
        t0 => $self->{t0},
        t1 => $self->setMicrotime("t1"),
    };

    $obj->{BENCHTIME} = MyClass::WebUtil::benchmarkMicrotime(2, $benchref);

    $myHtml->convertHtmlTags($obj);
    $myHtml->doPrintTags($opt);
}


#******************************************************
# @access    private
# @desc        select template code from database table
# @param    
# @return    
#******************************************************
sub _getDBTmpltFile {
    my $self    = shift;
    my $tmpltid = $self->getTmpltID() || 1;
    my $dbh     = $self->getDBConnection();

    $self->setDBCharset('SJIS');

    my $myTmpltFile = MyClass::JKZDB::TmpltFile->new($dbh);
## 今回のサイトは全キャリア共通テンプレートのため、ドコモエリアを利用する
#    $self->{tmplt}  = $myTmpltFile->fetchTmpltCodeByTmpltID({
#                              tmpltm_id => $tmpltid, carrier => $self->attrAccessUserData("carriercode")
#                      });
    $self->{tmplt}  = $myTmpltFile->fetchTmpltCodeByTmpltID({
                              tmpltm_id => $tmpltid, carrier => 1
                      });

    return $self->{tmplt};
}


#******************************************************
# @access    private
# @desc        select template code from database table by tmplt name
# @param    string $tmplt_name OR action
# @return    
#******************************************************
sub _getDBTmpltFileByName {
    my $self       = shift;
    my $tmplt_name = $_[0] || $self->action();

    ## Modified キャッシュ利用時点をここで実行
    ## memcachedのkeyは DENISMCD.tTmpltFileFtmplt_docomo_byName:tmplt_name
    my $namespace = sprintf("%s\.tTmpltFileFtmplt_docomo_byName:%s", $self->waf_name_space(), $tmplt_name);
    $self->{tmplt} = $self->memcached->get($namespace);

    unless($self->{tmplt}) {
        my $dbh = $self->getDBConnection();
        $self->setDBCharset('SJIS');
        my $myTmpltFile = MyClass::JKZDB::TmpltFile->new( $dbh, 1 );

       ## デバッグ用に指定の子テンプレートを明示的に取得
       ## 今回のサイトは全キャリア共通テンプレートのため、ドコモエリアを利用する
        $self->{tmplt}  =
            ( defined ($self->_debugTMPLT()) )
            ?
            $myTmpltFile->fetchTmpltCodeByTmpltName({ tmplt_name => $tmplt_name, carrier => $self->attrAccessUserData("carriercode"), debug => 1, tmpltfile_id => $self->_tmpltfile_id() })
            :
            $myTmpltFile->fetchTmpltCodeByTmpltName({ tmplt_name => $tmplt_name, carrier => 1 })
            ;
#           $myTmpltFile->fetchTmpltCodeByTmpltName({ tmplt_name => $tmplt_name, carrier => $self->attrAccessUserData("carriercode") })
    }

    ## Modified 20111101 ソフトバンクはコードをutfに変換
    $self->{tmplt} = MyClass::WebUtil::convertByNKF('-w', $self->{tmplt}) if 2 == $self->attrAccessUserData("carriercode");

    return $self->{tmplt};
}


#******************************************************
# @access    private
# @desc        select template from directory(tmplt code in a file)
# @param    
# @return    
# @update   2011/11/16
#******************************************************
sub _getTmpltFile {
    my $self        = shift;
    my $filename    = $_[0] || $self->action();
    my @carrier     = ('docomo', 'softbank', 'au', 'pc');
    $self->{tmplt}  = sprintf("%s/%s/%s", $self->cfg->param('TMPLT_DIR'), $carrier[$self->attrAccessUserData("carriercode")-1], $filename);

    return $self->{tmplt};
}


#******************************************************
# @desc     テンプレートのtmplt_nameからtmplt_summaryを取得する
# @param    
# @param    
# @return   string
#******************************************************
sub fetchTmpltSummaryByTmpltName {
    my $self        = shift;
    my $tmplt_name  = shift || return undef;
    my $namespame   = $self->waf_name_space() . 'TmpltSummary';
    my $obj          = $self->memcached->get("$namespame:$tmplt_name");

    if (!$obj) {
        $self->setDBCharset("sjis");
        my $tmplt   = MyClass::JKZDB::Tmplt->new($self->getDBConnection());
        $obj        = $tmplt->tmplt_summary($tmplt_name);
        $self->memcached->add("$namespame:$tmplt_name", $obj, 600);
        undef $tmplt;
    }

    return $obj;
}


#******************************************************
# 
#******************************************************
sub _debugTMPLT {
    my $self = shift;
    $self->{debugTMPLT} = $self->query->param('debug');

    return $self->{debugTMPLT};
}


#******************************************************
# テンプレートファイルのidを取得(デバッグ用)
#******************************************************
sub _tmpltfile_id {
    my $self = shift;
    $self->{tmpltfile_id} = $self->query->param('tf');

    return $self->{tmpltfile_id};
}


#******************************************************
# @desc     memcachedのイニシャライズ
#           環境にあわせてserversの値の変更が必要
# @param    hash obj ない場合UsrWebDB::MemcacheInitでの設定値がしようされる
#                {
#                    servers            => ["192.168.10.30:11211"],
#                    namespace          => '8008KUKUU:',
#                    compress_threshold => 10_000,
#                    compress_ratio     => 0.9,
#                }
#******************************************************
sub memcached {
    my $self = shift;
    #$self->{memcached} = MyClass::UsrWebDB::MemcacheInit();
    $self->{memcached} = MyClass::JKZMemcached->new();

    return $self->{memcached};
}

=pod
#******************************************************
# @access    Modified 2010/02/02
# @desc      Modified 2010/10/09
#******************************************************
sub initMemcachedFast {
    my $self = shift;
#    $self->{memcached} = MyClass::UsrWebDB::MemcacheInit();
#    return $self->{memcached};
    return $self->memcached;
}


#******************************************************
# memcachedからキャッシュデータを取得
#******************************************************
sub getFromCache {
    my $self        = shift;
    my $key         = shift || return (undef);
    my $obj         = $self->memcached->get($key);

    return $obj;
}


#******************************************************
# memcahcedからキャッシュデータを削除
#******************************************************
sub deleteFromCache {
    my $self        = shift;
    my $key         = shift || return (undef);

    $self->memcached->delete($key);
}
=cut

#******************************************************
# @desc        シリアライズオブジェクトからデータを取得
# @param    事前にシリアライズされて保存されていること
# @param    configuration value { CONFIGURATION_VALUE=>'', subject_id=> 'これは取得したいデータのid'}
# @return    arrayobj [{}] 対象リストのID順のarrayobjectです
#******************************************************
sub getFromObjectFile {
    my ($self, $param) = @_;

    return if !exists($param->{CONFIGURATION_VALUE});

    my $keyvalue = $param->{CONFIGURATION_VALUE};
    my $objfile  = $self->CONFIGURATION_VALUE($keyvalue);
    my $obj;

    eval {
        $obj = MyClass::WebUtil::publishObj( { file=>$objfile } );
    };
    if ($@) {
        return undef;
    }

    ## 引数が無い場合は全てを返す
    return $obj unless $param->{subject_id};

    return $obj->[$param->{subject_id}];
}


#******************************************************
# @access  
# @desc    エラーページの表示
#          エラーページテンプレートは決め打ち
#          tmplt_idの場合は：3 tmplt_nameの場合：error
# @param   
# @return  
#******************************************************
sub printErrorPage {
    my ($self, $msg) = @_;
    my $obj;
    $obj->{ERROR_MSG} = $msg;

    $self->action('error');

    #1 == $self->cfg->param('DBTMPLT') ? $self->setTmpltID("3") : $self->action('error');
    #$self->setTmpltID("24");
    #$self->action('error');

    return $obj;
}


sub USE_DBTMPLT {
    my $self = shift;
    return ($self->{DBTMPLT} = $self->cfg->param('DBTMPLT'));
}


sub ERROR_MSG {
    my $self = shift;
    if (@_) {
        my $constant_code = shift;
        return $self->cfg->param($constant_code);
    }

    return;
}


#******************************************************
# サイトのURL (ドメイン)
#******************************************************
sub MAIN_URL {
    my $self = shift;
    return ($self->{MAIN_URL} = $self->cfg->param('MAIN_URL'));
}


#******************************************************
# サイトトップのURL
#******************************************************
=pod コメントアウト 2011/10/03
sub MAINURL {
    my $self    = shift;
    my $timenow = MyClass::WebUtil::GetTime(4);

    $self->{MAINURL} = $self->cfg->param('UI_CONTROLER_NAME');

    $self->{MAINURL} .= 
            ( 1 == $self->attrAccessUserData("carriercode") ) ? '?guid=ON&'
            :
            ( 2 == $self->attrAccessUserData("carriercode") ) ? '?uid=1&'
            :
            ( 3 == $self->attrAccessUserData("carriercode") ) ? sprintf("?time=%s&", $timenow)
            :
            ""
           ;

    return $self->{MAINURL};
}
=cut

#******************************************************
# キャッシュオブジェクト格納ディレクトリ
#******************************************************
sub PUBLISH_DIR {
    my $self = shift;

    $self->{PUBLISH_DIR} = $self->cfg->param('SERIALIZEDOJB_DIR');
    return ($self->{PUBLISH_DIR});
}


#******************************************************#******************************************************#******************************************************#******************************************************#******************************************************


#******************************************************
# @access    
# @desc      データベースを接続
#
#******************************************************
sub dbh {
    my $self = shift;
=pod
    $self->{dbh} = MyClass::UsrWebDB::connect(
        {
          dbaccount => $self->cfg->param('DATABASE_USER'),
          dbpasswd  => $self->cfg->param('DATABASE_PASSWORD'),
          dbname    => $self->cfg->param('DATABASE_NAME'),
        }
    );
=cut
    ## Modified 2009/12/21
    #$self->{dbh}->trace(2, $self->cfg->param('TMP_DIR') . '/DBITrace.log') if 1 == $self->cfg->param('DEBUGMODE');
    $self->{dbh}->trace(2, $self->cfg->param('TMP_DIR') . '/DBITrace.log');
    return $self->{dbh};

}


#******************************************************
# @access    
# @desc      データベースを接続のエイリアス 不要だけど以前のプログラムとの互換性のため
#
#******************************************************
sub connectDB {
    my $self = shift;
    return $self->dbh();
}


#******************************************************
# @modified  2011/11/17
# @desc      DB接続ハンドル 不要 $self->dbhでよい
# @return    database handle
#******************************************************
sub getDBConnection {
    my $self = shift;
    return $self->{dbh};
}


#******************************************************
# @modified  2011/11/17
# @desc      DB接続ハンドル 不要 $self->dbh->disconnectでよい
# @desc        disconnect Database
#******************************************************
sub disconnectDB {
    my $self = shift;
    $self->dbh->disconnect();
}


#******************************************************
# @access    
# @desc      Set charset fro dbaccess
#******************************************************
sub setDBCharset {
    my ($self, $charset) = @_;
    return ($self->dbh->do("set names $charset"));
}


sub setMicrotime {
    my $self = shift;
    $self->{$_[0]} = MyClass::WebUtil::benchmarkMicrotime(1) if @_;
    return ($self->{$_[0]});
}


#******************************************************
# @access    public
# @desc        envconf.cfgに値を取得して配列で返す
# @param    key
# @return    array
#******************************************************
sub fetchArrayValuesFromConf {
    my $self = shift;
    unless (@_) { return; }

    my $name = shift;
    my @values = split(/,/, $self->cfg->param($name));

    return (@values);
}


#******************************************************
# @access
# @desc        envconfからCommonUse.xxxMに対応するデータを取得
#           envconfの定数からデータを取得
#           配列で格納されている 引数の値に対応する値を返す
# @param    $string        envconf内の定数名
# @param    $integer
# @return   $value
#******************************************************
sub fetchOneValueFromConf {
    my $self = shift;
    unless (@_) { return; }

    my ($name, $value) = @_;
    my $values = $self->{cfg}->param($name);
    my @tmplist = split(/,/, $values);

    return ($tmplist[$value]);
}


sub fetchValuesFromConf {
    my $self = shift;
    unless (@_) { return; }

    my ($name, $defaultvalue) = @_;
    my @values = split(/,/, $self->{cfg}->param($name));

    my $obj;
    no strict ('subs');
    $obj->{Loop . $name . List} = $#values;

    for  (my $i = 0; $i <= $#values; $i++) {
    $obj->{$name . Index}->[$i] = $i;
    $obj->{$name . Value}->[$i] = MyClass::WebUtil::convertByNKF('-s', $values[$i]);
    $obj->{$name . 'defaultvalue'}->[$i] = $defaultvalue == $i ? ' selected' : "";
    }

    return $obj;
}


#******************************************************
# @access   
# @desc      設定ファイルのキーを引数に対応した値を取得
#            キーが存在しない場合undefを返す
#            引数が複数の場合(リストコンテキスト)は配列で値を返す
#            引数が単一の場合(スカラコンテキスト)はスカラで値を返す
#
# @param     char    $configrationkey
# @return    char/undef    $configrationvalue
#******************************************************
sub CONFIGURATION_VALUE {
    my $self = shift;

    return undef if 1 > @_;

    my %CONFIGRATIONKEY = $self->cfg->vars();

    return (
        1 == @_
            ?
            ( $self->{CONFIGURATION_VALUE}->{$_[0]} = exists($CONFIGRATIONKEY{$_[0]}) ? $CONFIGRATIONKEY{$_[0]} : undef )
            :
            ( map { $self->{CONFIGURATION_VALUE}->{$_} = ( exists($CONFIGRATIONKEY{$_}) ) ? $CONFIGRATIONKEY{$_} : undef  } @_ )
    );
}


#******************************************************
# @access    
# @desc      アクセッサー 会員データ
#******************************************************
sub attrAccessUserData {
    my $self = shift;

    return (undef) unless @_;
    $self->{$_[0]} = $_[1] if @_ > 1;
    return ($self->{$_[0]});
}


#******************************************************
# 実行中のメソッド名取得
#******************************************************
sub _myMethodName {
    my @stack       = caller(1);
    my $methodname  = $stack[3];
    $methodname     =~ s{\A .* :: (\w+) \z}{$1}xms;

    return $methodname;
}


#******************************************************
# @desc      configuration fileから設定情報を取得
# @param    
# @return   
#******************************************************
sub setup_configuration {
    my ($class, $configfile) = @_;

    my $config = YAML::LoadFile($configfile);
    $class->class_component_reinitialize( reload_plugin => 1 );
    my $plugin_config = {};
    for my $plugin (@{ $config->{plugins} }) {
        $plugin_config->{$plugin->{module}} = $plugin->{config} || {};
    }
    $config->{plugin_config} = $plugin_config;

    $config;
}


#******************************************************
# @desc     __PACKAGE__->load_plugins(@plugins); をこのメソッド行う
# @param    
# @return   
#******************************************************
sub setup_plugins {
    my $self = shift;

    my @plugins;
    for my $plugin (@{ $self->config->{plugins} }) {
        push @plugins, $plugin->{module};
    }

    $self->load_plugins(@plugins);
    #$self->run_hook('plugin.fixup');
}



#******************************************************************************************************************************************************************
# ステージング用のMyClass.pmだけのメソッド サイトのテンプレートをステージング専用にする
# 2011/05/25
#******************************************************************************************************************************************************************

#******************************************************
# @access  
# @desc    hook処理を追加
# @param   
# @param   
# @return  
#******************************************************
sub StprocessHtml {
    my $self = shift;
    my $obj  = shift;
    my $q    = $self->query();

    ## 暫定処理 [ 0 : File system ] [ 1 : DB by ID] [2 : DB by Name ]
    my $TMPLT_BY_DATABASE = $self->cfg->param('DBTMPLT');
    #my $TMPLT_BY_DATABASE = 2;

    my $tmplt = 
        ( 1 == $TMPLT_BY_DATABASE ) ? $self->_StgetDBTmpltFile()       :
        ( 2 == $TMPLT_BY_DATABASE ) ? $self->_StgetDBTmpltFileByName() :
                                      $self->_StgetTmpltFile()         ;

    my $databaseflg = (0 < $TMPLT_BY_DATABASE) ? 1 : 0;

    my $myHtml = MyClass::JKZHtml->new($q, $tmplt, $databaseflg, 0);
    $myHtml->setfile() unless 0 < $databaseflg;

## PLUGIN HOOK 処理 BEGIN
    my @hooks = keys %{ $self->class_component_hooks };
    my $hook_regex = qr/If./;

    if ($databaseflg) {
        foreach my $hook (@hooks) {
            if ($tmplt =~ /__(?:$hook_regex$hook)__/) {
                my $tmpobj = $self->run_hook($hook);
                map { $obj->{$_} = $tmpobj->[0]->{$_} } keys %{ $tmpobj->[0] };
            }
        }
    } else {
        my $source_code = $myHtml->load_source_code();
        foreach my $hook (@hooks) {
            if ($source_code =~ /__(?:$hook_regex$hook)__/) {
                my $tmpobj = $self->run_hook($hook);
                map { $obj->{$_} = $tmpobj->[0]->{$_} } keys %{ $tmpobj->[0] };
            }
        }
    }
## PLUGIN HOOK 処理 END

    my $benchref = {
        t0 => $self->{t0},
        t1 => $self->setMicrotime("t1"),
    };

    $obj->{BENCHTIME} = MyClass::WebUtil::benchmarkMicrotime(2, $benchref);

    $myHtml->convertHtmlTags($obj);
    $myHtml->doPrintTags();

}


#******************************************************
# @access    private
# @desc        select template code from database table
# @param    
# @return    
#******************************************************
sub _StgetDBTmpltFile {
    my $self    = shift;
    my $tmpltid = $self->getTmpltID() || 1;

    my $dbh = $self->getDBConnection();
    $self->setDBCharset('SJIS');
    my $myTmpltFile = MyClass::JKZDB::StTmpltFile->new($dbh);
## 今回のサイトは全キャリア共通テンプレートのため、ドコモエリアを利用する
#    $self->{tmplt}  = $myTmpltFile->fetchTmpltCodeByTmpltID({
#                              tmpltm_id => $tmpltid, carrier => $self->attrAccessUserData("carriercode")
#                      });
    $self->{tmplt}  = $myTmpltFile->fetchTmpltCodeByTmpltID({
                              tmpltm_id => $tmpltid, carrier => 1
                      });

    return $self->{tmplt};
}


#******************************************************
# @access   private
# @desc     select template code from database table by tmplt name
# @param    string $tmplt_name OR action
# @return   
#******************************************************
sub _StgetDBTmpltFileByName {
    my $self       = shift;
    my $tmplt_name = $_[0] || $self->action();

    ## Modified キャッシュ利用時点をここで実行
    ## memcachedのkeyは DENISMCD.tTmpltFileFtmplt_docomo_byName:tmplt_name
    my $namespace = sprintf("%s\.tStTmpltFileFtmplt_docomo_byName:%s", $self->waf_name_space(), $tmplt_name);
    $self->{tmplt} = $self->memcached->get($namespace);

    unless($self->{tmplt}) {
        my $dbh = $self->getDBConnection();
        
        #$self->setDBCharset('SJIS');
        $self->setDBCharset('utf8');
        
        my $myTmpltFile = MyClass::JKZDB::StTmpltFile->new( $dbh, 1 );

       ## デバッグ用に指定の子テンプレートを明示的に取得
       ## 今回のサイトは全キャリア共通テンプレートのため、ドコモエリアを利用する
        $self->{tmplt}  =
            ( defined ($self->_debugTMPLT()) )
            ?
            $myTmpltFile->fetchTmpltCodeByTmpltName({ tmplt_name => $tmplt_name, carrier => $self->attrAccessUserData("carriercode"), debug => 1, tmpltfile_id => $self->_tmpltfile_id() })
            :
            $myTmpltFile->fetchTmpltCodeByTmpltName({ tmplt_name => $tmplt_name, carrier => 1 })
            ;
#           $myTmpltFile->fetchTmpltCodeByTmpltName({ tmplt_name => $tmplt_name, carrier => $self->attrAccessUserData("carriercode") })
    }

    ## Modified 20111101 ソフトバンクはコードをutfに変換
    $self->{tmplt} = MyClass::WebUtil::convertByNKF('-w', $self->{tmplt}) if 2 == $self->attrAccessUserData("carriercode");

    return $self->{tmplt};
}


#******************************************************
# @access    private
# @desc      select template from directory(tmplt code in a file)
# @param    
# @return   
#******************************************************
sub _StgetTmpltFile {
    my $self = shift;

    my @carrier = ('docomo', 'softbank', 'au');
    $self->{tmplt} = sprintf("%s/%s/%s", $self->cfg->param('TMPLT_DIR'), $carrier[$self->attrAccessUserData("carriercode")-1], $self->action);

    return $self->{tmplt};
}


#******************************************************
# @desc     テンプレートのtmplt_nameからtmplt_summaryを取得する
# @param    
# @param    
# @return   string
#******************************************************
sub StfetchTmpltSummaryByTmpltName {
    my $self        = shift;
    my $tmplt_name  = shift || return undef;
    my $namespame   = $self->waf_name_space() . 'StTmpltSummary';
    my $obj         = $self->memcached->get("$namespame:$tmplt_name");

    if (!$obj) {
        $self->setDBCharset("sjis");
        my $tmplt = MyClass::JKZDB::StTmplt->new($self->getDBConnection());
        $obj      = $tmplt->tmplt_summary($tmplt_name);
        $self->memcached->add("$namespame:$tmplt_name", $obj, 600);
        undef $tmplt;
    }

    return $obj;
}


1;
__END__
