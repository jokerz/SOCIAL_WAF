#******************************************************
# @desc     萌えフラッシュプラグイン
#           HOOK.CONTENTSCATEGORY
#           HOOK.LATESTCONTENTS
# @package    MyClass::Plugin::DegitalContents
# @author    Iwahase Ryo
# @create    2011/03/01
# @update    
# @version    1.00
#******************************************************

package MyClass::Plugin::DegitalContents;

use strict;
use warnings;
no warnings 'redefine';
use base 'MyClass::Plugin';

use MyClass::WebUtil;
use MyClass::JKZDB::Contents;
use MyClass::JKZDB::ContentsImage;
use MyClass::JKZDB::MyContentsStatus;

#use MyClass::JKZDB::GsaContentsSwf;
#use MyClass::JKZDB::GsaContentsImage;
#use MyClass::JKZDB::GsaContentsSampleImage;

#******************************************************
# @desc        hook  コンテンツのカテゴリ(体操服とかナースとか)
# @param    
# @param    
# @return    
#******************************************************
sub contentscategory :Hook('HOOK.CONTENTSCATEGORY') {
    my ($self, $c, $arg) = @_;

    my $return_obj = {};

    my $contentscategoryobj      = $c->getFromObjectFile( { CONFIGURATION_VALUE=>'CATEGORYLIST_OBJ' } );
    my $cnt = 0;
    map {
        my $i = $_;
        if (2 == $contentscategoryobj->[$i+1]->{'status_flag'}) {
                $return_obj->{'PL.category_id'}->[$cnt]      = $contentscategoryobj->[$i+1]->{'category_id'};
                $return_obj->{'PL.category_name'}->[$cnt]    = $contentscategoryobj->[$i+1]->{'category_name'};
                $return_obj->{'PL.LCATEGORYMAINURL'}->[$cnt] = $c->MAINURL;

                $cnt++;
        }
    } 0..$#{ $contentscategoryobj } -1;

    $return_obj->{'Loop.PL.ContentsCategoryList'} = $cnt-1;
    $return_obj->{'If.HOOK.CONTENTSCATEGORY'}     = 1;

    return $return_obj;
}


