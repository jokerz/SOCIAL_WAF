#******************************************************
# @desc      商品管理クラス(カテゴリも同居)
# @package   MyClass::JKZApp::AppContents
# @access    public
# @author    Iwahase Ryo
# @create    2010/09/30
# @update    
# @version   1.00
#******************************************************
package MyClass::JKZApp::AppContents;

use 5.008005;
our $VERSION = '1.00';
use strict;

use base qw(MyClass::JKZApp);

#use MyClass::JKZDB::Category;
#use MyClass::JKZDB::SubCategory;
use MyClass::JKZDB::Contents;
use MyClass::JKZDB::ContentsImage;
use MyClass::JKZDB::Item;
#use MyClass::JKZDB::ContentsSwf;

use Data::Dumper;

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
    !defined($self->query->param('action')) ? $self->action('contentsTopMenu') : $self->action();
    $self->SUPER::dispatch("IfAppContents");
}


#******************************************************
# @access    public
# @desc        商品管理トップメニュー
# @desc        だけど、基本的に検索はデフォルトで必要だから、searchContentsメソッド内で呼び出す
# @param    
#******************************************************
sub productTopMenu {
    my $self = shift;

    my $memcached = $self->initMemcachedFast();
    my $obj = $memcached->get("1MPCountContentsCategory");
    if (!$obj) {
        my $dbh = $self->getDBConnection();
        ($obj->{validCategory}, $obj->{invalidCategory}, $obj->{totalCategory})          = $dbh->selectrow_array("SELECT COUNT(IF(status_flag=2,category_id,NULL)) AS validCategory, COUNT(IF(status_flag=1,category_id,NULL)) AS invalidCategory, COUNT(category_id) AS totalCategory FROM 1MP.tCategoryM;");
        ($obj->{validSubCategory}, $obj->{invalidSubCategory}, $obj->{totalSubCategory}) = $dbh->selectrow_array("SELECT COUNT(IF(status_flag=2,subcategory_id,NULL)) AS validSubCategory, COUNT(IF(status_flag=1,subcategory_id,NULL)) AS invalidSubCategory, COUNT(subcategory_id) AS totalSubCategory FROM 1MP.tSubCategoryM;");
        ($obj->{validContents}, $obj->{invalidContents}, $obj->{totalContents})             = $dbh->selectrow_array("SELECT COUNT(IF(status_flag=2,contents_id,NULL)) AS validContents, COUNT(IF(status_flag=1,contents_id,NULL)) AS invalidContents, COUNT(contents_id) AS totalContents FROM 1MP.tContentsM;");

        my $sql = "SELECT s.category_name, s.subcategory_name, s.subcategory_id,
 COUNT(IF(p.status_flag=2, p.contents_id, NULL)) AS ACNT,
 COUNT(IF(p.status_flag=1, p.contents_id, NULL)) AS ANCNT,
 COUNT(p.contents_id) AS CNT
 FROM tSubCategoryM s, tContentsM p
 WHERE s.subcategory_id=p.subcategorym_id GROUP BY s.subcategory_id;";


        my $aryref = $dbh->selectall_arrayref($sql, { Columns => {} });
        $obj->{LoopContentsList} = $#{$aryref};

        map {
            my $cnt = $_;
            foreach my $key (keys %{ $aryref }) {
                $obj->{$key}->[$cnt] = $aryref->[$cnt]->{$key};
            }
            $obj->{cssstyle}->[$cnt] = 0 != $cnt % 2 ? 'focusodd' : 'focuseven';
            0 < $obj->{ACNT}->[$cnt]  ? $obj->{IfExistsACNT}->[$cnt]  = 1 : $obj->{IfNotExistsACNT}->[$cnt]  = 1;
            0 < $obj->{ANCNT}->[$cnt] ? $obj->{IfExistsANCNT}->[$cnt] = 1 : $obj->{IfNotExistsANCNT}->[$cnt] = 1;

        } 0..$obj->{LoopContentsList};

        $memcached->add("1MPCountContentsCategory", $obj, 600);
    }

    return $obj;
}


#******************************************************
# @access    public
# @desc        カテゴリリスト
# @param    
#******************************************************
sub fetchCategory {
    my $self      = shift;
    my $namespame = $self->waf_name_space() . '_categorylist';
    my $memcached = $self->initMemcachedFast();
    my $obj       = $memcached->get("$namespame");
    if (!$obj) {
        my $dbh = $self->getDBConnection();
        $self->setDBCharset('SJIS');

        my $cmsCategorylist = MyClass::JKZDB::Category->new($dbh);
        $cmsCategorylist->executeSelectList();
        map { $obj->{$_} = $cmsCategorylist->{columnslist}->{$_} } keys %{$cmsCategorylist->{columnslist}};

        $memcached->add("$namespame", $obj, 1800);

        undef($cmsCategorylist);
    }

    return $obj;
}


#******************************************************
# @desc     
# @param    
# @param    
# @return   arrayobj { LoopItemByItemTypeList => int, item_catorym_id => [], item_id => [] item_name => [] }
#******************************************************
sub fetchItemListByItemType {
    my ($self, $item_type) = @_;
    my $namespame = $self->waf_name_space() . '_item_by_item_type';
    my $obj       = $self->memcached->get("$namespame:$item_type");
    if (!$obj) {
        my $dbh = $self->getDBConnection();
        $self->setDBCharset('sjis');

        my $cmsItemlist = MyClass::JKZDB::Item->new($dbh);
        my $itemobj     = $cmsItemlist->fetchItemByItemType($item_type);
        if (0 <=  $#{ $itemobj }) {
            $obj->{LoopItemByItemTypeList} = $#{ $itemobj };
            map {
                my $cnt = $_;
                foreach my $key (keys %{ $itemobj }) {
                    $obj->{$key}->[$cnt] = $itemobj->[$cnt]->{$key};
                }
            } 0..$obj->{LoopItemByItemTypeList};
            $obj->{IfExistsItemByItemType} = 1;
        }
        else {
            $obj->{IfNotExistsItemByItemType} = 1;
        }
        $self->memcached->add("$namespame:$item_type", $obj, 1800);

        undef($cmsItemlist);
    }

    return $obj;
}


#******************************************************
# @desc     
# @param    
# @param    
# @return   arrayobj { LoopItemByItemTypeList => int, item_catorym_id => [], item_id => [] item_name => [] }
#******************************************************
sub fetchItemListByItemCategoryID {
    my ($self, $item_category_id) = @_;
    my $namespame = $self->waf_name_space() . '_item_by_item_category_id';
    my $obj       = $self->memcached->get("$namespame:$item_category_id");
    if (!$obj) {
        my $dbh = $self->getDBConnection();
        $self->setDBCharset('sjis');

        my $cmsItemlist = MyClass::JKZDB::Item->new($dbh);
        my $itemobj     = $cmsItemlist->fetchItemByItemCategoryID($item_category_id);
        if (0 <=  $#{ $itemobj }) {
            $obj->{LoopItemByItemCategoryList} = $#{ $itemobj };
            map {
                my $cnt = $_;
                foreach my $key (keys %{ $itemobj }) {
                    $obj->{$key}->[$cnt] = $itemobj->[$cnt]->{$key};
                }
            } 0..$obj->{LoopItemByItemCategoryList};
            $obj->{IfExistsItemByItemCategory} = 1;
        }
        else {
            $obj->{IfNotExistsItemByItemCategory} = 1;
        }
        $self->memcached->add("$namespame:$item_category_id", $obj, 1800);

        undef($cmsItemlist);
    }

    return $obj;
}



#************************************************************************************************************
# @desc        コンテンツデータ関連
#************************************************************************************************************


