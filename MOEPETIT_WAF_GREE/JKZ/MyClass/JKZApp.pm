#******************************************************
# @desc      管理画面を扱う基底クラス
# @package   MyClass::JKZApp
# @access    public
# @author    Iwahase Ryo
# @create    2010/09/28
# @version   1.02
#******************************************************
package MyClass::JKZApp;

use 5.008005;
our $VERSION = '1.00';

use strict;

use MyClass::Session;

use MyClass::UsrWebDB;
use MyClass::WebUtil;
use MyClass::JKZHtml;
use MyClass::JKZDB::CmsMember;
use MyClass::JKZDB::Tmplt;

use Data::Dumper;
#******************************************************
# @access    public
# @desc        コンストラクタ
# @param    
# @return    
#******************************************************
sub new {
    my ($class, $cfg) = @_;

    my $self =  bless {}, $class;
    my $q      = CGI->new();

    $self->{cfg}    = $cfg;
    $self->{query}  = $q;
    $self->{action} = $q->param('action') || 'cmsTopMenu';
    $self->{dbh}    = undef;

    return $self;
}


#******************************************************
# @access    public
# @desc        run actionパラメーターの値により処理を決定
#            $myJKZ->run ($q->param ('action'));
# @param    $cgiQuery = CGI.pm
# @return    
# @author    
#******************************************************
sub run {
    my $self = shift;
    $self->connectDB();
## 管理画面のときだけMySQLのデバック情報出力 2010/02/26
    $self->{dbh}->trace(2, $self->cfg->param('TMP_DIR') . '/DBITrace.log');

    $self->setDBCharset('SJIS');
    $self->setMicrotime("t0");

    if ($self->_authorize()) {
       $self->dispatch();
      } else {
        $self->loginform();
    }
    $self->disconnectDB();
}


#******************************************************
# @access	
# @desc		アクセッサ
#******************************************************
sub cfg {
	my $self = shift;

	return $self->{cfg};
}