#******************************************************
# @desc        hook  新着コンテンツ表示
# @param    
# @param    
# @return    
#******************************************************
sub latestcontents :Hook('HOOK.LATESTCONTENTS') {
    my ($self, $c, $arg) = @_;

    my $return_obj    = {};
    my $latestcontentsref = $c->getFromObjectFile({ CONFIGURATION_VALUE => 'LATEST_CONTENTS_ONTOP_OBJ' });

    if (defined($latestcontentsref)) {
       ## 新着をトップでの表示数は3個だから3個以上あるときはループは3回までに制限
        $return_obj->{'Loop.PL.LatestContentsList'}     = ( 3 > $#{ $latestcontentsref } ) ? $#{ $latestcontentsref } : 2;
        $return_obj->{'If.PL.ExistsMoreLatestContents'} = 1;
        $return_obj->{'If.PL.ExistsLatestContents'}     = 1;

        #my $is_called_from_member    = ( defined( $c->query->param('s') ) ) ? $c->s_is_ciphered_member_param() : 0;
        #my $MEMBERMAINURL_OR_MAINURL = ( 1 == $is_called_from_member ) ? $c->MEMBERMAINURL : $c->MAINURL;
        #my $MEMBERMAINURL_OR_MAINURL = ( 0 < $c->user_is_member ) ? $c->MEMBERMAINURL : $c->MAINURL;
        
        map {
            $return_obj->{'PL.latestcontents_contents_id'}->[$_]   = $latestcontentsref->[$_]->[0];
            $return_obj->{'PL.latestcontents_contents_name'}->[$_] = 20 < length($latestcontentsref->[$_]->[1]) ? substr($latestcontentsref->[$_]->[1], 0, 20) .'...' : $latestcontentsref->[$_]->[1];
            $return_obj->{'PL.LATESTCONTENTS_SMALL_IMAGE'}->[$_]   = sprintf("%s%s?p=%s:1&s=4", $c->MAIN_URL, $c->CONFIGURATION_VALUE('CONTENTS_SAMPLE_IMAGE_SCRIPTDATABASE_NAME'), $latestcontentsref->[$_]->[0]);
            $return_obj->{'PL.MAINURL'}->[$_]                      = $c->MAINURL;
        } 0..$return_obj->{'Loop.PL.LatestContentsList'};

    } else {
        $return_obj->{'If.PL.NotExistsNewContents'} = 1;
    }

    $return_obj->{'If.HOOK.LATESTCONTENTS'} = 1;

    return $return_obj;
}


#******************************************************
# @desc     hook justuserのデータ取得
# @desc    flashgameJustUser.objからjsutuserとゲットした画像IDを取得
# @desc    { justuser_gree_user_id, justuser_nickname justuser_getimage justuser_contents_name categorym_id } justuser_getimageはCONCAT(contentsm_id, ':', categorym_id)
# @return   
#******************************************************
sub justuser :Hook('HOOK.JUSTUSER') {
    my ($self, $c, $arg) = @_;

    my $return_obj = {};

    $return_obj->{'If.HOOK.JUSTUSER'} = 1;

    my $justuserref = $c->getFromObjectFile({ CONFIGURATION_VALUE => 'FLASHGAME_JUST_USER_OBJ' });

    if (!$justuserref) {
        $return_obj->{'If.PL.NotExistsJustUser'} = 1;
        return $return_obj;
    }

    map { $return_obj->{'PL.' . $_} = $justuserref->{$_} } keys %{ $justuserref };

    my $categoryobj = $c->getFromObjectFile({ CONFIGURATION_VALUE => 'CATEGORYLIST_OBJ', subject_id => $justuserref->{categorym_id} });

    $return_obj->{'PL.justuser_category_name'} = $categoryobj->{category_name};

    ($justuserref->{justuser_gree_user_id} == $c->opensocial_viewer_id ) ? $return_obj->{'If.PL.JustUserIsYourself'} = 1 : $return_obj->{'If.PL.JustUserIsNotYourself'} = 1;
    $return_obj->{'PL.JUSTUSER_OTHERPAGE_URL'}                   = $c->OTHERPAGE_URL;
    $return_obj->{'PL.JUSTUSER_SAMPLE_IMAGE_SCRIPTDATABASE_URL'} = sprintf("%s%s", $c->MAIN_URL, $c->CONFIGURATION_VALUE('CONTENTS_SAMPLE_IMAGE_SCRIPTDATABASE_NAME'));
    $return_obj->{'If.PL.ExistsJustUser'} = 1;

    return $return_obj;
}


#******************************************************
# @desc     hook 挑戦ﾗﾝｷﾝｸﾞ
# @param    
# @return   
#******************************************************
sub getimageuserranking :Hook('HOOK.MYGETIMAGEUSERRANKING') {
    my ($self, $c, $arg) = @_;

    my $return_obj = {};
    my $userrankingref = $c->getFromObjectFile({ CONFIGURATION_VALUE => 'GETIMAGE_USERRANKING_OBJ' });

    if (defined($userrankingref)) {
       ## ランキングをトップでの表示数は3個だから5個以上あるときはループは5回までに制限
        $return_obj->{'Loop.PL.MyGetImageUserRankingList'} = ( 5 > $#{ $userrankingref } ) ? $#{ $userrankingref } : 4;
        $return_obj->{'If.PL.ExistsMyGetImageUserRanking'}    = 1;

        map {
            foreach my $key ( keys %{ $userrankingref->[$_] } ) {
                $return_obj->{'PL.' . $key}->[$_]                   = $userrankingref->[$_]->{$key};
                $return_obj->{'PL.my_getimagerankuser_rank'}->[$_]  = $_ + 1;
                $return_obj->{'PL.LOTHERPAGE_URL'}->[$_]            = $c->OTHERPAGE_URL;

                # ﾗﾝｷﾝｸﾞのが自分の場合
                ( $userrankingref->[$_]->{getimagerankuser_gree_user_id} == $c->opensocial_viewer_id ) ? $return_obj->{'If.PL.UserIsYourself'}->[$_] = 1 : $return_obj->{'If.PL.UserIsNotYourself'}->[$_] = 1;
            }
        } 0..$return_obj->{'Loop.PL.MyGetImageUserRankingList'};
    }
    else {
        $return_obj->{'If.PL.NotExistsMyGetImageUserRanking'} = 1;
    }
    $return_obj->{'If.HOOK.MYGETIMAGEUSERRANKING'}     = 1;

    return $return_obj;
}


#******************************************************
# @desc     萌えコンテンツ詳細
# @param    mc 
# @return    
#******************************************************
sub detail_contents :Method {
    my ($self, $c, $args) = @_;

    my $return_obj  = {};
    my $q           = $c->query();
    my $a           = $q->param('a');
    my $o           = $q->param('o');
    my $contents_id = $q->param('p');

    my $memcached   = $c->memcached();
    my $namespace   = $c->waf_name_space() . 'contents';
    $return_obj     = $memcached->get("$namespace:$contents_id");

    if (!$return_obj) {
        my $dbh    = $c->getDBConnection();
        $c->setDBCharset("sjis");
        my $myContents = MyClass::JKZDB::Contents->new($dbh);
        if(!$myContents->executeSelect( { whereSQL => "contents_id=? AND status_flag=?", placeholder => [$contents_id, 2] } )) {
        
        }
        else {
            map { $return_obj->{$_} = $myContents->{columns}->{$_} } keys %{ $myContents->{columns} };

            $memcached->add("$namespace:$contents_id", $return_obj, 3600);
        }
    }

    my $categorylist = $c->getFromObjectFile( { CONFIGURATION_VALUE => 'CATEGORYLIST_OBJ' } );


    my $gree_user_id = $c->opensocial_owner_id;
    my $myContents = MyClass::JKZDB::MyContentsStatus->new($c->getDBConnection);
    # クリア済みキャラクタのカテゴリ取得 クリア済みの場合は合計6つの値が入ってる
    my @tmp         = split(/,/, $myContents->makeSetOfCategoryID({ gree_user_id => $gree_user_id, contentsm_id => $contents_id }));
    my @complete    = map { log($_) / log(2) } @tmp;

    $return_obj->{'Loop.PL.CharacterList'}  = $#{ $categorylist } - 1;
    map {
        my $idx = $_;
        $return_obj->{'PL.category_id'}->[$idx]         = $categorylist->[$idx+1]->{'category_id'};
        $return_obj->{'PL.category_name'}->[$idx]       = $categorylist->[$idx+1]->{'category_name'};
        $return_obj->{'PL.LCATEGORYMAINURL'}->[$idx]    = $c->MAINURL;
        $return_obj->{'PL.LMYPAGE_URL'}->[$idx]         = $c->MYPAGE_URL;
        $return_obj->{'PL.contents_id'}->[$idx]         = $return_obj->{contents_id};
        $return_obj->{'If.PL.TREnd'}->[$idx]            = 1 if ( 2 == $idx % 3 );
        $return_obj->{'If.PL.TRBegin'}->[$idx]          = 1 if ( 0 == $idx % 3 );

        $return_obj->{'PL.LCONTENTS_SAMPLE_IMAGE_SCRIPTDATABASE_URL'}->[$idx] = sprintf("%s%s", $c->MAIN_URL, $c->CONFIGURATION_VALUE('CONTENTS_SAMPLE_IMAGE_SCRIPTDATABASE_NAME'));
        $return_obj->{'PL.LCONTENTS_IMAGE_SCRIPTDATABASE_URL'}->[$idx]        = sprintf("%s%s", $c->MAIN_URL, $c->CONFIGURATION_VALUE('CONTENTS_IMAGE_SCRIPTDATABASE_NAME'));

        # Modified 2011/04/30 未コンプリートの場合はクリア済み画像かの判定
        ( grep { /$return_obj->{'PL.category_id'}->[$idx]/ } @complete )  ? $return_obj->{'If.PL.MyGetImage'}->[$idx] = 1 : $return_obj->{'If.PL.NotMyGetImage'}->[$idx] = 1;

    } 0..$return_obj->{'Loop.PL.CharacterList'};

    return $return_obj;

}


#******************************************************
# @desc     萌え新着コンテンツ表示メソッド
# @param    mc 
# @return    
#******************************************************
sub viewlist_latestcontents :Method {
    my ($self, $c, $args) = @_;

    my $return_obj       = {};
    my $q                = $c->query();
    my $a                = $q->param('a');
    my $o                = $q->param('o');
    my $offset           = $q->param('off') || 0;
    my $record_limit     = 6;
    my $condition_limit  = $record_limit+1;


    #*******************************
    ##オブジェクトの取得
    #*******************************
    my $latestcontentsobj = $c->getFromObjectFile({ CONFIGURATION_VALUE => 'LATEST_CONTENTS_ONTOP_OBJ' });

    if ($latestcontentsobj) {
        my $totalrec = $#{ $latestcontentsobj } + 1;
        my @navilink;

        ## レコード数が1ページ以上場合
        if ($totalrec > $record_limit) {
            my $url = sprintf("%sa=%s&o=%s", $c->MAINURL, $a, $o);

            ## 2ページ目以降の場合 前へリンクの生成
            if (0 < $offset) {
                $return_obj->{'If.PL.ExistsPreviousPage'} = 1;
                $return_obj->{'PL.PreviousPageUrl'} = sprintf("%s&off=%s", $url, ($offset - $record_limit));
            }
            ## 次へリンクの生成
            if (($offset + $record_limit) < $totalrec) {
                $return_obj->{'If.PL.ExistsNextPage'} = 1;
                $return_obj->{'PL.NextPageUrl'} = sprintf("%s&off=%s", $url, ($offset + $record_limit));
            }

            ## ページ番号生成
            for (my $i = 0; $i < $totalrec; $i += $record_limit) {

                my $pageno = int ($i / $record_limit) + 1;

                if ($i == $offset) { ###現在表示してるﾍﾟｰｼﾞ分
                    push (@navilink, $pageno);
                } else {
                    my $pagenate_url = sprintf("%s&off=%s", $url, $i);
                    push (@navilink, $c->query->a({-href=>$pagenate_url}, $pageno));
                }
            }

            @navilink = map{ "$_\n" } @navilink;

            $return_obj->{'PL.pagenavi'} = join(' ', @navilink);
        }

        $return_obj->{'PL.totalrecord'} = $totalrec;

      ## コンテンツ数とオフセットの差が1ページ表示数以上であれば1ページ表示数分のループ。以下であればその差をループ
        $return_obj->{'Loop.PL.LatestContentsList'} = ( $record_limit < ($totalrec - $offset) ) ? ( $record_limit - 1 ) : ( $totalrec - $offset - 1 );

        map {
            $return_obj->{'PL.LMAINURL'}->[$_]      = $c->MAINURL;
            $return_obj->{'PL.LMYPAGE_URL'}->[$_]   = $c->MYPAGE_URL;
            $return_obj->{'PL.LCONTENTS_SAMPLE_IMAGE_SCRIPTDATABASE_URL'}->[$_] = sprintf("%s%s", $c->MAIN_URL, $c->CONFIGURATION_VALUE('CONTENTS_SAMPLE_IMAGE_SCRIPTDATABASE_NAME'));
            $return_obj->{'PL.latestcontents_id'}->[$_]                         = $latestcontentsobj->[$_+$offset]->[0];
            $return_obj->{'PL.latestcontents_name'}->[$_]                       = $latestcontentsobj->[$_+$offset]->[1];

            if ( $return_obj->{'Loop.PL.LatestContentsList'} == $_ ) {
                $return_obj->{'If.PL.TDandTDandTREnd'}->[$_] = 1 if ( 0 == $_ % 3 );
                $return_obj->{'If.PL.TDandTREnd'}->[$_]      = 1 if ( 1 == $_ % 3 );
            }
            $return_obj->{'If.PL.TREnd'}->[$_]   = 1 if ( 2 == $_ % 3 );
            $return_obj->{'If.PL.TRBegin'}->[$_] = 1 if ( 0 == $_ % 3 );

        } 0..$return_obj->{'Loop.PL.LatestContentsList'};

        ( 0 < $totalrec ) ? $return_obj->{'If.PL.ExistsLatestContents'} = 1 : $return_obj->{'If.PL.NotExistsLatestContents'} = 1;

    } else {
        $return_obj->{'If.PL.NotExistsLatestContents'} = 1;
    }

    $return_obj;
}


#******************************************************
# @desc     カテゴリ別キャラリスト
# @desc     tContentsImageMからデータを取得する
# @param    
# @return   
#******************************************************
sub viewlist_contents_by_c :Method {
    my ($self, $c, $args) = @_;

    my $return_obj      = {};
    my $q               = $c->query();
    my $a               = $q->param('a');
    my $o               = $q->param('o');
    my $category_id     = $q->param('c');
    my $offset          = $q->param('off') || 0;
    my $record_limit    = 9;
    my $condition_limit = $record_limit+1;

    my $dbh = $c->getDBConnection();
    $c->setDBCharset("sjis");
        ## 全レコード件数SQL
=pod
    my $myContents = MyClass::JKZDB::ContentsImage->new($dbh);
    my $maxrec = $myContents->getCountSQL(
                        {
                            columns     => 'contentsm_id',
                            whereSQL    => 'categorym_id=?',
                            #orderbySQL  => $orderby,
                            orderbySQL  => 'contentsm_id DESC',
                            limitSQL    => "$offset, $condition_limit",
                            placeholder => [$category_id],
                        }
                    );
=cut
    ## Modified 2011/05/09
    ## Modified 2011/05/19
=pod
    my $sql = sprintf("SELECT COUNT(i.contentsm_id)
 FROM tContentsImageM i, tContentsM c 
 WHERE i.contentsm_id=c.contents_id 
 AND c.status_flag=2 
 AND i.categorym_id=?
 ORDER BY contentsm_id DESC LIMIT %s, %s;", $offset, $condition_limit);
=cut
    my $sql = "SELECT COUNT(i.contentsm_id)
 FROM tContentsImageM i, tContentsM c 
 WHERE i.contentsm_id=c.contents_id 
 AND c.status_flag=2 
 AND i.categorym_id=?
 ORDER BY contentsm_id DESC;";

    my $maxrec = $dbh->selectrow_array($sql, undef, $category_id);


    my @navilink;
    ## レコード数が1ページ上限数より多い場合
    if ($maxrec > $record_limit) {
       my $url = sprintf("%sa=%s&o=%s&c=%s", $c->MAINURL, $a, $o, $category_id);

        ## 前へリンクの生成
        if (0 != $offset) { ## 最初のページじゃない場合（2ページ目以降の場合）
            $return_obj->{'If.PL.ExistsPreviousPage'} = 1;
            $return_obj->{'PL.PreviousPageUrl'}       = sprintf("%s&off=%s", $url, ($offset - $record_limit));
        }

        ## 次へリンクの生成
        if (($offset + $record_limit) < $maxrec) {
            $return_obj->{'If.PL.ExistsNextPage'} = 1;
            $return_obj->{'PL.NextPageUrl'}       = sprintf("%s&off=%s", $url, ($offset + $record_limit));
        }

        ## ページ番号生成
        for (my $i = 0; $i < $maxrec; $i += $record_limit) {

            my $pageno = int ($i / $record_limit) + 1;

            if ($i == $offset) { ###現在表示してるﾍﾟｰｼﾞ分
                push (@navilink, $pageno);
            } else {
                my $pagenate_url = sprintf("%s&off=%s", $url, $i);
                push (@navilink, $q->a({-href=>$pagenate_url}, $pageno));
            }
        }
        @navilink = map{ "$_\n" } @navilink;

        $return_obj->{'PL.pagenavi'} = join(' ', @navilink);
    }

    $return_obj->{totalrecord} = $maxrec;

=pod
    my $myContentsList = MyClass::JKZDB::ContentsImage->new($dbh);
    $myContentsList->getSpecificValuesSQL({
                        columnslist => ['contentsm_id', 'contentsm_name', 'categorym_id'],
                        whereSQL    => 'categorym_id=?',
                        orderbySQL  => 'contentsm_id DESC',
                        limitSQL    => "$offset, $condition_limit",
                        placeholder => [$category_id],
    });
=cut
    $sql = sprintf("SELECT i.contentsm_id, i.contentsm_name, i.categorym_id 
 FROM tContentsImageM i, tContentsM c 
 WHERE i.contentsm_id=c.contents_id 
 AND c.status_flag=2 
 AND i.categorym_id=?
 ORDER BY contentsm_id DESC LIMIT %s, %s;", $offset, $condition_limit);
    my $aryref = $dbh->selectall_arrayref($sql, { Columns => {} }, $category_id);

    $return_obj->{'Loop.PL.ContentsList'} = ( $#{ $aryref } >= $record_limit ) ? $#{ $aryref } - 1 : $#{ $aryref };
    if (0 <= $return_obj->{'Loop.PL.ContentsList'}) {
        $return_obj->{'If.PL.ExistsContents'} = 1;
        for (my $j = 0; $j <= $return_obj->{'Loop.PL.ContentsList'}; $j++) {

            map { $return_obj->{'PL.' . $_}->[$j] = $aryref->[$j]->{$_} } keys %{ $aryref->[$j] };

            if ( $return_obj->{'Loop.PL.ContentsList'} == $j ) {
                $return_obj->{'If.PL.TDandTDandTREnd'}->[$j] = 1 if ( 0 == $j % 3 );
                $return_obj->{'If.PL.TDandTREnd'}->[$j]      = 1 if ( 1 == $j % 3 );
            }
            $return_obj->{'If.PL.TREnd'}->[$j]   = 1 if ( 2 == $j % 3 );
            $return_obj->{'If.PL.TRBegin'}->[$j] = 1 if ( 0 == $j % 3 );

            $return_obj->{'PL.MAINURL'}->[$j]            = $c->MAINURL;
            $return_obj->{'PL.LMYPAGE_URL'}->[$j]        = $c->MYPAGE_URL;
            $return_obj->{'PL.LCONTENTS_SAMPLE_IMAGE_SCRIPTDATABASE_URL'}->[$j] = sprintf("%s%s", $c->MAIN_URL, $c->CONFIGURATION_VALUE('CONTENTS_SAMPLE_IMAGE_SCRIPTDATABASE_NAME'));
        }
    }

=pod
    $return_obj->{'Loop.PL.ContentsList'} = ( $#{ $myContentsList->{columnslist}->{contentsm_id} } >= $record_limit ) ? $#{ $myContentsList->{columnslist}->{contentsm_id} } - 1 : $#{ $myContentsList->{columnslist}->{contentsm_id} };

    if (0 <= $return_obj->{'Loop.PL.ContentsList'}) {
        $return_obj->{'If.PL.ExistsContents'} = 1;
        for (my $j = 0; $j <= $return_obj->{'Loop.PL.ContentsList'}; $j++) {

            map { $return_obj->{'PL.' . $_}->[$j] = $myContentsList->{columnslist}->{$_}->[$j] } keys %{ $myContentsList->{columnslist} };

            if ( $return_obj->{'Loop.PL.ContentsList'} == $j ) {
                $return_obj->{'If.PL.TDandTDandTREnd'}->[$j] = 1 if ( 0 == $j % 3 );
                $return_obj->{'If.PL.TDandTREnd'}->[$j]      = 1 if ( 1 == $j % 3 );
            }
            $return_obj->{'If.PL.TREnd'}->[$j]   = 1 if ( 2 == $j % 3 );
            $return_obj->{'If.PL.TRBegin'}->[$j] = 1 if ( 0 == $j % 3 );

            $return_obj->{'PL.MAINURL'}->[$j]            = $c->MAINURL;
            $return_obj->{'PL.LCONTENTS_SAMPLE_IMAGE_SCRIPTDATABASE_URL'}->[$j] = sprintf("%s%s", $c->MAIN_URL, $c->CONFIGURATION_VALUE('CONTENTS_SAMPLE_IMAGE_SCRIPTDATABASE_NAME'));
        }
    }
=cut
    else {
        $return_obj->{'If.PL.NotExistsContents'} = 1;
    }
    #undef $myContentsList;

    my $categorylist = $c->getFromObjectFile( { CONFIGURATION_VALUE => 'CATEGORYLIST_OBJ' } );

    $return_obj->{'Loop.PL.CategoryList'}  = $#{ $categorylist } - 1;
    map {
        $return_obj->{'PL.category_id'}->[$_]      = $categorylist->[$_+1]->{'category_id'};
        $return_obj->{'PL.category_name'}->[$_]    = $categorylist->[$_+1]->{'category_name'};
        $return_obj->{'PL.LCATEGORYMAINURL'}->[$_] = $c->MAINURL;
        ( $category_id == $categorylist->[$_+1]->{'category_id'} ) ? $return_obj->{'If.PL.CategoryOnFocus'}->[$_] = 1 : $return_obj->{'If.PL.CategoryNotFocus'}->[$_] = 1;

    } 0..$return_obj->{'Loop.PL.CategoryList'};


    return $return_obj;
}


#******************************************************
# @access	public
# @desc		コンテンツ全文検索
# @param	strings
# @return	
#******************************************************
=pod
sub search_contents :Method {
    my ($self, $c, $args) = @_;

    my $return_obj      = {};
    my $q               = $c->query();
    my $a               = $q->param('a');
    my $o               = $q->param('o');
    my $offset          = $q->param('off') || 0;
    my $record_limit    = 6;
    my $condition_limit = $record_limit+1;

    #****************************
    # 呼び出しが会員からか非会員からの判定
    #****************************
    my $is_called_from_member    = $c->user_is_member ? 1 : 0;
    my $MEMBERMAINURL_OR_MAINURL = ( 0 < $c->user_is_member ) ? $c->MEMBERMAINURL : $c->MAINURL;

    #*********************************
    # 全文検索条件SQLの生成
    #*********************************

    if ($q->param('keyword')) {
        my ($keyword, $opt, $exclusion, $multicondition);
        $return_obj->{'PL.keyword'} = $q->param('keyword');
        $opt        = $q->param('opt') || 1;

         #*********************************
         # キーワードが複数の場合でAND検索時はスペースを+に置き換え
         #*********************************
         ## 全角スペースはカンマに変換
         $keyword = MyClass::WebUtil::convertSZSpace2C($q->param('keyword'));
         2 == $q->param('opt') ? $keyword =~ s!,! \+!g : $keyword =~ s!,! !g;

         #*********************************
         # マルチセクション全文検索構文生成
         #*********************************
         $multicondition = sprintf("*W1,2 %s%s ", $keyword);




        my $dbh = $c->getDBConnection();
#        $dbh->trace(2, '/home/vhosts/DENISMCD/JKZ/tmp/DBITrace.log');
        $c->setDBCharset("sjis");

        ## 全レコード件数SQL
        my $myContents = MyClass::JKZDB::Contents->new($dbh);
        my $maxrec = $myContents->getCountSQL(
                        {
                        columns     => 'contents_id',
                        whereSQL    => 'status_flag=? AND MATCH(contents_name, description) AGAINST(? IN BOOLEAN MODE)',
                        orderbySQL  => 'subcategorym_id DESC',
                        limitSQL    => "$offset, $condition_limit",
                        placeholder => [2, $multicondition],
                        }
                    );

        my @navilink;
        ## レコード数が1ページ上限数より多い場合
        if ($maxrec > $record_limit) {
           my $url = sprintf("%sa=%s&o=%s&keyword=%s&opt=%s", $MEMBERMAINURL_OR_MAINURL, $a, $o, $return_obj->{'PL.keyword'}, $opt);

            ## 前へリンクの生成
            if (0 != $offset) { ## 最初のページじゃない場合（2ページ目以降の場合）
                $return_obj->{'If.PL.ExistsPreviousPage'} = 1;
                $return_obj->{'PL.PreviousPageUrl'}       = sprintf("%s&off=%s", $url, ($offset - $record_limit));
            }

            ## 次へリンクの生成
            if (($offset + $record_limit) < $maxrec) {
                $return_obj->{'If.PL.ExistsNextPage'} = 1;
                $return_obj->{'PL.NextPageUrl'}       = sprintf("%s&off=%s", $url, ($offset + $record_limit));
            }

            ## ページ番号生成
            for (my $i = 0; $i < $maxrec; $i += $record_limit) {

                my $pageno = int ($i / $record_limit) + 1;

                if ($i == $offset) { ###現在表示してるﾍﾟｰｼﾞ分
                    push (@navilink, $pageno);
                } else {
                    my $pagenate_url = sprintf("%s&off=%s", $url, $i);
                    push (@navilink, $q->a({-href=>$pagenate_url}, $pageno));
                }
            }
            @navilink = map{ "$_\n" } @navilink;

            $return_obj->{'PL.pagenavi'} = join(' ', @navilink);
        }

        $return_obj->{totalrecord} = $maxrec;

        my $myContentsList = MyClass::JKZDB::Contents->new($dbh);
        $myContentsList->getSpecificValuesSQL({
                            columnslist => ['contents_id', 'contents_name', 'categorym_id', 'subcategorym_id'],
                            whereSQL    => 'status_flag=? AND MATCH(contents_name, description) AGAINST(? IN BOOLEAN MODE)',
                            orderbySQL  => 'subcategorym_id DESC',
                            limitSQL    => "$offset, $condition_limit",
                            placeholder => [2, $multicondition],
        });



        $return_obj->{'Loop.PL.SearchContentsList'} = ( $#{ $myContentsList->{columnslist}->{contents_id} } >= $record_limit ) ? $#{ $myContentsList->{columnslist}->{contents_id} } - 1 : $#{ $myContentsList->{columnslist}->{contents_id} };

         if (0 <= $return_obj->{'Loop.PL.SearchContentsList'}) {
            $return_obj->{'If.PL.ExistsSearchContents'} = 1;
            map {
                foreach my $key (keys %{ $myContentsList->{columnslist} }) {
                    #$return_obj->{'PL' . $key}->[$_] = $contentsref->{$key}->[$_];
                    $return_obj->{'PL.' . $key}->[$_] = $myContentsList->{columnslist}->{$key}->[$_];
                }
            $return_obj->{'PL.LMEMBERMAINURL_OR_MAINURL'}->[$_] = $MEMBERMAINURL_OR_MAINURL;
            $return_obj->{'PL.LCONTENTS_SAMPLE_IMAGE_SCRIPTDATABASE_URL'}->[$_] = $c->CONFIGURATION_VALUE('CONTENTS_SAMPLE_IMAGE_SCRIPTDATABASE_NAME');

            $return_obj->{'If.PL.TRBegin'}->[$_]    = ( 0 == $_ % 3 ) ? 1 : 0;
            $return_obj->{'If.PL.TREnd'}->[$_]      = ( 2 == $_ % 3 ) ? 1 : 0;
            $return_obj->{'If.PL.TDandTREnd'}->[$_] = ( ( $return_obj->{'Loop.PL.SearchContentsList'} == $_ ) && ( 1 == $_ % 3 ) ) ? 1 : 0;

            } 0..$return_obj->{'Loop.PL.SearchContentsList'};

        } else {
            $return_obj->{'If.PL.NotExistsSearchContents'} = 1;
        }


    }

	return $return_obj;
}
=cut


sub class_component_plugin_attribute_detect_cache_enable { 0 }

1;