#******************************************************
# @access    public
# @desc        商品検索/商品管理デフォルト表示
# @param    
#******************************************************
sub searchContents {
    my $self = shift;
    my $q    = $self->query();
    my $obj  = {};
    my $cookie_name = $self->waf_name_space. 'CMSsearchContents';
    ## 検索フォーム内のカテゴリループと検索結果の商品ループで属性名がかぶるから検索フォームにはs_を付与
    my $skey = 's_';

#***************************
# カテゴリリスト
#***************************
    my $categorylist = $self->getCategoryFromObjectFile();
    $obj->{LoopCategoryList}  = $#{ $categorylist } - 1;
    map {
        $obj->{$skey . 'category_id'}->[$_]   = $categorylist->[$_+1]->{'category_id'};
        $obj->{$skey . 'category_name'}->[$_] = $categorylist->[$_+1]->{'category_name'};
    } 0..$obj->{LoopCategoryList};

#***************************
# サブカテゴリリスト
#***************************
    my $subcategorylist = $self->getSubCategoryFromObjectFile();
    $obj->{LoopSubCategoryList} = $#{ $subcategorylist } - 1;
    map {
        my $i = $_;
        $obj->{$skey . 'subcategory_id'}->[$i]   = $subcategorylist->[$i+1]->{'subcategory_id'};
        $obj->{$skey . 'subcategory_name'}->[$i] = $subcategorylist->[$i+1]->{'subcategory_name'};
    } 0..$obj->{LoopSubCategoryList};


    my $pulldown = $self->createPeriodPullDown({year=>"years", month=>"months", date=>"dates", range=>"-2,3"});
    map { $obj->{$_} = $pulldown->{$_} } keys %{$pulldown};
    $pulldown = $self->createPeriodPullDown({year=>"toyears", month=>"tomonths", date=>"todates", range=>"-2,3"});
    map { $obj->{$_} = $pulldown->{$_} } keys %{$pulldown};

    if ($q->param('search') and 'searchContents' eq $q->param('action')) {
        my $record_limit    = 20;
        my $offset          = $q->param('off') || 0;
        my $condition_limit = $record_limit+1;

        ## 共通SQL部分
=pod
        my $SQL = sprintf("SELECT
 c.contents_id,
 c.status_flag,
 c.charge_flag,
 c.point_flag,
 c.latest_flag,
 c.recommend_flag,
 LEFT(c.contents_name, 30) AS contents_name,
 c.categorym_id,
 c.subcategorym_id,
 LEFT(c.description, 30) AS description,
 c.tanka,
 c.point,
 c.registration_date,
 LEFT(sc.category_name, 8) AS category_name,
 LEFT(sc.subcategory_name, 8) AS subcategory_name
 FROM %s.tContentsM c LEFT JOIN %s.tSubCategoryM sc ON c.subcategorym_id=sc.subcategory_id", $self->waf_name_space, $self->waf_name_space);
=cut
        my $SQL = sprintf("SELECT
 c.contents_id,
 c.status_flag,
 c.latest_flag,
 LEFT(c.contents_name, 30) AS contents_name,
 c.categorym_id,
 c.subcategorym_id,
 LEFT(c.description, 30) AS description,
 c.registration_date,
 sc.category_name,
 sc.subcategory_name
 FROM %s.tContentsM c LEFT JOIN %s.tSubCategoryM sc ON c.subcategorym_id=sc.subcategory_id", $self->waf_name_space, $self->waf_name_space);

        ## 全レコード件数SQL
        my $MAXREC_SQL = sprintf("SELECT
 COUNT(c.contents_id)
 FROM %s.tContentsM c
 LEFT JOIN %s.tCategoryM ca ON c.categorym_id=ca.category_id", $self->waf_name_space, $self->waf_name_space);

        ## placeholderの初期化
        my @placeholder;

        ## Modified パラメータに検索があり、かつGETの場合はリンクからの遷移のためクッキーを参照 2009/05/29 BEGIN
        #***************************
        ## 検索条件SQLの生成
        #***************************
        if ($q->MethGet() && defined($q->param('off'))) {
            my $cookie = $q->cookie($cookie_name);
        ## SQL文をくっきーにカンマで区切って格納するとSQL文のPOW(2,←このカンマで検索失敗するからセミコロンに変更) 2010/02/10
        ## 下記563行目付近と連動
            #my ($whereSQL, $orderbySQL, $holder) = split (/,/, $cookie);
            my ($whereSQL, $orderbySQL, $holder) = split (/;/, $cookie);
            @placeholder = split(/ /, $holder) if $holder;
            $SQL .= sprintf(" WHERE %s", $whereSQL) if "" ne $whereSQL;
            $SQL .= $orderbySQL;
            $MAXREC_SQL .= sprintf(" WHERE %s", $whereSQL) if "" ne $whereSQL;

        }
        else {

            my @whereSQL;
            my ($contents_id, $sum_status_flag, $sum_charge_flag, $sum_point_flag, $sum_latest_flag, $sum_recommend_flag, $sum_categoryid, $sum_subcategory_id);
   ## 暫定処理2010/07/23
            my $subcategory_id = $q->param('subcategory_id');

            map { $sum_status_flag      += $_ } $q->param('status_flag');
            #map { $sum_charge_flag      += 2 ** $_ } $q->param('charge_flag');
            #map { $sum_charge_flag      += $_ } $q->param('charge_flag');
            #map { $sum_point_flag       += $_ } $q->param('point_flag');
            map { $sum_latest_flag      += $_ } $q->param('latest_flag');
            #map { $sum_recommend_flag   += $_ } $q->param('recommend_flag');
            map { $sum_categoryid       += 2 ** $_ } $q->param('category_id') if $q->param('category_id');
            map { $sum_subcategory_id   += 2 ** $_ } $q->param('subcategory_id') if $q->param('subcategory_id');

            #*********************************
            # 商品コード検索条件SQLの生成
            #*********************************
            if ($q->param('contents_id')) {
                my @fscontents_id;
                my $fsplaceholder;
                my @param = $q->param('contents_id');
                if (0 < $#param) {
                    @fscontents_id = @param;
                    $fsplaceholder = ',?' x $#fscontents_id;
                }
                else {
                    my $contents_id = $param[0];
                    $contents_id =~ s/^[\s|,]+//g;
                    $contents_id =~ s/[\s|,]+$//g;
                    $contents_id =~ s/[\s|,]+/,/g;
                    @fscontents_id = split(/,/, $contents_id);
                    $fsplaceholder = ',?' x $#fscontents_id;
                }
                push(@whereSQL, sprintf("c.contents_id IN (?%s)", $fsplaceholder));
                push(@placeholder, @fscontents_id);
            }

            #*********************************
            # 状態検索条件SQLの生成
            #*********************************
            if (3 > $sum_status_flag && 0 < $sum_status_flag) {
                push(@whereSQL, 'p.status_flag = ?');
                push(@placeholder, $sum_status_flag);
            }

            #*********************************
            # 新着表示検索条件SQLの生成
            #*********************************
            if (7 > $sum_latest_flag && 0 < $sum_latest_flag) {
                push(@whereSQL, 'c.latest_flag & ?');
                push(@placeholder, $sum_latest_flag);
            }
=pod
            #*********************************
            # おすすめ表示検索条件SQLの生成
            #*********************************
            if (3 > $sum_recommend_flag && 0 < $sum_recommend_flag) {
                push(@whereSQL, 'c.recommend_flag = ?');
                push(@placeholder, $sum_recommend_flag);
            }

            #*********************************
            # コンテンツの販売・配信検索条件SQLの生成
            # 現状は1=無料 2=pointで販売 4=現金で販売なので合計が７
            #*********************************
            if (7 > $sum_charge_flag && 0 < $sum_charge_flag) {
                push(@whereSQL, 'c.charge_flag & ?');
                push(@placeholder, $sum_charge_flag);
            }

            #*********************************
            # ポイント還元検索条件SQLの生成
            #*********************************
            if (3 > $sum_point_flag && 0 < $sum_point_flag) {
                push(@whereSQL, 'c.point_flag = ?');
                push(@placeholder, $sum_point_flag);
            }
=cut
            #*********************************
            # 全文検索条件SQLの生成
            #*********************************
            if ($q->param('keyword')) {
                my ($keyword, $exclusion, $multicondition);
                $obj->{Skeyword}  = $q->param('keyword');
                $obj->{Sexlusion} = $q->param('exclusion');
            ## Modified 上のはタイプミスっぽいのんで  2009
                $obj->{Sexclusion}= $q->param('exclusion');

                #*********************************
                # キーワードが複数の場合でAND検索時はスペースを+に置き換え
                #*********************************
                ## 全角スペースはカンマに変換
                $keyword = MyClass::WebUtil::convertSZSpace2C($q->param('keyword'));
                2 == $q->param('opt') ? $keyword =~ s!,! \+!g : $keyword =~ s!,! !g;

                #*********************************
                # 除外ｷｰﾜｰどの処理
                # 除外ｷｰﾜｰどがある場合は-()でくくる
                #*********************************
                $exclusion = $q->param('exclusion') ? ' -(' . $q->param('exclusion') . ')' : undef;

                #*********************************
                # マルチセクション全文検索構文生成
                #*********************************
                $multicondition = sprintf("*W1,2 %s%s ", $keyword, $exclusion);
                push(@whereSQL, 'MATCH(c.contents_name, c.description) AGAINST(? IN BOOLEAN MODE)');
                push(@placeholder, $multicondition);
            }

            #*********************************
            # カテゴリ検索条件SQLの生成 ビット演算に対応 2010/01/15
            #*********************************
            if (0 < $sum_categoryid) {
                push(@whereSQL, "POW(2, c.categorym_id) & ?");
                push(@placeholder, $sum_categoryid);
            }

            #*********************************
            # サブカテゴリ索条件SQLの生成
            #*********************************
            if ( 0 < $sum_subcategory_id ) {
                push(@whereSQL, "POW(2, c.subcategorym_id) & ?");
                push(@placeholder, $sum_subcategory_id);
            }

            #*********************************
            # 期間指定検索条件SQLの生成
            #*********************************
            if ($q->param('period_flag')) {
                push(@whereSQL, "DATE_FORMAT(p.registration_date, \"%Y-%m-%d\") BETWEEN ? AND ?");
                push(@placeholder, sprintf("%04d-%02d-%02d", $q->param('years'),$q->param('months'),$q->param('dates')));
                push(@placeholder, sprintf("%04d-%02d-%02d", $q->param('toyears'), $q->param('tomonths'), $q->param('todates')));
            }

            my @ORDERBY = ('c.registration_date', 'c.contents_id', 'c.status_flag', 'c.categorym_id',);
            my $orderbystr = $ORDERBY[$q->param('orderby')-1];

            #*********************************
            # SQLの生成
            #*********************************
            $SQL .= sprintf(" %s%s", (0 < @whereSQL ? "WHERE " : ""), join(' AND ', @whereSQL));
            $SQL .= " ORDER BY $orderbystr DESC";

            $MAXREC_SQL .= sprintf(" %s%s", (0 < @whereSQL ? "WHERE " : ""), join(' AND ', @whereSQL));

            ## 初回の検索時だけクッキーに検索条件挿入
            my $cookiesql   = join(' AND ', @whereSQL);
    ## カンマで区切るとSQL文と衝突するからセミコロンに変更 2010/02/10
            $cookiesql .= sprintf("\; ORDER BY %s DESC", $orderbystr);
            $cookiesql .= "\;@placeholder" if 0 < @placeholder;

            $self->{cookie} = $self->query->cookie(
                        -name  => $cookie_name,
                        -value => $cookiesql,
                        -path  =>    '/',
                        );
        }

        #*********************************
        ## SQL生成完了
        #*********************************
        $SQL .= " LIMIT $offset, $condition_limit;";

        my $dbh = $self->getDBConnection();
        $self->setDBCharset('SJIS');
        #*********************************
        # SENNAのmultisectionを有効にする
        #*********************************
        $dbh->do('SET SESSION senna_2ind=ON;');

    #*********************************
    ## ページ数表示リンクのナビ
    #*********************************
        my @navilink;

        my $maxrec = $dbh->selectrow_array($MAXREC_SQL, undef, @placeholder);

        ## レコード数が1ページ上限数より多い場合
        if ($maxrec > $record_limit) {

        my $url = 'app.mpl?app=AppContents;action=searchContents;search=1';

        ## 前へページの生成
            if (0 == $offset) { ## 最初のページの場合
                push(@navilink, "<font size=-1>&lt;&lt;前</font>&nbsp;");
            } else { ## 2ページ目以降の場合
                push(@navilink, $self->genNaviLink($url, "<font size=-1>&lt;&lt;前</font>&nbsp;", $offset - $record_limit));
            }

        ## ページ番号生成
            for (my $i = 0; $i < $maxrec; $i += $record_limit) {

                my $pageno = int ($i / $record_limit) + 1;

                if ($i == $offset) { ###現在表示してるﾍﾟｰｼﾞ分
                    push (@navilink, '<font size=+1>' . $pageno . '</font>');
                } else {
                    push (@navilink, $self->genNaviLink($url, $pageno, $i));
                }
            }

        ## 次へページの生成
            if (($offset + $record_limit) > $maxrec) {
                push (@navilink, "&nbsp;<font size=-1>次&gt;&gt;</font>");
            } else {
                push (@navilink, $self->genNaviLink($url, "&nbsp;<font size=-1>次&gt;&gt;</font>", $offset + $record_limit));
            }

            @navilink = map{ "$_\n" } @navilink;

            $obj->{pagenavi} = sprintf("<font size=-1>[全%s件 / %s件\表\示]</font><br />", $maxrec, $record_limit) . join(' ', @navilink);
        }
        else {
            $obj->{pagenavi} = sprintf("<font size=-1>[全%s件]</font><br />", $maxrec);
        }

        $obj->{pagenavi} = MyClass::WebUtil::convertByNKF('-s', $obj->{pagenavi});

        my $aryref = $dbh->selectall_arrayref($SQL, { Columns => {} }, @placeholder);

        $obj->{LoopSearchList} = ($record_limit == $#{$aryref}) ? $record_limit-1 : $#{$aryref};
        if (0 <= $#{$aryref}) {
            $obj->{IfExistsSearchList} = 1;
            map {
                my $i = $_;
                foreach my $key (keys %{ $aryref }) {
                    $obj->{$key}->[$i] = $aryref->[$i]->{$key};
                }
                $obj->{status_flagDescription}->[$i] = $self->fetchOneValueFromConf('STATUS', ($obj->{status_flag}->[$i]-1));
                $obj->{status_flagImages}->[$i]      = $self->fetchOneValueFromConf('STATUSIMAGES', ($obj->{status_flag}->[$i]-1));
                $obj->{latest_flagImages}->[$i]      = $self->fetchOneValueFromConf('STATUSIMAGES', ($obj->{latest_flag}->[$i]-1));
                $obj->{recommend_flagImages}->[$i]   = $self->fetchOneValueFromConf('STATUSIMAGES', ($obj->{recommend_flag}->[$i]-1));
                $obj->{description}->[$i]            = MyClass::WebUtil::escapeTags($obj->{description}->[$i]);
                $obj->{registration_date}->[$i]      =~ s!-!/!g;
                $obj->{registration_date}->[$i]      = substr($obj->{registration_date}->[$i] ,2, 9);

                $obj->{cssstyle}->[$i] = ( 0 == $i % 2 ) ? 'focusodd' : 'focuseven';

                ## Modified 管理画面のExtJSの正常動作のため IE対策
                $obj->{SetComma}->[$i] = $i < $obj->{LoopSearchList} ? ',' : '';

            } 0..$obj->{LoopSearchList};
        }
        else {
            $obj->{IfNotExistsSearchList} = 1;
        }
        $obj->{IfSearchExecuted} = 1;
    }

    return  $obj;
}


sub viewContentsList {
    my $self = shift;
    my $q    = $self->query();
    my $obj  = {};

#    if ($q->param('search') and 'searchContents' eq $q->param('action')) {
        my $record_limit    = 20;
        my $offset          = $q->param('off') || 0;
        my $condition_limit = $record_limit+1;

        my $SQL = sprintf("SELECT
contents_id
,status_flag
,latest_flag
,recommend_flag
,name AS c_name
,name_kana
,personality
,appearance 
,grade
,bloodtype
,year_of_birth
,month_of_birth
,date_of_birth
,constellation
,hobby
,message
,contentsimage_id
,painter
,registration_date
 FROM %s.tContentsM LIMIT %s, %s;", $self->waf_name_space, $offset, $condition_limit);

        my $MAXREC_SQL = sprintf("SELECT COUNT(contents_id) FROM %s.tContentsM", $self->waf_name_space);

        #if ($q->MethGet() && defined($q->param('off'))) {
        #    my $cookie = $q->cookie($cookie_name);
        #}

        my $dbh = $self->getDBConnection();
        $self->setDBCharset('SJIS');
$obj->{SQL} = $SQL;
    #*********************************
    ## ページ数表示リンクのナビ
    #*********************************
        my @navilink;

        my $maxrec = $dbh->selectrow_array($MAXREC_SQL);

        ## レコード数が1ページ上限数より多い場合
        if ($maxrec > $record_limit) {

        my $url = 'app.mpl?app=AppContents;action=searchContents;search=1';

        ## 前へページの生成
            if (0 == $offset) { ## 最初のページの場合
                push(@navilink, "<font size=-1>&lt;&lt;前</font>&nbsp;");
            } else { ## 2ページ目以降の場合
                push(@navilink, $self->genNaviLink($url, "<font size=-1>&lt;&lt;前</font>&nbsp;", $offset - $record_limit));
            }

        ## ページ番号生成
            for (my $i = 0; $i < $maxrec; $i += $record_limit) {

                my $pageno = int ($i / $record_limit) + 1;

                if ($i == $offset) { ###現在表示してるﾍﾟｰｼﾞ分
                    push (@navilink, '<font size=+1>' . $pageno . '</font>');
                } else {
                    push (@navilink, $self->genNaviLink($url, $pageno, $i));
                }
            }

        ## 次へページの生成
            if (($offset + $record_limit) > $maxrec) {
                push (@navilink, "&nbsp;<font size=-1>次&gt;&gt;</font>");
            } else {
                push (@navilink, $self->genNaviLink($url, "&nbsp;<font size=-1>次&gt;&gt;</font>", $offset + $record_limit));
            }

            @navilink = map{ "$_\n" } @navilink;

            $obj->{pagenavi} = sprintf("<font size=-1>[全%s件 / %s件\表\示]</font><br />", $maxrec, $record_limit) . join(' ', @navilink);
        }
        else {
            $obj->{pagenavi} = sprintf("<font size=-1>[全%s件]</font><br />", $maxrec);
        }

        $obj->{pagenavi} = MyClass::WebUtil::convertByNKF('-s', $obj->{pagenavi});

        my $aryref = $dbh->selectall_arrayref($SQL, { Columns => {} });

        $obj->{LoopSearchList} = ($record_limit == $#{$aryref}) ? $record_limit-1 : $#{$aryref};
        if (0 <= $#{$aryref}) {
            $obj->{IfExistsSearchList} = 1;
            map {
                my $i = $_;
                foreach my $key (keys %{ $aryref }) {
                    $obj->{$key}->[$i] = $aryref->[$i]->{$key};
                }
                $obj->{status_flagDescription}->[$i] = $self->fetchOneValueFromConf('STATUS', ($obj->{status_flag}->[$i]-1));
                $obj->{status_flagImages}->[$i]      = $self->fetchOneValueFromConf('STATUSIMAGES', ($obj->{status_flag}->[$i]-1));
                $obj->{latest_flagImages}->[$i]      = $self->fetchOneValueFromConf('STATUSIMAGES', ((log($obj->{latest_flag}->[$i]) / log(2))-1));
                $obj->{recommend_flagImages}->[$i]   = $self->fetchOneValueFromConf('STATUSIMAGES', ($obj->{recommend_flag}->[$i]-1));
                $obj->{description}->[$i]            = MyClass::WebUtil::escapeTags($obj->{description}->[$i]);
                $obj->{registration_date}->[$i]      =~ s!-!/!g;
                $obj->{registration_date}->[$i]      = substr($obj->{registration_date}->[$i] ,2, 9);

                $obj->{cssstyle}->[$i] = ( 0 == $i % 2 ) ? 'focusodd' : 'focuseven';

                ## Modified 管理画面のExtJSの正常動作のため IE対策
                $obj->{SetComma}->[$i] = $i < $obj->{LoopSearchList} ? ',' : '';

            } 0..$obj->{LoopSearchList};
        }
        else {
            $obj->{IfNotExistsSearchList} = 1;
        }
        $obj->{IfSearchExecuted} = 1;
#    }

    return  $obj;
}


#******************************************************
# @access    public
# @desc      コンテンツ詳細/編集
# @param    
#******************************************************
sub detailContents {
    my $self = shift;

    my $q = $self->query();
    #$q->autoEscape(0);

    my $obj = {};

    defined($q->param('md5key')) ? $obj->{IfConfirmContentsForm} = 1 : $obj->{IfModifyContentsForm} = 1;

    $obj->{md5key} = MyClass::WebUtil::createHash($self->__session_id(), 20);
    ## こちらの評価を先にする。パブリッシュするため
    if ($obj->{IfConfirmContentsForm}) {

           my @error;
        push @error, ' キャラクター名は5文字以上必要です。' if 5 > length($q->param('name'));
        push @error, ' キャラクター名カナが必要です。' if 5 > length($q->param('name_kana'));
        push @error, ' キャラクターの性格が必要です。' if 5 > length($q->param('personality'));
        push @error, ' キャラクターの外見が必要です。' if 5 > length($q->param('appearance'));
        push @error, ' キャラクターの趣味が必要です。' if 5 > length($q->param('hobby'));
        push @error, ' キャラクターから一言が必要です。' if 5 > length($q->param('message'));
        push @error, ' キャラクター絵師が必要です。' if 5 > length($q->param('painter'));
        push @error, ' 生年は4桁' if $q->param('year_of_birth') !~ /\d\d\d\d/;
#        push @error, ' 生月は1～12' if $q->param('month_of_birth') !~ /[1..12]/;
#        push @error, ' 生日は1～31' if $q->param('date_of_birth') !~ /[1..31]/;

        $obj->{contents_id}      = $q->param('contents_id');
        $obj->{status_flag}      = $q->param('status_flag');
        $obj->{latest_flag}      = $q->param('latest_flag');
        $obj->{recommend_flag}   = $q->param('recommend_flag');
        $obj->{name}             = $q->param('name');
       ## 管理画面ユーザーの変数と同じのため
        $obj->{cname} = $obj->{name};
        $obj->{name_kana}        = $q->param('name_kana');
        $obj->{personality}      = $q->param('personality');
        $obj->{appearance}       = $q->param('appearance');
        $obj->{grade}            = $q->param('grade');
        $obj->{bloodtype}        = $q->param('bloodtype') || 0;
        $obj->{year_of_birth}    = $q->param('year_of_birth');
        $obj->{month_of_birth}   = $q->param('month_of_birth');
        $obj->{date_of_birth}    = $q->param('date_of_birth');
        $obj->{constellation}    = $q->param('constellation');
        $obj->{hobby}            = $q->param('hobby');
        $obj->{message}          = $q->param('message');
        $obj->{contentsimage_id} = $q->param('contentsimage_id');
        $obj->{painter}          = $q->param('painter');
        $obj->{stopwatch_id}          = $q->param('stopwatch_id');


        if (@error) {
            $obj->{IfError}       = 1;
            map { $obj->{ERROR_MSG} .= MyClass::WebUtil::convertByNKF('-s', $_ )} @error;
            $obj->{IfErrorHistoryBack} = 1;
        ## コンテンツの状態
            2 == $obj->{status_flag}    ? $obj->{IfStatusFlagIsActive}      = 1 : $obj->{IfStatusFlagIsNotActive}    = 1;

            ## 新着表示の状態
            2 == $obj->{latest_flag}    ? $obj->{IfLatestFlagIsActive}      = 1 :
            4 == $obj->{latest_flag}    ? $obj->{IfLatestOnTopFlagIsActive} = 1 :
                                          $obj->{IfLatestFlagIsNotActive}   = 1 ;

            $obj->{bloodtypeDescription}     = MyClass::WebUtil::convertByNKF('-s', $self->fetchOneValueFromConf('BLOODTYPE', ($obj->{bloodtype} -1)));
            $obj->{constellationDescription} = MyClass::WebUtil::convertByNKF('-s', $self->fetchOneValueFromConf('CONSTELLATION', $obj->{constellation}));
            return $obj;
        }

        $obj->{IfSubmitOK} = 1;

=pod
        $obj->{name_kana}        = $q->escapeHTML($q->param('name_kana'));
        $obj->{personality}      = $q->escapeHTML($q->param('personality'));
        $obj->{appearance}       = $q->escapeHTML($q->param('appearance'));
        $obj->{grade}            = $q->escapeHTML($q->param('grade'));
        $obj->{bloodtype}        = $q->param('bloodtype') || 0;
        $obj->{year_of_birth}    = $q->escapeHTML($q->param('year_of_birth'));
        $obj->{month_of_birth}   = $q->escapeHTML($q->param('month_of_birth'));
        $obj->{date_of_birth}    = $q->escapeHTML($q->param('date_of_birth'));
        $obj->{constellation}    = $q->escapeHTML($q->param('constellation'));
        $obj->{hobby}            = $q->escapeHTML($q->param('hobby'));
        $obj->{message}          = $q->escapeHTML($q->param('message'));
        $obj->{contentsimage_id} = $q->param('contentsimage_id');
        $obj->{painter}          = $q->escapeHTML($q->param('painter'));
=cut

        #( $obj->{categorym_id}, $obj->{subcategorym_id}, $obj->{DecodedCategoryName}, $obj->{DecodedSubCategoryName} ) = split(/;/, $q->param('allcategory_id'));
        ( $obj->{categorym_id}, $obj->{DecodedCategoryName} ) = split(/;/, $q->param('allcategory_id'));

        $obj->{DecodedCategoryName}    = $q->unescape($obj->{DecodedCategoryName});
        #$obj->{DecodedSubCategoryName} = $q->unescape($obj->{DecodedSubCategoryName});

        #my $publish = $self->PUBLISH_DIR() . '/admin/' . $obj->{md5key};
        my $publish = sprintf("%s/admin/%s", $self->PUBLISH_DIR(), $q->param('md5key'));

        MyClass::WebUtil::publishObj({file=>$publish, obj=>$obj});

        ## コンテンツの状態
        2 == $obj->{status_flag}    ? $obj->{IfStatusFlagIsActive}      = 1 : $obj->{IfStatusFlagIsNotActive}    = 1;

        ## 新着表示の状態
        2 == $obj->{latest_flag}    ? $obj->{IfLatestFlagIsActive}      = 1 :
        4 == $obj->{latest_flag}    ? $obj->{IfLatestOnTopFlagIsActive} = 1 :
                                      $obj->{IfLatestFlagIsNotActive}   = 1 ;

        $obj->{bloodtypeDescription}     = MyClass::WebUtil::convertByNKF('-s', $self->fetchOneValueFromConf('BLOODTYPE', ($obj->{bloodtype}-1)));
        $obj->{constellationDescription} = MyClass::WebUtil::convertByNKF('-s', $self->fetchOneValueFromConf('CONSTELLATION', $obj->{constellation}));


    }
    elsif ($obj->{IfModifyContentsForm}) {
        my $contents_id = $q->param('contents_id');

        my $dbh = $self->getDBConnection();
        my $cmsContents = MyClass::JKZDB::Contents->new($dbh);
        if (!$cmsContents->executeSelect({whereSQL => "contents_id=?", placeholder => [$contents_id,]})) {
            $obj->{DUMP} = "データの取得失敗のまき";
        } else {
            map { $obj->{$_} = $cmsContents->{columns}->{$_} } keys %{$cmsContents->{columns}};

            $obj->{cname} = $obj->{name};
            $obj->{description} = $q->escapeHTML($obj->{description});

            2 == $obj->{status_flag}    ? $obj->{IfStatusFlagIsActive}    = 1 : $obj->{IfStatusFlagIsNotActive}    = 1;
            
            2 == $obj->{latest_flag}    ? $obj->{IfLatestFlagIsActive}      = 1 :
            4 == $obj->{latest_flag}    ? $obj->{IfLatestOnTopFlagIsActive} = 1 :
                                          $obj->{IfLatestFlagIsNotActive}   = 1 ;

            #$obj->{bloodtype}   = log($obj->{bloodtype}) / log(2);
            $obj->{IfTypeA}       = 1 if 1 == $obj->{bloodtype};
            $obj->{IfTypeAB}      = 1 if 2 == $obj->{bloodtype};
            $obj->{IfTypeB}       = 1 if 3 == $obj->{bloodtype};
            $obj->{IfTypeO}       = 1 if 4 == $obj->{bloodtype};
            my $constellationlist    = ( 0 < $obj->{constellation} )  ? $self->fetchValuesFromConf("CONSTELLATION", $obj->{constellation})   : $self->fetchValuesFromConf("CONSTELLATION");
            map { $obj->{$_} = $constellationlist->{$_}  } %{ $constellationlist };

            (0 < $obj->{stopwatch_id}) ? $obj->{IfExistsStopWatchID} = 1 : $obj->{IfNotExistsStopWatchID} = 1;
            # アイテムマスターから取得アイテムで実装系のリストを取得(コンプリートストップウォッチアイテム)
            my $stopwatchobj = $self->fetchItemListByItemCategoryID("11000");
            map { $obj->{$_} =  $stopwatchobj->{$_} } keys %{ $stopwatchobj };
            #$obj->{LoopItemByItemCategoryList} = $stopwatchobj->{LoopItemByItemCategoryList};
            map {
            $obj->{IfStopWatchIDIsSelected}->[$_] = 1 if $obj->{stopwatch_id} == ($obj->{item_categorym_id}->[$_] + $obj->{item_id}->[$_]);
            } 0..$obj->{LoopItemByItemCategoryList};
            
            

        }
        undef($cmsContents);

        #*********************************
        # 全サブカテゴリリスト取得 category_id;subcategory_id;EncodedCategoryName;EncodedSubCategoryName
        #*********************************

     ## ここは全データが存在するsamllcategoryからデータ取得に変更
=pod
        my $subcategorylist = $self->getSubCategoryFromObjectFile();
        $obj->{LoopAllCategoryList} = $#{ $subcategorylist } - 1;
        map {
            my $i = $_;
            $obj->{category_id}->[$i]             = $subcategorylist->[$i+1]->{'category_id'};
            $obj->{category_name}->[$i]           = $subcategorylist->[$i+1]->{'category_name'};
            $obj->{subcategory_id}->[$i]          = $subcategorylist->[$i+1]->{'subcategory_id'};
            $obj->{subcategory_name}->[$i]        = $subcategorylist->[$i+1]->{'subcategory_name'};
            $obj->{EncodedCategoryName}->[$i]     = $q->escape($obj->{category_name}->[$i]);
            $obj->{EncodedSubCategoryName}->[$i]  = $q->escape($obj->{subcategory_name}->[$i]);
            $obj->{IfSelectedSubCategoryID}->[$i] = 1 if $obj->{subcategory_id}->[$i] == $obj->{subcategorym_id};
        } 0..$obj->{LoopAllCategoryList};
=cut
        #*********************************
        # 画像情報の取得
        #*********************************
=pod
        my $ContentsImage = MyClass::JKZDB::ContentsImage->new($dbh);
        #if ($ContentsImage->checkRecord($contents_id)) {
        if ( $obj->{image_mime_type} = $ContentsImage->fetchMimeType($contents_id) ) {
            $obj->{IfExistsContentsImageImageData} = 1;
        } else {
            $obj->{IfNotExistsContentsImageImageData} = 1;
        }
=cut
=pod
        my $ContentsSampleImage = MyClass::JKZDB::ContentsSampleImage->new($dbh);
        #if ($ContentsSampleImage->checkRecord($contents_id)) {
        if ( $obj->{sample_image_mime_type} = $ContentsSampleImage->fetchMimeType($contents_id) ) {
            $obj->{IfExistsContentsSampleImageData} = 1;
        } else {
            $obj->{IfNotExistsContentsSampleImageData} = 1;
        }
=cut

    ## ビット値を元に戻しておく
        ## 今回はbitではないのでそのままでOK 2010/1/17
        #my $log_category_id = (log($obj->{categorym_id}) / log(2));
            #*********************************
            # flash情報の取得 暫定処理
            #*********************************
=pod
        my $sql = sprintf("SELECT mime_type, file_size, height, width FROM %s.tContentsSwfM WHERE contentsm_id=?;", $self->waf_name_space);
        $obj->{IfExistsFlashData} = 1 if ($obj->{swf_mime_type}, $obj->{file_size}, $obj->{height}, $obj->{width}) = $dbh->selectrow_array($sql, undef, $contents_id);
        unless ($obj->{IfExistsFlashData}) { $obj->{IfNotExistsFlashData} = 1; }
=cut
    }

    $obj->{IfSwfcontents} = 1;
    return $obj;
}


#******************************************************
# @access    public
# @desc      コンテンツ登録
# @param    
#******************************************************
sub registContents {
    my $self = shift;

    my $q = $self->query();
    $q->autoEscape(0);
    my $obj = {};

    #*********************************
    # カテゴリとサブカテゴリを関連付けてを取得
    #*********************************
=pod
    my $subcategorylist = $self->getSubCategoryFromObjectFile();
    $obj->{LoopAllCategoryList} = $#{ $subcategorylist } - 1;
    map {
        my $i = $_;
        $obj->{category_id}->[$i]              = $subcategorylist->[$i+1]->{'category_id'};
        $obj->{category_name}->[$i]            = $subcategorylist->[$i+1]->{'category_name'};
        $obj->{subcategory_id}->[$i]           = $subcategorylist->[$i+1]->{'subcategory_id'};
        $obj->{subcategory_name}->[$i]         = $subcategorylist->[$i+1]->{'subcategory_name'};
        $obj->{EncodedCategoryName}->[$i]      = $q->escape($obj->{category_name}->[$i]);
        $obj->{EncodedSubCategoryName}->[$i]   = $q->escape($obj->{subcategory_name}->[$i]);
    } 0..$obj->{LoopAllCategoryList};

    my $categorylist = $self->getCategoryFromObjectFile();
    $obj->{LoopCategoryList}  = $#{ $categorylist } - 1;
    map {
        $obj->{$skey . 'category_id'}->[$_]   = $categorylist->[$_+1]->{'category_id'};
        $obj->{$skey . 'category_name'}->[$_] = $categorylist->[$_+1]->{'category_name'};
    } 0..$obj->{LoopCategoryList};
=cut
    #*********************************
    # テンプレートリストを取得
    #*********************************
=pod 今回はコンテンツ専用テンプレートは不要
    my $tmpltobj = $self->fetchTmplt();
    $obj->{LoopTmpltMasterList} = $#{$tmpltobj->{tmplt_id}};
    if (0 <= $obj->{LoopTmpltMasterList}) {
        for (my $i = 0; $i <= $obj->{LoopTmpltMasterList}; $i++) {
            map { $obj->{$_}->[$i] = $tmpltobj->{$_}->[$i] } qw(tmplt_id summary);
            $obj->{EncodedSummary}->[$i] = $q->escape($obj->{summary}->[$i]);
            $obj->{IfTmpltID15}->[$i] = 1 if 15 == $obj->{tmplt_id}->[$i] ; # 絵文字・プチデコ・デコメ用のテンプレートをデフォルト選択
        }
    }
=cut
    return $obj;
}


#******************************************************
# @access    public
# @desc        コンテンツ情報更新/新規登録
# @param    
#******************************************************
sub modifyContents {
    my $self = shift;

    my $q = $self->query();
    my $obj = {};

    if (!$q->MethPost()) {
        $obj->{ERROR_MSG} = $self->ERROR_MSG("ERR_MSG18");
    }
=pod コンテンツデータに不要なものはハッシュから削除 2010/10/13
    my $updateData = {
        contents_id        => undef,
        status_flag        => undef,
        charge_flag        => undef,
        point_flag         => undef,
        latest_flag        => undef,
        recommend_flag     => undef,
        contents_name      => undef,
        categorym_id       => undef,
        subcategorym_id    => undef,
        description        => undef,
        genka              => undef,
        tanka              => undef,
        tanka_notax        => undef,
        teika              => undef,
        tmplt_id           => undef,
        point              => undef,
        stock              => undef,
    };
=cut

    my $updateData = {
        contents_id      => undef,
        status_flag      => undef,
        latest_flag      => undef,
        recommend_flag   => undef,
        name             => undef,
        name_kana        => undef,
        personality      => undef,
        appearance       => undef,
        grade            => undef,
        bloodtype        => undef,
        year_of_birth    => undef,
        month_of_birth   => undef,
        date_of_birth     => undef,
        constellation    => undef,
        hobby            => undef,
        message          => undef,
        contentsimage_id => undef,
        painter          => undef,
        stopwatch_id     => undef,
    };

    my $publish = $self->PUBLISH_DIR() . '/admin/' . $q->param('md5key');
    eval {
        my $publishobj = MyClass::WebUtil::publishObj( { file=>$publish } );
        map { exists($updateData->{$_}) ? $updateData->{$_} = $publishobj->{$_} : "" } keys%{$publishobj};
        if (1 > $updateData->{contents_id}) {
            $updateData->{contents_id} = -1;
            $obj->{IfRegistContents} = 1;
        } else {
            $obj->{IfModifyContents} = 1;
        }
    };
    ## パブリッシュオブジェクトの取得失敗の場合
    if ($@) {

    } else {
        my $dbh = $self->getDBConnection();
        my $cmsContents = MyClass::JKZDB::Contents->new($dbh);
        ## autocommit設定をoffにしてトランザクション開始
        my $attr_ref = MyClass::UsrWebDB::TransactInit($dbh);

        eval {
            $cmsContents->executeUpdate($updateData);
            ## 新規の場合にcontents_idが何かをわかるように mysqlInsertIDSQLはcommitの前で取得
            $obj->{contents_id_is} = $obj->{IfRegistContents} ? $cmsContents->mysqlInsertIDSQL() : $updateData->{contents_id};

            $dbh->commit();
            $obj->{name}   = $updateData->{name};
#            $obj->{categorym_id}    = $updateData->{categorym_id};
#            $obj->{subcategorym_id} = $updateData->{subcategorym_id};

            ## シリアライズオブジェクトの破棄
            MyClass::WebUtil::clearObj($publish);
        };
        ## 失敗のロールバック
        if ($@) {
            $dbh->rollback();
            $obj->{ERROR_MSG} = $self->ERROR_MSG("ERR_MSG20");
            $obj->{IfFailExecuteUpdate} = 1;
        } else {
            ## キャッシュから古いデータをなくすため全て削除
            $self->flushAllFromCache();

            ## 新着コンテンツオブジェクトの再構築
            
            my $moddir = $self->CONFIGURATION_VALUE("MODULE_DIR");
            #my $module = sprintf("%s/%s", $moddir, $self->CONFIGURATION_VALUE("GENERATE_LATEST_PRODUCT_MODULE"));
            my $module = $self->CONFIGURATION_VALUE("GENERATE_LATEST_PRODUCT_MODULE");
            my $fullpath2_latest_contents_module = sprintf("%s/%s", $moddir, $self->CONFIGURATION_VALUE("GENERATE_LATEST_PRODUCT_MODULE"));

           # Modified 有効コンテンツ・全コンテンツ生成モジュール 2011/04/30
            my $contents_module = $self->CONFIGURATION_VALUE("GENERATE_ACTIVE_CONTENTS_LIST_MODULE");
            my $fullpath2_contents_module = sprintf("%s/%s", $moddir, $self->CONFIGURATION_VALUE("GENERATE_ACTIVE_CONTENTS_LIST_MODULE"));

            if (-e $fullpath2_latest_contents_module && $fullpath2_contents_module) {
                system("cd $moddir && perl $contents_module");
                system("cd $moddir && perl $module");
            }

            $obj->{IfSuccessExecuteUpdate} = 1;

            $obj->{IfSwfContents} = 1;

        }
        ## autocommit設定を元に戻す
        MyClass::UsrWebDB::TransactFin($dbh, $attr_ref, $@);
        undef($cmsContents);
    }
    $q->delete('md5key');
    $q->param(-name=>"contents_id", -value=>$updateData->{contents_id});
    $self->action('detailContents');
    return $self->detailContents();
    #return $obj;
}


#******************************************************
# @access    public
# @desc        コンテンツの登録状態を一括変更
#            状態・新着・新着Toｐ・オススメ
# @param    int changeContentsStatusTo
#            1  状態を無効にする
#            2  有効にする
#            3  Toｐ表示を有効にする
#
#
# @param    contents_id status_flag  contents_id status_flag latest_flag recommend_flag の4つ値が；で区切り
#       new status
#******************************************************
sub changeContentsStatus {
    my $self = shift;
    my $q    = $self->query();
    my $obj  = {};

    my @TYPE_OF_STATUS    = $self->fetchArrayValuesFromConf("NAME_FOR_STATUS");
    my @FLAG_NAMES        = $self->fetchArrayValuesFromConf("COLUNM_NAME_FOR_STATUS");

    defined($q->param('md5key')) ? $obj->{IfUpdateCompleted} = 1 : $obj->{IfConfirm} = 1;

    if  (!defined($q->param('md5key'))) {

        ## 項目が選択されていない場合はエラー
        unless ( 0 < $q->param('changeContentsStatusTo') || $q->param('contents_id_statatus_flag') ) {
            $obj->{IfError}   = 1;
            $obj->{ERROR_MSG} = "対象IDと状態変更内容を選択してください";
            return $obj;
        }
        if (!$q->MethPost()) {
            $obj->{IfError}   = 1;
            $obj->{ERROR_MSG} = $self->ERROR_MSG("ERR_MSG18");
            return $obj;
        }

        my ( $key_value, $key_status_value ) = split(/;/, $q->param('changeContentsStatusTo'));
        my $config_name_jp    = 'STATUS_NAME_FOR_' . $TYPE_OF_STATUS[$key_value-1] . '_JP';
        $obj->{CONFIGNAME_JP} = $config_name_jp;
        my $column_name       = $FLAG_NAMES[$key_value-1];
        my @STATUS_NAME_JP    = $self->fetchArrayValuesFromConf($config_name_jp);
        my $newstatus_name_jp = $STATUS_NAME_JP[$key_status_value-1];


        my @productparam = $q->param('contents_id_statatus_flag');
        $obj->{LoopContentsList} = $#productparam;
        for (0..$#productparam) {
            ( $obj->{contents_id}->[$_], $obj->{status_flag}->[$_], $obj->{latest_flag}->[$_], $obj->{recommend_flag}->[$_] ) = split(/;/, $productparam[$_]);
        ## 実際の更新の値
            $obj->{newstatus}->[$_]     = $key_status_value;

        ## たなんる出力用の値
            $obj->{statusnamenow}->[$_] = $STATUS_NAME_JP[( $obj->{$column_name}->[$_] - 1 )];
            $obj->{newstatusname}->[$_] = $newstatus_name_jp;
        }
        $obj->{key_value} = $key_value;
        $obj->{md5key} = MyClass::WebUtil::createHash($self->__session_id(), 20);
        ## オブジェクト生成
        my $publish = $self->PUBLISH_DIR() . '/admin/' . $obj->{md5key};
        MyClass::WebUtil::publishObj({file=>$publish, obj=>$obj});

    }
    else {
        $obj->{IfUpdateCompleted} = 1;

        my $publish = $self->PUBLISH_DIR() . '/admin/' . $q->param('md5key');
        my $publishobj;
        eval {
            $publishobj = MyClass::WebUtil::publishObj( { file=>$publish } );
        };
        ## パブリッシュオブジェクトの取得失敗の場合
        if ($@) {

        } else {
            my $dbh = $self->getDBConnection();
            my $cmsContents = MyClass::JKZDB::Contents->new($dbh);
            ## 配列のインデックスで値を取得して更新

            my $tmphash = {};

            for(0..$#{$publishobj->{contents_id}}) {
                $tmphash->{contents_id} = $publishobj->{contents_id}->[$_];
                $tmphash->{$FLAG_NAMES[$publishobj->{key_value} - 1]} = $publishobj->{newstatus}->[$_];
warn "\n ----- \n contents_id : columname : newstatus [",  $tmphash->{contents_id}, " : ", $FLAG_NAMES[$publishobj->{key_value} - 1], " : ", $tmphash->{$FLAG_NAMES[$publishobj->{key_value} - 1]}, " ] \n -------";
warn Dumper($tmphash);
               $obj->{DUMP} .= $cmsContents->executeUpdate($tmphash);
            }

            ## シリアライズオブジェクトの破棄
            MyClass::WebUtil::clearObj($publish);
            ## キャッシュから古いデータをなくすため全て削除 2009/06/08
            $self->flushAllFromCache();
        }
    }

    #******************************************************
    # コンテンツ検索フォーム
    #******************************************************
    my $skey = 's_';
    my $categorylist = $self->fetchCategory();
    $obj->{LoopCategoryList}  = $#{$categorylist->{category_id}};
    for (my $i =0; $i <= $obj->{LoopCategoryList}; $i++) {
        map { $obj->{$skey . $_}->[$i] = $categorylist->{$_}->[$i] } keys %{$categorylist};
    }

    my $pulldown = $self->createPeriodPullDown({year=>"years", month=>"months", date=>"dates", range=>"-2,3"});
    map { $obj->{$_} = $pulldown->{$_} } keys %{$pulldown};
    $pulldown = $self->createPeriodPullDown({year=>"toyears", month=>"tomonths", date=>"todates", range=>"-2,3"});
    map { $obj->{$_} = $pulldown->{$_} } keys %{$pulldown};

    return $obj;

}


#************************************************************************************************************
# @desc        商品カテゴリデータ関連
#************************************************************************************************************

#******************************************************
# @access    public
# @desc      商品カテゴリ一覧
# @param    
#******************************************************
sub viewCategoryList {
    my $self = shift;
    my $q    = $self->query();

    my $record_limit    = 30;
    my $offset          = $q->param('off') || 0;
    my $condition_limit = $record_limit+1;

    my $obj = {};

    my $categorylist = $self->fetchCategory($condition_limit, $offset);
    $obj->{LoopCategoryList} = $#{$categorylist->{category_id}};
    if (0 <= $obj->{LoopCategoryList}) {
        $obj->{IfExistsCategoryList} = 1;
        for (my $i =0; $i <= $obj->{LoopCategoryList}; $i++) {
            map { $obj->{$_}->[$i] = $categorylist->{$_}->[$i] } keys %{$categorylist};
            $obj->{status_flagDescription}->[$i] = $self->fetchOneValueFromConf('STATUS', ($obj->{status_flag}->[$i]-1));
            $obj->{status_flagImages}->[$i]      = $self->fetchOneValueFromConf('STATUSIMAGES', ($obj->{status_flag}->[$i]-1));
            $obj->{description}->[$i]            = MyClass::WebUtil::escapeTags($obj->{description}->[$i]);
            $obj->{registration_date}->[$i]      =~ s!-!/!g;
            $obj->{registration_date}->[$i]      = substr($obj->{registration_date}->[$i] ,2, 9);
        }
        $obj->{rangeBegin} = ($offset+1);
        $obj->{rangeEnd}   = ($obj->{rangeBeginCT}+$obj->{LoopCategoryList});

        if ($record_limit == $obj->{LoopCategoryList}) {
            $obj->{offsetTOnext} = (0 < $offset) ? ($offset + $condition_limit - 1) : $record_limit;
            $obj->{IfNextData}   = 1;
        }
        if ($record_limit <= $offset) {
            $obj->{offsetTOprevious} = ($offset - $condition_limit + 1);
            $obj->{IfPreviousData}   = 1;
        }
    }
    else {
        $obj->{IfNotExistsCategoryList} = 1;
    }

    return  $obj;
}


#******************************************************
# @access    public
# @desc        商品カテゴリ詳細/編集
# @param    
#******************************************************
sub detailCategory {
    my $self = shift;
    my $q    = $self->query();
    $q->autoEscape(0);

    my $obj = {};

    defined($q->param('md5key')) ? $obj->{IfConfirmCategoryForm} = 1 : $obj->{IfModifyCategoryForm} = 1;

    $obj->{md5key} = MyClass::WebUtil::createHash($self->__session_id(), 20);
    ## こちらの評価を先にする。パブリッシュするため
    #*********************************
    # 更新情報をシリアライズ
    #*********************************
    if ($obj->{IfConfirmCategoryForm}) {
        $obj->{category_id}        = $q->param('category_id');
        $obj->{status_flag}        = $q->param('status_flag');
        $obj->{category_name}      = $q->escapeHTML($q->param('category_name'));
        $obj->{description}        = $q->escapeHTML($q->param('description'));
        $obj->{description_detail} = $q->escapeHTML($q->param('description_detail'));
        ## 現在は未使用 2009/03/18
        #$obj->{rank}                = $q->param('rank') || 0;

        my $publish = $self->PUBLISH_DIR() . '/admin/' . $obj->{md5key};
        MyClass::WebUtil::publishObj({file=>$publish, obj=>$obj});

        2 == $obj->{status_flag} ? $obj->{IfStatusFlagIsActive} = 1 : $obj->{IfStatusFlagIsNotActive} = 1;

    }
    elsif ($obj->{IfModifyCategoryForm}) {
        my $category_id = $q->param('category_id');
        my $dbh         = $self->getDBConnection();
        my $cmsCategory = MyClass::JKZDB::Category->new($dbh);

        if (!$cmsCategory->executeSelect({whereSQL => "category_id=?", placeholder => [$category_id,]})) {
            $obj->{DUMP} = "データの取得失敗のまき";
        } else {
            map { $obj->{$_} = $cmsCategory->{columns}->{$_} } keys %{$cmsCategory->{columns}};
            $obj->{description}        = $q->escapeHTML($obj->{description});
            $obj->{description_detail} = $q->escapeHTML($obj->{description_detail});
            2 == $obj->{status_flag} ? $obj->{IfStatusFlagIsActive} = 1 : $obj->{IfStatusFlagIsNotActive} = 1;
        }
        undef($cmsCategory);
    }

    return $obj;
}


#******************************************************
# @access    public
# @desc        商品サブカテゴリ詳細/編集
# @param    
#******************************************************
sub detailSubCategory {
    my $self = shift;
    my $q    = $self->query();
    $q->autoEscape(0);

    my $obj = {};

    #defined($q->param('md5key')) ? $obj->{IfConfirmSubCategoryForm} = 1 : $obj->{IfModifySubCategoryForm} = 1;
    $obj->{IfConfirmSubCategoryForm} = 1 if $q->param('md5key');
    $obj->{IfModifySCategoryForm}    = !$obj->{IfConfirmSubCategoryForm} ? 1 : 0;

    $obj->{md5key} = MyClass::WebUtil::createHash($self->__session_id(), 20);
    ## こちらの評価を先にする。パブリッシュするため
    #*********************************
    # 更新情報をシリアライズ
    #*********************************
    if ($obj->{IfConfirmSubCategoryForm}) {

        ($obj->{categorym_id}, $obj->{EncodedCategoryName})    = split(/;/, $q->param('category_id'));
        $obj->{category_name}      = $q->unescape($obj->{EncodedCategoryName});
        $obj->{subcategory_id}     = $q->param('subcategory_id');
        #$obj->{categorym_id}      = $obj->{categorym_id};
        $obj->{status_flag}        = $q->param('status_flag');
        $obj->{subcategory_name}   = $q->escapeHTML($q->param('subcategory_name'));
        $obj->{category_name}      = $obj->{category_name};
        $obj->{description}        = $q->escapeHTML($q->param('description'));
        $obj->{description_detail} = $q->escapeHTML($q->param('description_detail'));
        ## 現在は未使用 2009/03/18
        #$obj->{rank}                = $q->param('rank') || 0;

        my $publish = $self->PUBLISH_DIR() . '/admin/' . $obj->{md5key};
        MyClass::WebUtil::publishObj({file=>$publish, obj=>$obj});

        2 == $obj->{status_flag} ? $obj->{IfStatusFlagIsActive} = 1 : $obj->{IfStatusFlagIsNotActive} = 1;

    }
    elsif ($obj->{IfModifySCategoryForm}) {
        my $subcategory_id = $q->param('subcategory_id');
        my $categorym_id   = $q->param('category_id');

        my $dbh = $self->getDBConnection();
        my $cmsSubCategory = MyClass::JKZDB::SubCategory->new($dbh);
        #if (!$cmsSubCategory->executeSelect({whereSQL => "subcategory_id=? AND categorym_id=?", placeholder => [$subcategory_id, $categorym_id,]})) {
        if (!$cmsSubCategory->getSpecificValuesSQL({ columns => ["subcategory_id", "categorym_id", "subcategory_name", "status_flag", "registration_date"],whereSQL => "subcategory_id=? AND categorym_id=?", placeholder => [$subcategory_id, $categorym_id,]})) {
            $obj->{DUMP} = "データの取得失敗のまき";
        } else {

            my $categoryobj = $self->fetchCategory();
            $obj->{LoopCategoryList}  = $#{$categoryobj->{category_id}};
            for (my $i =0; $i <= $obj->{LoopCategoryList}; $i++) {
                map { $obj->{$_}->[$i] = $categoryobj->{$_}->[$i] } qw(category_id category_name);
                $obj->{EncodedCategoryName}->[$i]  = $q->escape($obj->{category_name}->[$i]);
                $obj->{IfSelectedCategoryID}->[$i] = 1 if $obj->{category_id}->[$i] == $categorym_id;
            }

            map { $obj->{$_} = $cmsSubCategory->{columns}->{$_} } keys %{$cmsSubCategory->{columns}};
            $obj->{description}        = $q->escapeHTML($obj->{description});
            $obj->{description_detail} = $q->escapeHTML($obj->{description_detail});
            2 == $obj->{status_flag} ? $obj->{IfStatusFlagIsActive} = 1 : $obj->{IfStatusFlagIsNotActive} = 1;
        }
        undef($cmsSubCategory);
    }

    return $obj;
}


#******************************************************
# @access    public
# @desc        カテゴリ新規登録画面
# @param    
#******************************************************
sub registCategory {
    my $self = shift;
    my $q = $self->query();
    $q->autoEscape(0);

    my $obj = $self->viewSubCategoryList();

    my $categoryobj = $self->fetchCategory();

    $obj->{LoopCategoryList} = $#{ $categoryobj->{category_id} };
    map {
        $obj->{category_idM}->[$_] = $categoryobj->{category_id}->[$_];
        $obj->{category_nameM}->[$_] = $categoryobj->{category_name}->[$_];
        $obj->{EncodedCategoryNameM}->[$_] = $q->escape($categoryobj->{category_name}->[$_]);
    } 0..$obj->{LoopCategoryList};
=pod
    $obj->{md5key} = MyClass::WebUtil::createHash($self->__session_id(), 20);
    if (defined($q->param('md5key'))) {
        $obj->{status_flag}        = $q->param('status_flag');
        $obj->{category_name}      = $q->escapeHTML($q->param('category_name'));
        $obj->{description}        = $q->escapeHTML($q->param('description'));
        $obj->{description_detail} = $q->escapeHTML($q->param('description_detail'));
        ## 現在は未使用 2009/03/18
        #$obj->{rank}                = $q->param('rank') || 0;
        ## 入力項目が条件を満たしてない場合はデータをパブリッシュしない。
        ## 再度新規登録フォームを表示
        if (4 > length($q->param('category_name'))) {
            $obj->{IfRegistCategoryForm} = 1;
            $obj->{ERROR_MSG}            = $self->ERROR_MSG('ERR_MSG17');
            $obj->{IfInputCheckError}    = 1;
            (2 == int($q->param('status_flag'))) ? $obj->{IfStatusflag2} = 1 : $obj->{IfStatusflag1} = 1;
        } else {
            $obj->{IfConfirmCategoryForm} = 1;
            $obj->{Ifabc} = 0;
            my $publish = $self->PUBLISH_DIR() . '/admin/' . $obj->{md5key};
            MyClass::WebUtil::publishObj({file=>$publish, obj=>$obj});
            2 == $obj->{status_flag} ? $obj->{IfStatusFlagIsActive} = 1 : $obj->{IfStatusFlagIsNotActive} = 1;
        }
    } else {
        $obj->{IfRegistCategoryForm} = 1;
    }

=cut


    return $obj;
}


#******************************************************
# @access    public
# @desc        中カテゴリ新規登録画面
# @param    
#******************************************************
sub registSubCategory {
    my $self = shift;
    my $q = $self->query();
    $q->autoEscape(0);
    my $obj = {};

    $obj->{md5key} = MyClass::WebUtil::createHash($self->__session_id(), 20);
    if (defined($q->param('md5key'))) {

        ($obj->{categorym_id}, $obj->{EncodedCategoryName})    = split(/;/, $q->param('category_id'));
        $obj->{category_name}      = $q->unescape($obj->{EncodedCategoryName});
        $obj->{status_flag}        = $q->param('status_flag');
        $obj->{subcategory_name}   = $q->escapeHTML($q->param('subcategory_name'));
        $obj->{description}        = $q->escapeHTML($q->param('description'));
        $obj->{description_detail} = $q->escapeHTML($q->param('description_detail'));
        ## 現在は未使用 2009/03/18
        #$obj->{rank}                = $q->param('rank') || 0;
        ## 入力項目が条件を満たしてない場合はデータをパブリッシュしない。
        ## 再度新規登録フォームを表示
        if (4 > length($q->param('subcategory_name'))) {
            $obj->{IfRegistSubCategoryForm} = 1;
            $obj->{ERROR_MSG} = $self->ERROR_MSG('ERR_MSG17');
            $obj->{IfInputCheckError} = 1;
            (2 == int($q->param('status_flag'))) ? $obj->{IfStatusflag2} = 1 : $obj->{IfStatusflag1} = 1;
        } else {
            $obj->{IfConfirmSubCategoryForm} = 1;
            $obj->{Ifabc} = 0;
            my $publish = $self->PUBLISH_DIR() . '/admin/' . $obj->{md5key};
            MyClass::WebUtil::publishObj({file=>$publish, obj=>$obj});
            2 == $obj->{status_flag} ? $obj->{IfStatusFlagIsActive} = 1 : $obj->{IfStatusFlagIsNotActive} = 1;
        }
    } else {
        $obj->{IfRegistSubCategoryForm} = 1;

        my $categoryobj = $self->fetchCategory();
        $obj->{LoopCategoryList}  = $#{$categoryobj->{category_id}};
        for (my $i =0; $i <= $obj->{LoopCategoryList}; $i++) {
            map { $obj->{$_}->[$i] = $categoryobj->{$_}->[$i] } qw(category_id category_name);
            $obj->{EncodedCategoryName}->[$i]    = $q->escape($obj->{category_name}->[$i]);
        }

    }

    return $obj;
}


#******************************************************
# @access    public
# @desc        カテゴリ情報更新/新規登録
# @param    
#******************************************************
sub modifyCategory {
    my $self = shift;

    my $q = $self->query();
    my $obj = {};

    if (!$q->MethPost()) {
        $obj->{ERROR_MSG} = $self->ERROR_MSG("ERR_MSG18");
    }

    my $updateData = {
        category_id        => undef,
        status_flag        => undef,
        category_name      => undef,
        description        => undef,
        description_detail => undef,
    };

    my $publish = $self->PUBLISH_DIR() . '/admin/' . $q->param('md5key');
    eval {
        my $publishobj = MyClass::WebUtil::publishObj( { file=>$publish } );
        map { exists($updateData->{$_}) ? $updateData->{$_} = $publishobj->{$_} : "" } keys%{$publishobj};
        if (1 > $updateData->{category_id}) {
            $updateData->{category_id} = -1;
            $obj->{IfRegistCategory}   = 1;
        } else {
            $obj->{IfModifyCategory}   = 1;
        }
    };
    ## パブリッシュオブジェクトの取得失敗の場合
    if ($@) {
        
    } else {
        my $dbh         = $self->getDBConnection();
        my $cmsCategory = MyClass::JKZDB::Category->new($dbh);
        my $attr_ref    = MyClass::UsrWebDB::TransactInit($dbh);

        eval {
            $cmsCategory->executeUpdate($updateData);
            $dbh->commit();
            ## 新規の場合にcontents_idが何かをわかるように
            $obj->{category_id_is} = $obj->{IfRegistCategory} ? $cmsCategory->mysqlInsertIDSQL() : $updateData->{category_id};
            $obj->{category_name}  = $updateData->{category_name};

            ## シリアライズオブジェクトの破棄
            MyClass::WebUtil::clearObj($publish);
        };
        ## 失敗のロールバック
        if ($@) {
            $dbh->rollback();
            $obj->{ERROR_MSG}           = $self->ERROR_MSG("ERR_MSG20");
            $obj->{IfFailExecuteUpdate} = 1;
        } else {
            $obj->{IfSuccessExecuteUpdate} = 1;
            ## cacheを削除する。OR新規データが表示されない。
            $self->deleteFromCache("1MPcategorylist");
        }
        ## autocommit設定を元に戻す
        MyClass::UsrWebDB::TransactFin($dbh, $attr_ref, $@);
        undef($cmsCategory);
    }
    return $obj;
}


#******************************************************
# @access    public
# @desc        サブカテゴリ情報更新/新規登録
# @param    
#******************************************************
sub modifySubCategory {
    my $self = shift;
    my $q    = $self->query();
    my $obj  = {};

    if (!$q->MethPost()) {
        $obj->{ERROR_MSG} = $self->ERROR_MSG("ERR_MSG18");
    }

    my $subcategory_id = $q->param('subcategory_id');
    my $subcategory_name = $q->param('subcategory_name');

    if (5 > length($subcategory_name) || "" eq $subcategory_name) {
        $obj->{ERROR_MSG} = MyClass::WebUtil::convertByNKF('-s', "サブカテゴリ名がありません。");
    }

    my $status_flag = $q->param('status_flag');
    my $description = $q->param('description');

    my $updateData = {
        status_flag        => $status_flag,
        subcategory_name   => MyClass::WebUtil::escapeTags($subcategory_name),
        description        => $description,
    };

    ## 新規登録
    if (0 > $subcategory_id) {
        my ($categorym_id, $EncodedCategoryName)    = split(/;/, $q->param('category_id'));
        my $category_name  = $q->unescape($EncodedCategoryName);

        $updateData->{subcategory_id} = -1;
        $updateData->{categorym_id}   = $categorym_id;
        $updateData->{category_name}  = $category_name;
    }
    else {
        $updateData->{subcategory_id} = $subcategory_id;
    }

    my $dbh            = $self->getDBConnection();
    $self->setDBCharset("sjis");
    my $cmsSubCategory = MyClass::JKZDB::SubCategory->new($dbh);
    my $attr_ref       = MyClass::UsrWebDB::TransactInit($dbh);

    eval {
        $cmsSubCategory->executeUpdate($updateData);
        $dbh->commit();

    };
    ## 失敗のロールバック
    if ($@) {
        $dbh->rollback();
        $obj->{IfFailExecuteUpdate} = 1;
    }

    $self->flushAllFromCache();
    ## autocommit設定を元に戻す
    MyClass::UsrWebDB::TransactFin($dbh, $attr_ref, $@);
    undef($cmsSubCategory);

    ## オブジェクト再構築
    my $moddir = $self->CONFIGURATION_VALUE("MODULE_DIR");
    my $module = sprintf("%s/%s", $moddir, $self->CONFIGURATION_VALUE("GENERATE_SMALL_SUB_CATEGORY_LIST_MODULE"));
    if (-e $module) {
        system("cd $moddir && perl $module");
    }

    $self->action('registCategory');

    return $self->registCategory();

=pod
    my $publish = $self->PUBLISH_DIR() . '/admin/' . $q->param('md5key');
    eval {
        my $publishobj = MyClass::WebUtil::publishObj( { file=>$publish } );
        map { exists($updateData->{$_}) ? $updateData->{$_} = $publishobj->{$_} : "" } keys%{$publishobj};
        if (1 > $updateData->{subcategory_id}) {
            $updateData->{subcategory_id} = -1;
            $obj->{IfRegistSubCategory}   = 1;
        } else {
            $obj->{IfModifySubCategory}   = 1;
        }
    };
    ## パブリッシュオブジェクトの取得失敗の場合
    if ($@) {
        
    } else {

        my $dbh            = $self->getDBConnection();
        my $cmsSubCategory = MyClass::JKZDB::SubCategory->new($dbh);
        my $attr_ref       = MyClass::UsrWebDB::TransactInit($dbh);


        eval {
            $cmsSubCategory->executeUpdate($updateData);
            $dbh->commit();
            ## 新規の場合にcontents_idが何かをわかるように
            $obj->{subcategory_id_is}    = $obj->{IfRegistSubCategory} ? $cmsSubCategory->mysqlInsertIDSQL() : $updateData->{subcategory_id};
            ## シリアライズオブジェクトの破棄
            MyClass::WebUtil::clearObj($publish);
        };
        ## 失敗のロールバック
        if ($@) {
            $dbh->rollback();
            $obj->{ERROR_MSG}              = $self->ERROR_MSG("ERR_MSG20");
            $obj->{IfFailExecuteUpdate}    = 1;
        } else {
            $obj->{IfSuccessExecuteUpdate} = 1;
            $obj->{categorym_id}           = $updateData->{categorym_id};
            $obj->{subcategory_name}       = $updateData->{subcategory_name};
            $obj->{category_name}          = $updateData->{category_name};
            ## cacheを削除する。OR新規データが表示されない。
            #$self->flushAllFromCache();
        }

        $self->flushAllFromCache();
        ## autocommit設定を元に戻す
        MyClass::UsrWebDB::TransactFin($dbh, $attr_ref, $@);
        undef($cmsSubCategory);

        ## オブジェクト再構築
        my $moddir = $self->CONFIGURATION_VALUE("MODULE_DIR");
        my $module = sprintf("%s/%s", $moddir, $self->CONFIGURATION_VALUE("GENERATE_SMALL_SUB_CATEGORY_LIST"));
        if (-e $module) {
            system("cd $moddir && perl $module");
        }

    $self->action('registCategory');

    return $self->registCategory();
=cut
}

1;

__END__
=pod
                ## まだループがあるとき
                unless ($i == $obj->{LoopImageList}) {
                    ## 2個の場合
                    $obj->{TRBEGIN}->[$i]    = (0 == $i % 2 ) ? '<tr>' : '';
                    $obj->{TREND}->[$i]        = (0 == $i % 2 ) ? '' : '</tr>';
                    ## 3個の場合
    #                $obj->{TR}->[$i] = (0 == ($i+1) % 3 ) ? '</tr><tr><!-- auto generated end tag and begin tag -->' : "";
                    ## 5この場合
    #                $obj->{TR}->[$i] = (0 == ($i+1) % 5 ) ? '</tr><tr><!-- auto generated end tag and begin tag -->' : "";
                } else { ## 最終ループで終わりのとき
                    ## 2個の場合
                    $obj->{TRBEGIN}->[$i]    = (0 == $i % 2 ) ? '<tr>' : '';
                    $obj->{TREND}->[$i]        = (0 == $i % 2 ) ? '<td><br /></td></tr>' : '</tr>';
                    ## 3個の場合
    #                $obj->{TR}->[$i] =
    #                    (0 == ($i+1) % 3 ) ? '</tr><!-- auto generated tr end tag -->'                         :
    #                    (2 == ($i+1) % 3 ) ? '<td></td></tr><!-- auto generated one pair of td tag tr end tag -->'         :
    #                                         '<td></td><td></td></tr><!-- auto generated two pair of td tag tr end tag -->';
                    ## 5個の場合
    #                $obj->{TR}->[$i] =
    #                    (0 == ($i+1) % 5 ) ? '</tr>'                                                                 :
    #                    (1 == ($i+1) % 5 ) ? '<td><br /></td><td><br /></td><td><br /></td><td><br /></td></tr>'    :
    #                    (2 == ($i+1) % 5 ) ? '<td><br /></td><td><br /></td><td><br /></td></tr>'                    :
    #                    (3 == ($i+1) % 5 ) ? '<td><br /></td><td><br /></td></tr>'                                    :
    #                                         '<td><br /></td></tr>'                                                     ;
                }



#******************************************************
# @access    public
# @desc      コンテンツ一覧
# @param    
#******************************************************
sub viewContentsList {
    my $self = shift;

    my $q = $self->query();
    my $record_limit    = 20;
    my $offset          = $q->param('off') || 0;
    my $condition_limit = $record_limit+1;

    my $obj = {};
    my $dbh = $self->getDBConnection();

        ## 全レコード件数SQL
#        my $MAXREC_SQL = sprintf("SELECT
# COUNT(c.contents_id)
# FROM %s.tContentsM c
# LEFT JOIN %s.tCategoryM ca ON c.categorym_id=ca.category_id;",
        my $MAXREC_SQL = sprintf("SELECT COUNT(c.contents_id) FROM %s.tContentsM c;", $self->waf_name_space);

    my @navilink;

    my $maxrec = $dbh->selectrow_array($MAXREC_SQL);

    ## レコード数が1ページ上限数より多い場合
    if ($maxrec > $record_limit) {

    my $url = '/app.mpl?app=AppContents;action=viewContentsList';

    ## 前へページの生成
        if (0 == $offset) { ## 最初のページの場合
            push(@navilink, "<font size=-1>&lt;&lt;前</font>&nbsp;");
        } else { ## 2ページ目以降の場合
            push(@navilink, $self->genNaviLink($url, "<font size=-1>&lt;&lt;前</font>&nbsp;", $offset - $record_limit));
        }

    ## ページ番号生成
        for (my $i = 0; $i < $maxrec; $i += $record_limit) {

            my $pageno = int ($i / $record_limit) + 1;

            if ($i == $offset) { ###現在表示してるﾍﾟｰｼﾞ分
                push (@navilink, '<font size=+1>' . $pageno . '</font>');
            } else {
                push (@navilink, $self->genNaviLink($url, $pageno, $i));
            }
        }

    ## 次へページの生成
        if (($offset + $record_limit) > $maxrec) {
            push (@navilink, "&nbsp;<font size=-1>次&gt;&gt;</font>");
        } else {
            push (@navilink, $self->genNaviLink($url, "&nbsp;<font size=-1>次&gt;&gt;</font>", $offset + $record_limit));
        }

        @navilink = map{ "$_\n" } @navilink;

        $obj->{pagenavi} = sprintf("<font size=-1>[全%s件 / %s件\表\示]</font><br />", $maxrec, $record_limit) . join(' ', @navilink);
    }

    my $ContentsList = MyClass::JKZDB::Contents->new($dbh);
    $ContentsList->executeSelectList({
        orderbySQL => 'registration_date DESC',
        limitSQL   => "$offset, $condition_limit",
    });

    $obj->{LoopContentsList} = ($record_limit == $ContentsList->countRecSQL()) ? $record_limit-1 : $ContentsList->countRecSQL();
    if (0 <= $ContentsList->countRecSQL()) {
        $obj->{IfExistsContentsList} = 1;
        map {

            my $i = $_;
            foreach my $key (keys %{ $ContentsList->{columnslist} }) {
                $obj->{$key}->[$i] = $ContentsList->{columnslist}->{$key}->[$i];
            }
            $obj->{status_flagDescription}->[$i] = $self->fetchOneValueFromConf('STATUS', ($obj->{status_flag}->[$i]-1));
            $obj->{status_flagImages}->[$i]      = $self->fetchOneValueFromConf('STATUSIMAGES', ($obj->{status_flag}->[$i]-1));
            $obj->{description}->[$i]            = MyClass::WebUtil::escapeTags($obj->{description}->[$i]);
            $obj->{registration_date}->[$i]      =~ s!-!/!g;
            $obj->{registration_date}->[$i]      = substr($obj->{registration_date}->[$i] , 2, 9);

        } 0..$obj->{LoopContentsList};

        $obj->{rangeBegin} = ($offset+1);
        $obj->{rangeEnd}   = ($obj->{rangeBeginCT}+$obj->{LoopContentsList});

        if ($record_limit == $obj->{LoopContentsList}) {
            $obj->{offsetTOnext} = (0 < $offset) ? ($offset + $condition_limit - 1) : $record_limit;
            $obj->{IfNextData}   = 1;
        }
        if ($record_limit <= $offset) {
            $obj->{offsetTOprevious} = ($offset - $condition_limit + 1);
            $obj->{IfPreviousData}   = 1;
        }
    }
    else {
        $obj->{IfNotExistsContentsList} = 1;
    }

    return  $obj;
}


#******************************************************
# @access    public
# @desc        商品中カテゴリ一覧
# @param    
#******************************************************
sub viewSubCategoryList {
    my $self = shift;
    my $q    = $self->query();

    my $record_limit    = 30;
    my $offset          = $q->param('off') || 0;
    my $condition_limit = $record_limit+1;

    my $obj = {};

    my $subcategorylist = $self->fetchSubCategory($condition_limit, $offset);
    $obj->{LoopSubCategoryList}  = $#{$subcategorylist->{subcategory_id}};
    if (0 <= $obj->{LoopSubCategoryList}) {
        $obj->{IfExistsSubCategoryList} = 1;
        for (my $i =0; $i <= $obj->{LoopSubCategoryList}; $i++) {
            map { $obj->{$_}->[$i] = $subcategorylist->{$_}->[$i] } keys %{$subcategorylist};

            $obj->{description}->[$i]            = MyClass::WebUtil::escapeTags($obj->{description}->[$i]);
            2 == $obj->{status_flag}->[$i] ? $obj->{IfStatusIsActive}->[$i] = 1 : $obj->{IfStatusIsNotActive}->[$i] = 1;
            $obj->{cssstyle}->[$i] = 0 != $i % 2 ? 'focuseven' : 'focusodd';

        }
        $obj->{rangeBegin} = ($offset+1);
        $obj->{rangeEnd}   = ($obj->{rangeBeginCT}+$obj->{LoopSubCategoryList});

        if ($record_limit == $obj->{LoopSubCategoryList}) {
            $obj->{offsetTOnext} = (0 < $offset) ? ($offset + $condition_limit - 1) : $record_limit;
            $obj->{IfNextData}   = 1;
        }
        if ($record_limit <= $offset) {
            $obj->{offsetTOprevious} = ($offset - $condition_limit + 1);
            $obj->{IfPreviousData}   = 1;
        }
    }
    else {
        $obj->{IfNotExistsSubCategoryList} = 1;
    }

    return  $obj;
}

=cut

#******************************************************
# @access    public
# @desc      商品サブカテゴリリスト
# @param    
#******************************************************
=pod
sub fetchSubCategory {
    my $self      = shift;
    my $namespame = $self->waf_name_space() . 'AppSubCategorylist';
    my $memcached = $self->initMemcachedFast();
    my $obj = $memcached->get("$namespame");

    if (!$obj) {
        my $dbh = $self->getDBConnection();
        $self->setDBCharset('SJIS');

        my $cmsSubCategorylist = MyClass::JKZDB::SubCategory->new($dbh);
        $cmsSubCategorylist->executeSelectList();
        map { $obj->{$_} = $cmsSubCategorylist->{columnslist}->{$_} } keys %{$cmsSubCategorylist->{columnslist}};

        $memcached->add("$namespame", $obj, 600);
        undef($cmsSubCategorylist);
    }

    return $obj;
}
=cut