#******************************************************
# @access	
# @desc		アクセッサ
#******************************************************
sub query {
	my $self = shift;

	return $self->{query};
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
# @access	
# @desc		アクセッサ 引数があれば値をセット
#******************************************************
sub action {
    my $self = shift;

    $self->{action} = $_[0] if @_ > 0;

    return $self->{action};
}


#******************************************************
# @access    public
# @desc        getActionからaction属性値を取得するが、t属性があるならt+actionとしてフォーム名を決定
# @param    
#******************************************************
sub ActionForm {
    my $self = shift;

    return ( defined( $self->query->param('t') ) ? $self->action() . $self->query->param('t') : $self->action() );
}


#******************************************************
# @access    public
# @desc        dispatch actionパラメーターの値により処理を決定
# @param    $cgiQuery = CGI.pm
# @return    
# @author    
#******************************************************
sub dispatch {
    my $self   = shift;

    my $method = $self->action();
    #my $cookie = $self->getcookie2();

    $self->setMicrotime("t0");

    my $obj;
    $obj = $self->can($method) ? $self->$method() : $self->logout();

   #クライアント画像処理スクリプト
    #$obj->{MEDIACLIENTIMAGE_SCRIPTDATABASE_NAME} = $self->CONFIGURATION_VALUE('MEDIACLIENTIMAGE_SCRIPTDATABASE_NAME');
   ## 管理画面にサイト名を挿入
    $obj->{CMS_NAME} = MyClass::WebUtil::convertByNKF('-s', $self->cfg->param('CMS_NAME'));

    $obj->{name} = MyClass::WebUtil::convertByNKF('-s', $self->__name());

	$obj->{ITEMIMAGE_SCRIPTDATABASE_URL} = $self->CONFIGURATION_VALUE('ITEM_IMAGE_SCRIPTDATABASE_NAME');

    $self->_processCMSHtml($obj);

}


#******************************************************
# @access    public
# @desc        default page
# @param
# @return    
#******************************************************
sub cmsTopMenu {
    my $self = shift;
    my $q    = $self->query();
    my $obj  = {};

#$obj->{COOKIE} = $self->cfg->param('COOKIE_NAME');
my $cookie = $self->{cookie};
#$obj->{COOKIE} = $cookie;
$obj->{COOKIE} = $ENV{'HTTP_COOKIE'};#cookie;
#$obj->{COOKIE} = Dumper($cookie);
#$obj->{COOKIE} = $self->query->cookie( $self->cfg->param('COOKIE_NAME') );

    return $obj;
}


#******************************************************
# @access    public
# @desc        単にフォームを表示したいとき action値とt値のフォームを表示
# @param
# @return    
#******************************************************
sub form {
    my $self = shift;
}


#******************************************************
# @access    public
# @desc        loginform
# @param
# @return    
# @author    
#******************************************************
sub loginform {
    my $self = shift;
    my $obj  = {};
    $self->action('loginform');
    $obj->{nextaction} = 'default';
    $obj->{CMS_NAME}   = MyClass::WebUtil::convertByNKF('-s', $self->cfg->param('CMS_NAME'));

    $self->_processCMSHtml($obj);
}


#******************************************************
# @access    public
# @desc        logout
# @param
# @return    
# @author    
#******************************************************
sub logout {
    my $self = shift;

    my ($session_id, $login_name, $password);
    my $cookie = $self->query->cookie( $self->cfg->param('COOKIE_NAME') );
    ($session_id, $login_name, $password) = split(/::/, $cookie);

    my $dbh = $self->getDBConnection();
    if (defined ($session_id)) {
        my $sess_ref = MyClass::Session->open($dbh, $session_id);
        $sess_ref->delete();
        $sess_ref->close();
        $self->deletecookie();

        undef $sess_ref;
    }
    $self->action('loginform');

    return;
}


#******************************************************
# @access    private
# @desc        認証
# @param    
# @return    boolean
#******************************************************
sub _authorize {
    my $self        = shift;
    my $q           = $self->query();
    my $dbh         = $self->getDBConnection();
    my $cookie_name = $self->cfg->param('COOKIE_NAME');
    my $cookie      = $q->cookie($cookie_name);

    my ($sess_ref, $session_id, $sess_id, $level);
    my ($login_name, $password, $name);
    if ($cookie) {
        ($session_id, $login_name, $password, $name, $level) = split(/::/, $cookie);

#        unless ($session_id and $login_name and $password) {
#            $self->deletecookie();

#            return;
#        }

        if (defined($session_id)) {
            if (!defined ($sess_ref = MyClass::Session->open($dbh, $session_id))) {
                $self->deletecookie($session_id);

                return;
            }

            my $myCmsMember = MyClass::JKZDB::CmsMember->new($dbh);
            my %condition = (
                whereSQL => "uid = '" 
                            . $sess_ref->attr("uid")
                            . '\' AND status_flag = 2'
                );

            if ($myCmsMember->executeSelect(\%condition)) {
                $sess_ref->attr("uid", $myCmsMember->{columns}->{uid});
                $sess_ref->attr("login_name", $myCmsMember->{columns}->{login_name});
                $sess_ref->attr("login_password", $myCmsMember->{columns}->{login_password});
                $sess_ref->attr("name", $myCmsMember->{columns}->{name});
                $sess_ref->attr("level", $myCmsMember->{columns}->{level});
            }

            $self->setcookie($sess_ref);
            $sess_ref->close() if defined($sess_ref);

            return 1;
        }
    }
    else {
        ($login_name, $password) = ($q->param('login_name'), $q->param('login_password'));
        ## login情報チェック
        my $myCmsMember = MyClass::JKZDB::CmsMember->new($dbh);
        my %condition   = (
            whereSQL    => "login_name=? AND login_password=? AND status_flag=2" ,
            placeholder => ["$login_name","$password"],
        );

        if (!$myCmsMember->executeSelect(\%condition)) {

            return 0;
        }

        defined ($sess_ref = MyClass::Session->open($dbh, undef)) or warn "Could not create session: $MyClass::Session::errstr";

        $sess_ref->attr("uid", $myCmsMember->{columns}->{uid});
        $sess_ref->attr("login_name", $myCmsMember->{columns}->{login_name});
        $sess_ref->attr("login_password", $myCmsMember->{columns}->{login_password});
        $sess_ref->attr("name", $myCmsMember->{columns}->{name});
        $sess_ref->attr("level", $myCmsMember->{columns}->{level});
        $self->setcookie($sess_ref);

        $self->{uid}            = $sess_ref->attr("uid");
        $self->{login_name}     = $sess_ref->attr("login_name");
        $self->{login_password} = $sess_ref->attr("login_password");
        $self->{name}           = $sess_ref->attr("name");
        $self->{level}          = $sess_ref->attr("level");

        $sess_ref->close() if defined($sess_ref);

        return 1;
    }
}


#******************************************************
# @access    
# @desc        管理画面表示処理
# @param
# @return    htmlページ
# @author    
#******************************************************
sub _processCMSHtml {
    my $self = shift;
    my $obj  = shift;
    my ($tmplt, $databaseflg);
    my $q =  $self->query();

    if (@_) {
        ## shift template source(from database access);
        $tmplt       = shift;
        $databaseflg = 1;
    } else {
        $tmplt       = sprintf("%s/%s/%s", $self->cfg->param('TMPLT_DIR'), 'admin', $self->action());
        $databaseflg = 0;
    }

    my $myHtml = MyClass::JKZHtml->new($q, $tmplt, $databaseflg, 0);
    $myHtml->setfile() unless 0 < $databaseflg;

    my $benchref = {
        t0 => $self->{t0},
        t1 => $self->setMicrotime("t1"),
    };
    $obj->{BENCH_TIME} = MyClass::WebUtil::benchmarkMicrotime(2, $benchref);


    $myHtml->convertHtmlTags($obj);
    $myHtml->doPrintTags((!$self->{cookie} ? undef : $self->{cookie}));
}


#******************************************************
# @access    
# @desc        管理画面表示処理 表示を複数ページにする
# @param
# @return    
# @author    
#******************************************************
sub genNaviLink {
    my $self = shift;

    my ($url, $label, $offset) = @_;

    $url .= ";off=$offset";

    return ($self->query->a({-href=>"$url", -onclick=>"init();", -id=>"content"}, $label));
}


#************************************************************************************************************
# @desc        その他
#************************************************************************************************************


#******************************************************
# @access    public
# @desc        tTmpltM からデータを取得する
# @return    listobj  
#******************************************************
sub fetchTmplt {
    my $self = shift;

    my $cachekey_tmpltlist  = $self->waf_name_space() . 'TmpltList';
    my $cachekey_tmpltmaxid = $self->waf_name_space() . 'TmpltMaxID';

    my $memcached = $self->initMemcachedFast();
    my $obj       = $memcached->get("$cachekey_tmpltlist");
    if (!$obj) {
        my $dbh         = $self->getDBConnection();
        my $myTmpltList = MyClass::JKZDB::Tmplt->new($dbh);
        $obj = $myTmpltList->getSpecificValuesSQL({
            columnslist => ['tmplt_id', 'summary',],
            orderbySQL  => "tmplt_id"
        });
        ## 30分有効キャッシュ
        $memcached->add("$cachekey_tmpltlist", $obj, 1800);
        ## 最大のIDを取得してキャッシュに入れる
        $obj->{max_tmplt_id} = $myTmpltList->maxTmpltID() + 1;
        $memcached->add("$cachekey_tmpltmaxid", $obj->{max_tmplt_id}, 1800);

        undef($myTmpltList);
    }

    return $obj;
}


#******************************************************
# @desc		シリアライズオブジェクトからデータを取得
# @param	事前にシリアライズされて保存されていること
# @param	configuration value { CONFIGURATION_VALUE=>'', subject_id=> 'これは取得したいデータのid'}
# @return	arrayobj [{}] 対象リストのID順のarrayobjectです
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
# 
# @desc      カテゴリのIDと名称を返す
#            引数がない場合は全て。ある場合は対象のデータ カテゴリID順に
#            [
#              { category_id, category_name, status_flag }, 
#              { category_id, category_name, status_flag },
#            ]
# @return    arrayobj 引数なしの場合
# @return    hashobj 引数ありの場合
#******************************************************
sub getCategoryFromObjectFile {
    my $self = shift;

    my $objfile = $self->CONFIGURATION_VALUE('CATEGORYLIST_OBJ');
    my $obj;

    eval {
        $obj = MyClass::WebUtil::publishObj( { file=>$objfile } );
    };
    if ($@) {
        return undef;
    }
    ## 引数が無い場合は全てを返す
    return $obj unless @_;
    ## 引数がある場合 $obj->{category_id},{category_name}, {status_flag}
    return $obj->[$_[0]]->[$_[1]];
}


#******************************************************
# 
# @desc        サブカテゴリ・カテゴリのIDと名称を返す
#            引数がない場合は全て。ある場合は対象のデータ カテゴリID順→サブカテゴリID順
#              [ 
#               { category_id, subcategory_id, category_name, subcategory_name, status_flag }, # これはカテゴリIDが１でサブカテゴリIDが１
#               { category_id, subcategory_id, category_name, subcategory_name, status_flag }, # これはカテゴリIDが１でサブカテゴリIDが2
#              ],
# @param     int      $subcategory_id
# @return    arrayobj 引数なしの場合
# @return    hashobj 引数ありの場合
#******************************************************
=pod
sub getSubCategoryFromObjectFile {
    my $self = shift;

    my $objfile = $self->CONFIGURATION_VALUE('SUBCATEGORYLIST_OBJ');
    my $obj;

    eval {
        $obj = MyClass::WebUtil::publishObj( { file=>$objfile } );
    };
    if ($@) {
        return undef;
    }
    ## 引数が無い場合は全てを返す
    return $obj unless @_;
    ## 引数がある場合 $obj->{category_id},{subcategory_id}, {category_name}, {subcategory_name}, {status_flag}
    return $obj->[$_[0]];
}
=cut

#******************************************************
# @desc       小ｶﾃｺﾞﾘ サブカテゴリ・カテゴリのIDと名称を返す
#            引数がない場合は全て。ある場合は対象のデータ カテゴリID順→サブカテゴリID順
#              [ 
#               { category_id, subcategory_id, category_name, subcategory_name, status_flag }, # これはカテゴリIDが１でサブカテゴリIDが１
#               { category_id, subcategory_id, category_name, subcategory_name, status_flag }, # これはカテゴリIDが１でサブカテゴリIDが2
#              ],
# @param     int  $smallcategory_id
# @return    arrayobj 引数なしの場合
# @return    hashobj 引数ありの場合 { category_id, subcategory_id, smallcategory_id, category_name, subcategory_name, smallcategory_, status_flag },
#******************************************************
=pod
sub getSmallCategoryFromObjectFile {
    my $self = shift;

    my $objfile = $self->CONFIGURATION_VALUE('SMALLCATEGORYLIST_OBJ');
    my $obj;

    eval {
        $obj = MyClass::WebUtil::publishObj( { file=>$objfile } );
    };
    if ($@) {
        return undef;
    }
    ## 引数が無い場合は全てを返す
    return $obj unless @_;
    ## 引数がある場合 $obj->{category_id},{subcategory_id}, {category_name}, {subcategory_name}, {status_flag}
    return $obj->[$_[0]];
}
=cut


#******************************************************
# @access    public
# @desc        キャッシュオブジェクト取得メソッド
# @param    hash ref オブジェクトのキーと値
# @return    obj || undef
#******************************************************
sub getFromCache {
    my $self = shift;
    my $key  = shift || return (undef);

    my $memcached = $self->initMemcachedFast();
    my $obj       = $memcached->get($key);

    return $obj;
}


#******************************************************
# @access    public
# @desc        キャッシュオブジェクトを削除
# @param    key
#******************************************************
sub deleteFromCache {
    my $self = shift;
    my $key  = shift || return (undef);

    my $memcached = $self->initMemcachedFast();
    $memcached->delete($key);
}


#******************************************************
# @access    public
# @desc        キャッシュオブジェクトを全て削除　管理画面で情報更新時以外には使用しない
# @param    
#******************************************************
sub flushAllFromCache {
    my $self = shift;

    my $memcached = $self->initMemcachedFast();
    $memcached->flush_all;
}


#******************************************************
# @access    
# @desc        /modules/以下にあるモジュールを実行する。
# @param    
# @param    
# @return    
#******************************************************
sub rebuildCache {
    my $self = shift;
    my $q    = $self->query();

    my $obj  = {};
    my $module;

    if ($q->param('f')) {
        my $mod     = $q->param('f');
        my $moddir  = $self->CONFIGURATION_VALUE("MODULE_DIR");
        # 1 カテゴリ関係 2 オススメ商品  3 新着商品  4 ヤフーニュース  5  テンプレートなどのキャッシュクリア
        my @modules = $self->CONFIGURATION_VALUE("GENERATE_MEDIACATEGORY_LIST_MODULE", "GENERATE_RECOMMEND_PRODUCT", "GENERATE_LATEST_PRODUCT", "GENERATE_NEWS", "FLUSH_MEMCAHED_MODULE");

        $module = sprintf("%s/%s", $moddir, $modules[$mod-1]);

        if (-e $module) {
            system("cd $moddir && perl $module");
            $obj->{mod} = $module;
            #$obj->{rv} = `cd $moddir && perl $module`;
            $obj->{IfSuccess} = 1;
            $obj->{MSG}       = $modules[$mod-1];
        }
        $self->flushAllFromCache();
    }

    return $obj;
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

    return $obj;
}


#******************************************************
# @access    public
# @desc        プルダウン
# @param    hashobj {year=> year, month=>month, date=>date, range=>"-10,1", defaultvalue=>'2009-07-11' }
# @return    
#******************************************************
sub createPeriodPullDown {
    my $self    = shift;
    my $hashobj = shift || undef;
    # 対象年期間のデフォルト範囲
    $hashobj->{range} ||= "-1,1";

    my $q = $self->query();
    my $obj = {};

    ## Modified 2009/07/07
    my ($this_year, $this_month, $today) = split(/-/, exists($hashobj->{defaultvalue}) ? $hashobj->{defaultvalue} : (/-/, MyClass::WebUtil::GetTime(1)));
    $this_month = sprintf("%d", $this_month);
    $today      = sprintf("%d", $today);

    my @years   = map { $this_year+$_ } split/,/, $hashobj->{range};
    my @months  = (1..12);
    my @dates   = (1..31);
    $this_month = int ($this_month);
    $obj->{$hashobj->{year}}  = $q->popup_menu(-name=>$hashobj->{year}, -values=>[$years[0]..$years[-1]], -default=>$this_year) if exists($hashobj->{year});
    $obj->{$hashobj->{month}} = $q->popup_menu(-name=>$hashobj->{month}, -values=>[@months], -default=>$this_month) if exists($hashobj->{month});
    $obj->{$hashobj->{date}}  = $q->popup_menu(-name=>$hashobj->{date}, -values=>[@dates], -default=>$today) if exists($hashobj->{date});

    return ($obj);
}


#******************************************************
# @access    public
# @desc        月のテーブルを生成
# @param    dbhandle year month
# @return    
# @author    
#******************************************************
sub createMonthTable {
    my ($self, $sYear, $sMonth) = @_;

    my $obj = {};
    #*********************************
    # 対象月の日・曜日の生成
    #*********************************
    my $targetPeriod = sprintf("%04d-%02s-01", $sYear, $sMonth);
    ## 月の最後の日付・月の最初の曜日の数値 月の初日
    my $getmonthsql = "SELECT DATE_FORMAT(LAST_DAY(?), '%d'), DAYOFWEEK(CONCAT(DATE_FORMAT(?, '%Y%m' ), '01')), DAYOFMONTH(?);";
    my $dbh = $self->getDBConnection();
    my ($last_day, $dayofweek, $thismonth) = $dbh->selectrow_array($getmonthsql, undef, $targetPeriod, $targetPeriod, $targetPeriod);
    my @YOBI = ('<font style="color:red;">日</font>', '月', '火', '水', '木', '金', '<font style="color:blue;">土</font>', );
    for (my $i = 0; $i < $last_day; $i++) {
#        $obj->{yobi}->[$i] = $YOBI[(($dayofweek + ($i - 1))%7)];
        $obj->{yobi}->[$i] = MyClass::WebUtil::convertByNKF('-s',$YOBI[(($dayofweek + ($i - 1))%7)]);
        $obj->{cssstyle}->[$i] = 0 != $i % 2 ? 'focus2even' : 'focus2odd';
    }
    my @tmpday = (1..$last_day);
    @ { $obj->{day} } = @tmpday;
    $obj->{LoopMONTH} = ($last_day-1);
    $obj->{MONTH} = $thismonth;

    return $obj;
}


#******************************************************
# @access    
# @desc      データベースを接続
#
#******************************************************
sub connectDB {
    my $self = shift;
    $self->{dbh} = MyClass::UsrWebDB::connect(
        {
          dbaccount => $self->cfg->param('DATABASE_USER'),
          dbpasswd  => $self->cfg->param('DATABASE_PASSWORD'),
          dbname    => $self->cfg->param('DATABASE_NAME'),
        }
    );
    $self->{dbh}->trace(2, $self->cfg->param('TMP_DIR') . '/DBITrace.log') if 1 == $self->cfg->param('DEBUGMODE');

    return $self->{dbh};
}

#******************************************************
# @access    
# @desc      DB接続ハンドル
# @return    database handle
#******************************************************
sub getDBConnection {
    my $self = shift;
    return $self->{dbh};
}

#******************************************************
# @access    
# @desc        disconnect Database
#******************************************************
sub disconnectDB {
    my $self = shift;
    $self->{dbh}->disconnect();
}

#******************************************************
# @access    
# @desc      Set charset fro dbaccess
#******************************************************
sub setDBCharset {
    my ($self, $charset) = @_;
    return ($self->{dbh}->do("set names $charset"));
}


sub initMemcachedFast {
    my $self = shift;
#    $self->{memcachedfast} = MyClass::UsrWebDB::MemcacheInit();
#    return $self->{memcachedfast};
    return $self->memcached;
}

#******************************************************
# memcachedのイニシャライズ
#******************************************************
sub memcached {
    my $self = shift;
    $self->{memcached} = MyClass::UsrWebDB::MemcacheInit();

    return $self->{memcached};
}


#******************************************************
# @access	
# @desc		アクセスユーザーの基本情報 キャリアコード・キャリア名・subno
# @return	
#******************************************************
sub attrAccessUserData {
    my $self = shift;

    return (undef) unless @_;
	$self->{$_[0]} = $_[1] if @_ > 1;

    return ($self->{$_[0]});
}


sub setMicrotime {
    my $self = shift;
    $self->{$_[0]} = MyClass::WebUtil::benchmarkMicrotime(1) if @_;
    return ($self->{$_[0]});
}


#******************************************************
# @access	
# @desc		シリアライズオブジェクトのディレクトリ
#******************************************************
sub PUBLISH_DIR {
	my $self = shift;

	return ($self->{PUBLISH_DIR} = $self->{cfg}->param('SERIALIZEDOJB_DIR'));
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
# @access   public
# @desc     envconf.cfgに値を取得して配列で返す
# @param    key
# @return   array
#******************************************************
sub fetchArrayValuesFromConf {
    my $self = shift;
    unless (@_) { return; }

    my $name = shift;
    my @values = split(/,/, $self->cfg->param($name));

    return (@values);
}


#******************************************************
# @access   public
# @desc	    envconfからCommonUse.xxxMに対応するデータを取得
#           envconfの定数からデータを取得
#           配列で格納されている 引数の値に対応する値を返す
# @param    $string		envconf内の定数名
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
# @desc        設定ファイルのキーを引数に対応した値を取得
#            キーが存在しない場合undefを返す
#
#            引数が複数の場合(リストコンテキスト)は配列で値を返す
#            引数が単一の場合(スカラコンテキスト)はスカラで値を返す
#
# @param    char    $configrationkey
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
# @desc		cookieをセットします
#			引数はセッションのリファレンス
# @access	public
# @param	\%sess_ref
# @return	$cookie
#******************************************************
sub setcookie {
    my ($self, $sess_ref) = @_;

	$self->{cookie} = $self->query->cookie(
                        -name  => $self->cfg->param('COOKIE_NAME'),
                        -value => join('::', $sess_ref->session_id (), $sess_ref->attr("login_name"), $sess_ref->attr("login_password"), $sess_ref->attr("name"), $sess_ref->attr("level")),
                        -path  => '/',
#                        -domain => 'cmsdenismcd.up-stair.jp',
#                        -expires=> '+30m',
                     );

    ## 必要に応じてsessionデータを設定
    $self->attrAccessUserData("uid", $sess_ref->attr("uid"));
    $self->attrAccessUserData("login_name", $sess_ref->attr("login_name"));
    $self->attrAccessUserData("login_password", $sess_ref->attr("login_password"));
    $self->attrAccessUserData("name", $sess_ref->attr("name"));

    return ($self->{cookie});
}


#******************************************************
# @desc		cookieを取得します
#			引数はセッションのリファレンス
# @access	public
# @param	\%sess_ref
# @return	$cookie
#******************************************************
sub getcookie {
    my $self = shift;

    return ($self->{cookie});
}


#******************************************************
# @desc		cookieを取得します 2009/03/12
# @access	public
# @return	$cookie
#******************************************************
sub getcookie2 {
    my $self = shift;

    return ($self->query->cookie($self->cfg->param('COOKIE_NAME')));
}


#******************************************************
# @desc		cookieを削除します
#			引数はセッションのリファレンス
# @access	public
# @param	\%sess_ref
# @return	$cookie
#******************************************************
sub deletecookie {
    my $self = shift;
    $self->{cookie} = $self->query->cookie(
                        -name    => $self->cfg->param('COOKIE_NAME'),
                        -value   => '',
                        -path    => '/',
                        -expires => '-1d',
                    );

    return ($self->{cookie});
}


#******************************************************
# @access	public
# @desc		メールコンフィグレーション取得
# @param	
# @return	
#******************************************************
sub setMailConfig {
    my ($self, $type) = @_;

    my $table = $self->cfg->param('MAILCONF_TABLE');
    my $sql = "SELECT * FROM " . $table . " WHERE type=?";
    my $dbh = $self->getDBConnection();
    my $sth = $dbh->prepare ($sql);
    $sth->execute($type);
    my $ref = $sth->fetchrow_hashref();
    $sth->finish();

    return ($ref);
}


#******************************************************
# @access	public
# @desc		sendmailコマンドでメール送信
# @param	
# @return	
#******************************************************
sub _sendMail {
    my ($self, $userdata, $mailconf) = @_;

    $mailconf->{body} =~ s{ %& (.*?) &% }{ exists ( $userdata->{$1} ) ? $userdata->{$1} : ""}gex;

    my $mailcontents = {
        sendmail      => '/usr/sbin/sendmail',
        subject       => $mailconf->{subject},
        from          => $mailconf->{from_addr},
        contents_body => $mailconf->{body}
    };

    require MyClass::TransferMail;
    my $myMail = MyClass::TransferMail->new();
    $myMail->setMailContents($mailcontents);
    $myMail->setMailAddress($userdata->{mobilemailaddress}); # $ref->{from_addr}
    $myMail->SendMailSend();
}


#******************************************************
# @access    private
# @desc        現在のメソッド名
# @param    
# @return    method name
#******************************************************
sub _myMethodName {
    my @stack = caller(1);
    my $methodname = $stack[3];
    $methodname =~ s{\A .* :: (\w+) \z}{$1}xms;
    return $methodname;
}

#******************************************************
# @access    private
# @desc        呼び出しメソッド名やパッケージ名
# @param    
# @return    hashobj {package, filename, line, methodname}
#******************************************************
sub _myCallerMethodName {
    my $callerref;
    ( $callerref->{package}, $callerref->{filename}, $callerref->{line}, $callerref->{method} ) = caller(1);

    return $callerref;
}


#******************************************************
# @access
# @desc        Session/login_name/password from Cookie
# @return    
#******************************************************
sub __session_id {
    my $self = shift;

    return($self->{session_id});
}

sub __login_name {
    my $self = shift;

    return($self->{login_name});
}

sub __password {
    my $self = shift;

    return($self->{password});
}

sub __name {
    my $self = shift;
    return($self->{name});
}

sub __level {
    my $self = shift;

    return($self->{level});
}


#******************************************************
# @access	public
# @desc		JISX0401データベーステーブルから日本の都道府県情報を
#			取得。検索条件は郵便番号
# @param	
# @return	
#******************************************************
sub getPrefectureAddressByZipCode {
    my ($self, $zipcode) = @_;

    my $dbh = $self->getDBConnection();
    $dbh->do('SET NAMES SJIS');
    my $sql = "SELECT prefecture_id,prefecture,city,street FROM CommonUse.JIX0401 WHERE zipcode=?;";
    my $sth = $dbh->prepare($sql);
    #####@対応するzipcodeがないときは何も返さない
    if ($sth->execute ($zipcode)<1) { return (undef); }
    my $ref = $sth->fetchrow_hashref();
    $sth->finish();

	return ($ref);
}

#------------------------------------------->


1;

__END__
