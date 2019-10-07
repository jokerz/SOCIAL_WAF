#******************************************************
# @desc      MyPageのクラス
# @desc      マイページの情報やフラッシュゲーム処理、ユーザーアクション全般
#
# @package   MyClass::Gree::MyPage
# @access    public
# @author    Iwahase Ryo
# @create    2011/03/30
# @update    
# @version    1.00
#******************************************************
package MyClass::Gree::MyPage;

use strict;
use warnings;
no warnings 'redefine';
use 5.008005;
our $VERSION = '1.00';

use base qw(MyClass::Gree);

use MyClass::WebUtil;
use MyClass::JKZSession;
use MyClass::JKZDB::GsaUserFlashGameLog;
use MyClass::JKZDB::GsaUserPowerLog;
use MyClass::JKZDB::GsaUserStatus;
use MyClass::JKZDB::Contents;
use MyClass::JKZDB::Item;
use MyClass::JKZDB::MyItem;
use MyClass::JKZDB::GsaUserGachaLog;
use MyClass::JKZDB::MyContentsStatus;
use MyClass::JKZDB::MyLibrary;

use JSON;
use JSON::XS;

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


=pod
sub run {
    my $self = shift;

    $self->SUPER::run();
}
=cut

#******************************************************
# @access   親のメソッドをオーバーライド
# @desc     
# @param    
# @param    
# @return   
#******************************************************
sub run {
    my $self = shift;
    my $obj  = {};

    $self->setAccessUserData();
    $self->connectDB();

    $self->memcached();
    $self->setMicrotime("t0");

    my $method;
#$self->fcheck_flash_game;
    #******************************************************
    # oauth_signatureの検証OKの場合のみ
    #******************************************************

## fcheck とfstopは画面遷移がないので認証はパス
#unless ("fchech_flash_game" eq $self->action) {}

    if ($self->query->param('a') eq 'fcheck' || $self->query->param('a') eq 'fstop') {
        $method = $self->action;
        $self->$method();
    }
    else {
        unless ($self->__verify_oauth_signature()) {
            $obj = $self->oauth_verification_failure();
        } else {
            $self->userid_ciphered();
            $method = $self->action();
            $method  ||= $self->action('gree_default');
            $obj       =
                exists ($self->class_component_methods->{$method}) ? $self->call($method) :
                $self->can($method)                                ? $self->$method()     :
                                                                     $self->printErrorPage("invalid method call");

            #*****************************
            # 定数として
            #*****************************
            $obj->{MAINURL}             = $self->MAINURL;
            $obj->{MYPAGE_URL}          = $self->MYPAGE_URL;
            $obj->{OTHERPAGE_URL}       = $self->OTHERPAGE_URL;
            $obj->{MY_ITEMBOX_URL}      = $self->MY_ITEMBOX_URL;
            $obj->{MY_STOPWATCH_URL}    = $self->MY_STOPWATCH_URL;
            $obj->{MY_LIBRARY_URL}      = $self->MY_LIBRARY_URL;
            $obj->{MY_GETIMAGE_URL}     = $self->MY_GETIMAGE_URL;
            $obj->{ITEMSHOP_URL}        = $self->ITEMSHOP_URL;
            $obj->{ITEMEXCHANGE_URL}    = $self->ITEMEXCHANGE_URL;

            $obj->{SITEIMAGE_SCRIPTDATABASE_URL} = sprintf("%s%s", $self->MAIN_URL, $self->CONFIGURATION_VALUE('SITEIMAGE_SCRIPTDATABASE_NAME'));
            $obj->{ITEMIMAGE_SCRIPTDATABASE_URL} = $self->ITEMIMAGE_SCRIPTDATABASE_URL;
            $obj->{CONTENTS_SAMPLE_IMAGE_SCRIPTDATABASE_URL} = sprintf("%s%s", $self->MAIN_URL, $self->CONFIGURATION_VALUE('CONTENTS_SAMPLE_IMAGE_SCRIPTDATABASE_NAME'));
            $obj->{CONTENTS_IMAGE_SCRIPTDATABASE_URL}        = sprintf("%s%s", $self->MAIN_URL, $self->CONFIGURATION_VALUE('CONTENTS_IMAGE_SCRIPTDATABASE_NAME'));
            $obj->{LIBRARY_IMAGE_SCRIPTDATABASE_URL}         = sprintf("%s%s", $self->MAIN_URL, $self->CONFIGURATION_VALUE('LIBRARY_IMAGE_SCRIPTDATABASE_NAME'));
            $obj->{DEGREE_IMAGE_SCRIPTDATABASE_URL}          = sprintf("%s%s", $self->MAIN_URL, $self->CONFIGURATION_VALUE('DEGREE_IMAGE_SCRIPTDATABASE_NAME'));

            $obj->{FLASH_SCRIPTFILE_URL}           = sprintf("%s%s", $self->MAIN_URL, $self->CONFIGURATION_VALUE('FLASH_SCRIPTFILE_NAME'));
            $obj->{opensocial_app_id}            = $self->opensocial_app_id;
            $obj->{opensocial_viewer_id}         = $self->opensocial_viewer_id;
            $obj->{opensocial_owner_id}          = $self->opensocial_owner_id;

            # Modified 2011/05/10
            $obj->{GACHA_URL}           = sprintf("%s/gacha.swf?s=%s", $self->MAIN_URL, $self->userid_ciphered);

            #************************
            # 各ログ収集
            #************************
            my $logger     = MyClass::JKZGsaLogger->new({ gree_user_id => $self->opensocial_viewer_id });
            $logger->saveLoginLog      if 'enter_top' eq $self->action(); ## 会員はmethod がmember_defaultの場合にログインログを取得
            $logger->closeLogger();
        }
    }

  #************************
  # サイト名
  #************************
    $obj->{SITE_NAME} = MyClass::WebUtil::convertByNKF('-s', $self->cfg->param('SITE_NAME'));

  #************************
  # キャリア判定
  #************************
    1 == $self->user_carriercode ? $obj->{IfDoCoMo}      = 1 :
    2 == $self->user_carriercode ? $obj->{IfSoftBank}    = 1 :
    3 == $self->user_carriercode ? $obj->{IfAu}          = 1 :
                                   $obj->{IfIsNonMobile} = 1 ;

  #************************
  ## フッター処理
  #************************
    my $footer_tags = {
        MAINURL          => undef,
        MYPAGE_URL       => undef,
        MY_ITEMBOX_URL   => undef,
        MY_STOPWATCH_URL => undef,
        MY_LIBRARY_URL   => undef,
        MY_GETIMAGE_URL  => undef,
        ITEMSHOP_URL     => undef,
        ITEMEXCHANGE_URL => undef,
        SITE_NAME        => undef,
        IfDoCoMo         => undef,
        IfSoftBank       => undef,
        IfAu             => undef,
    };

    map { exists($obj->{$_}) ? $footer_tags->{$_} = $obj->{$_} : delete $footer_tags->{$_} } keys %{ $footer_tags };

    my $tmpobj          = $self->_getDBTmpltFileByName('FOOTER_HTML');
    my $footer_obj      = MyClass::JKZHtml->new({}, $tmpobj, 1, 0);
    $obj->{FOOTER_HTML} = $footer_obj->convertHtmlTags( $footer_tags );

    if ($self->query->param('a') ne 'fcheck') {#|| $self->query->param('a') ne 'fstop') {
        $self->processHtml($obj);
    }

    $self->disconnectDB();
}


#******************************************************
# @access    public
# @desc      公開情報設定
# @param    
# @return    
#******************************************************
sub view_mypage {
    my $self = shift;

    my $gree_user_id = $self->opensocial_owner_id;
    my $api_key      = 'gsa';
    my $namespace    = sprintf("%s_%s_me_self", $self->waf_name_space(), $api_key);

    my $obj       =  $self->memcached->get("$namespace:$gree_user_id");

    if (!$obj) {
        $self->makeRequest2PeopleAPI();
        $obj =  $self->memcached->get("$namespace:$gree_user_id");
    }
    
    #************************
    # ユーザーのパワーなどのステータスじょうほう
    #************************
    my $userstatusobj = $self->gsaUserStatus();
    map { $obj->{$_} = $userstatusobj->{$_} } keys %{ $userstatusobj };

    # get画像がある場合のみ画像を取得
    if (0 < $obj->{my_getimage_total}) {
        my $myFlashGameLog = MyClass::JKZDB::GsaUserFlashGameLog->new($self->getDBConnection);
        my @getimages = $myFlashGameLog->getUserGetImages({
            gree_user_id    => $gree_user_id,
            orderbySQL      => 'lastupdate_date DESC',
            limitSQL        => '4',
        });
        if (3 < scalar @getimages) {
            $obj->{IfExistsMoreMyGetImage} = 1;
        }
        $obj->{LoopRecMyGetImageList} = 3 > $#getimages ? $#getimages : 2;
        map {
            $obj->{my_getimage_id}->[$_] = $getimages[$_];
            $obj->{LMYPAGE_URL}->[$_] = $self->MYPAGE_URL;
            $obj->{LMYCONTENTS_IMAGE_SCRIPTDATABASE_URL}->[$_] = sprintf("%s%s", $self->MAIN_URL, $self->CONFIGURATION_VALUE('CONTENTS_IMAGE_SCRIPTDATABASE_NAME'));
         } 0..$#getimages;

        $obj->{IfExistsMyGetImage} = 1;
    }
    else {
        $obj->{IfNotExistsMyGetImage} = 1;
    }

    # 図鑑
    my $myLibrary    = MyClass::JKZDB::MyLibrary->new($self->getDBConnection);
    $self->setDBCharset("sjis");
    my $mylibraryobj = $myLibrary->getSpecificValuesSQL({
        columnslist => ['my_library_id', 'my_library_name'],
        whereSQL    => 'gree_user_id=? AND status_flag IN(1,2)',
        placeholder => [$gree_user_id]
    });

    #if (0 > scalar @{ $mylibraryobj->{my_library_id} }) {
    if (!$mylibraryobj) {
        $obj->{IfNotExistsMyLibrary} = 1;
    }
    else {
        $obj->{IfExistsMyLibrary} = 1;
        $obj->{LoopMyLibraryList} = $#{ $mylibraryobj->{my_library_id} };
        my $library_url           = sprintf("%s%s", $self->MAIN_URL, $self->CONFIGURATION_VALUE('LIBRARY_IMAGE_SCRIPTDATABASE_NAME'));
        map {
            $obj->{my_library_id}->[$_]     = $mylibraryobj->{my_library_id}->[$_];
            $obj->{my_library_name}->[$_]   = $mylibraryobj->{my_library_name}->[$_];
            $obj->{LMY_LIBRARY_URL}->[$_]   = $library_url;
        } 0..$obj->{LoopMyLibraryList};
    }




    # コンテンツの総数
    my $contentsobj = $self->getFromObjectFile({ CONFIGURATION_VALUE => 'ACTIVECONTENTSLIST_OBJ' });
    $obj->{contents_total} = $#{ $contentsobj } + 1;

    #************************
    # グリー友達情報取得
    #************************
    my $friendobj = $self->getFriendsDataFromPeopleAPI();
    map { $obj->{$_} = $friendobj->{$_} } keys %{ $friendobj };

    my $dbh     = $self->getDBConnection();
    $self->setDBCharset("sjis");

	## 本日のガチャ確認 (ガチャ済みは戻りが1)
	my $myGacha = MyClass::JKZDB::GsaUserGachaLog->new($dbh);
	!$myGacha->checkGachaToday($gree_user_id) ? $obj->{IfGachaForToday} = 1 : $obj->{IfGachaNoMoreForToday} = 1;

    # get画像枚数ランキング
    # plugin にて実装

    return $obj;
}


#******************************************************
# @access    public
# @desc      ゆーざーのステータス
# @param    
# @return    hashobj power stopwatch_id latest_flashgame_record_time my_getimage_total my_completecharacter_total tomemoeLv compmoeLv my_nick_name
#******************************************************
sub gsaUserStatus {
    my $self = shift;
    my $obj  = {};
    my $gree_user_id;
    my $hash_key;
    my $namespace;

    # 引数があれば引数のgree_user_idのステータスを取得してなければ現在のgree_user_idのステータス
    if (0 < @_) {
        $gree_user_id   = shift;
        $hash_key       = 'other_'; ## 他ユーザーを示すため
        $namespace      = sprintf("%s_%s_userstatus", $self->waf_name_space(), $hash_key);## ぱわーやレベルなどのステータス
    } else {
        $gree_user_id   =  $self->opensocial_viewer_id;
        ## ぱわーやレベルなどのステータス
        $namespace      = sprintf("%s_userstatus", $self->waf_name_space());
        undef $hash_key; #undefしておく
    }

    $obj = $self->memcached->get("$namespace:$gree_user_id");

    if (!$obj) {
        my $dbh = $self->getDBConnection();
        $self->setDBCharset("sjis");

    #**************************
    # とりえづは通常の処理を行ってからキーを追加
    #**************************
        my $myStatus = MyClass::JKZDB::GsaUserStatus->new($dbh);
        $myStatus->executeSelect({ whereSQL => 'gree_user_id=?', placeholder => [$gree_user_id] });

        map { $obj->{$_} = $myStatus->{columns}->{$_} } keys %{ $myStatus->{columns} };
        $obj->{my_latest_flashgame_record_time} = '---' if "" eq $obj->{my_latest_flashgame_record_time};
        $obj->{my_stopwatch_id} = '6001' if "" eq $obj->{my_stopwatch_id};
        $obj->{my_stopwatch_name} = 'Default' if "" eq $obj->{my_stopwatch_name};

#**************************
# ここから下は例外的に処理をする。本来はGsaUserStatusから値を取得するべきだが値が格納されてないので関連テーブル等から取得
# 上記で取得した値を上書きする
#**************************
        # コンプリート済みコンテンツのIDを取得
        my $myContents          = MyClass::JKZDB::MyContentsStatus->new($self->getDBConnection);
        my @completedcontents   = $myContents->fetchCompleteContents($gree_user_id);
        # GsaUserStatusにｺﾝﾌﾟﾘｰﾄ数のカラムがあるが値を格納する処理がないのでｺﾝﾌﾟﾘｰﾄ済みIDの配列から別途取得する
        $obj->{my_completecharacter_total} = scalar @completedcontents;

    #*************************
    # ステータスバーをグラフにするための処理 BEGIN
    #*************************
        # my_powerの小数点値をグラフに合わせる調整
        $obj->{my_power_graph_id} = convert2graph_id($obj->{my_power});

        # Modified 2011/06/09 compmoeLvはここで調整（データベースに無駄な負荷がかかるため）
        # my_compmoeLvを上書き
        $obj->{my_compmoeLv} = 
            50 <= $obj->{my_completecharacter_total} ? 10 :
            44 < $obj->{my_completecharacter_total}  ? 9 :
            39 < $obj->{my_completecharacter_total}  ? 8 :
            34 < $obj->{my_completecharacter_total}  ? 7 :
            29 < $obj->{my_completecharacter_total}  ? 6 :
            24 < $obj->{my_completecharacter_total}  ? 5 :
            19 < $obj->{my_completecharacter_total}  ? 4 :
            9 < $obj->{my_completecharacter_total}   ? 3 :
            2 < $obj->{my_completecharacter_total}   ? 2 :
                                                       1 ;

        $obj->{my_tomemoeLv_graph_id}  = ($obj->{my_tomemoeLv} + 83);
        $obj->{my_compmoeLv_graph_id}  = ($obj->{my_compmoeLv} + 93);
    #*************************
    # ステータスバーをグラフにするための処理 END
    #*************************

        # GsaUserStatusに合計GET画像数カラムがあるが値を格納するしょりがないのでゲームログから取得
        my $myFlashGameLog          = MyClass::JKZDB::GsaUserFlashGameLog->new($self->getDBConnection);
        $obj->{my_getimage_total}   = $myFlashGameLog->getUserGetImageTotal($gree_user_id) || 0;

#  <----ここまで

        if (defined($hash_key)) {
            map {
                $obj->{$hash_key . $_} = $obj->{$_};
                delete $obj->{$_}; # 不要なメモリを開放
            } keys %{ $obj };

            #**************************
            # getNickNameFromPeopleAPIメソッドからのオブジェクト
            #   gsa_other_id
            #   gsa_other_nickname
            #   gsa_other_displayName
            #   gsa_other_aboutMe
            #   gsa_other_birthday
            #   gsa_other_addresses
            #   gsa_other_age
            #   gsa_other_bloodType
            #   gsa_other_userHash
            #   gsa_other_userType
            #   gsa_other_profileUrl
            #   gsa_other_thumbnailUrlSmall
            #   gsa_other_thumbnailUrlHuge
            #**************************
            my $tmphash = $self->getNickNameFromPeopleAPI($gree_user_id);
            $obj->{gsa_other_nickname}          = $tmphash->{gsa_other_nickname};
            $obj->{gsa_other_thumbnailUrlLarge} = $tmphash->{gsa_other_thumbnailUrlLarge};
            $obj->{gsa_other_profileUrl}        = $tmphash->{gsa_other_profileUrl};
        }

        $self->memcached->add("$namespace:$gree_user_id", $obj, 600);
    }

    return $obj;
}


#******************************************************
# @access   public
# @desc     
# @param    
# @return   
#******************************************************
sub getFriendsDataFromPeopleAPI {
    my $self         = shift;
    my $obj          = {};
    my $api_key      = 'gsa';
    ## アプリを使用してるユーザーの友達情報
    my $namespace    = sprintf("%s_%s_me_all", $self->waf_name_space(), $api_key);
    my $gree_user_id = $self->opensocial_viewer_id;
    $obj             = $self->memcached->get("$namespace:$gree_user_id");

    my $consumer_key    = $self->cfg->param('CONSUMERKEY');
    my $consumer_secret = $self->cfg->param('CONSUMERSECRET');
    #************************
    # cacheにユーザー本人情報がない場合はAPIにリクエスト
    #************************
    if (!$obj) {

        #my $api_endpoint = sprintf("%s/\@me/\@all?fields=nickname,profileUrl,thumbnailUrl&count=5", $self->cfg->param('GREE_PEOPLE_API_ENDPOINT'));
        my $api_endpoint = sprintf("%s/\@me/\@all", $self->cfg->param('GREE_PEOPLE_API_ENDPOINT'));

        my $request_url = $api_endpoint;
        my $consumer    = OAuth::Lite::Consumer->new(
            consumer_key         => $consumer_key,
            consumer_secret      => $consumer_secret,
            realm                => '',
        );

        my $res         = $consumer->request(
            method => 'GET',
            url    => $request_url,
            params => {
                        xoauth_requestor_id  => $self->opensocial_viewer_id,
                        opensocial_owner_id  => $self->opensocial_owner_id,
                        opensocial_app_id    => $self->opensocial_app_id,
                        opensocial_viewer_id => $self->opensocial_viewer_id,
                     },
        );

        #use Encode;
        #my $result = JSON->new->utf8(0)->decode(decode_utf8($res->decoded_content));
        my $result            = JSON::XS::decode_json($res->decoded_content);
        if ($result->{Error}) {
            warn encode('utf-8', $result->{Error}{Message}), "\n";
        }
        else {
            #*********************************
            # グリーのAPIデータと置換文字の設定
            # 置き換え文字はgsa_xxxyy
            #*********************************
            $api_key .= '_friend_';
            $obj->{LoopMyFriendList} = (3 <= $result->{totalResults}) ? 2 : $result->{totalResults} - 1;

            map {
                my $cnt = $_;
                foreach my $key (keys %{ $result->{entry} }) {
                    $obj->{$api_key . $key}->[$cnt] = MyClass::WebUtil::convertByNKF('-s', $result->{entry}->[$cnt]->{$key});
                    $obj->{LOTHERPAGE_URL}->[$cnt]  = $self->OTHERPAGE_URL;
                }
                $cnt++;
            } 0..$obj->{LoopMyFriendList};#0..$result->{totalResults} - 1;

            #*********************************
            # cacheの名前空間 gsa_me_self:{id}
            #*********************************
            #my $namespace = $self->waf_name_space() . '_me_self';
            $self->memcached->add("$namespace:$gree_user_id", $obj, 1800);

        }
    }

    return $obj;
}



#******************************************************
# @desc     萌えぷちユーザーのニックネームをAPIから取得
# @param    gree_user_id(toid)
# @param    名前空間 gsa_other_user_nickname
#
# APIから取得するデータ
# %&gsa_other_user_id&%
# %&gsa_other_user_nickname&%
# %&gsa_other_user_displayName&%
# %&gsa_other_user_aboutMe&%
# %&gsa_other_user_birthday&%
# %&gsa_other_user_addresses&%
# %&gsa_other_user_age&%
# %&gsa_other_user_bloodType&%
# %&gsa_other_user_userHash&%
# %&gsa_other_user_userType&%
# %&gsa_other_user_profileUrl&%
# %&gsa_other_user_thumbnailUrlSmall&%
# %&gsa_other_user_thumbnailUrlHuge&%
# 
# 
# 
#
#
# @return   
#******************************************************
sub getNickNameFromPeopleAPI {
    my $self         = shift;
    my $toid         = shift;
    my $obj          = {};

    return if !$toid;

    my $api_key      = 'gsa';
    ## アプリを使用してるユーザーのニックネーム
    my $namespace    = sprintf("%s_%s_other_nickname", $self->waf_name_space(), $api_key);
    $obj             = $self->memcached->get("$namespace:$toid");

    #************************
    # cacheにユーザー情報がない場合はAPIにリクエスト
    #************************
    if (!$obj) {
        #my $api_endpoint    = sprintf("%s/\@me/\@all/%s", $self->cfg->param('GREE_PEOPLE_API_ENDPOINT'), $toid);
        my $api_endpoint    = sprintf("%s/%s/\@self", $self->cfg->param('GREE_PEOPLE_API_ENDPOINT'), $toid);
        my $gree_user_id    = $self->opensocial_viewer_id;
        my $consumer_key    = $self->cfg->param('CONSUMERKEY');
        my $consumer_secret = $self->cfg->param('CONSUMERSECRET');
        my $request_url     = $api_endpoint;
        my $consumer        = OAuth::Lite::Consumer->new(
                                 consumer_key         => $consumer_key,
                                 consumer_secret      => $consumer_secret,
                                 realm                => '',
                             );

        my $res             = $consumer->request(
                                method => 'GET',
                                url    => $request_url,
                                params => {
                                            xoauth_requestor_id  => $self->opensocial_viewer_id,
                                            opensocial_owner_id  => $self->opensocial_owner_id,
#                                            opensocial_app_id    => $self->opensocial_app_id,
#                                            opensocial_viewer_id => $self->opensocial_viewer_id,
                                         },
                            );

        my $result            = JSON::XS::decode_json($res->decoded_content);
        if ($result->{Error}) {

            warn encode('utf-8', $result->{Error}{Message}), "\n";
        }
        else {
            #*********************************
            # グリーのAPIデータと置換文字の設定
            # 置き換え文字はgsa_xxxyy
            #*********************************
            $api_key .= '_other_';
            map { $obj->{$api_key . $_} = MyClass::WebUtil::convertByNKF('-s', $result->{entry}{$_} ) } keys %{ $result->{entry} };
            #*********************************
            # cacheの名前空間 gsa_user_nickname:{id}
            #*********************************
            $self->memcached->add("$namespace:$toid", $obj, 1800);
        }
=pod
        #use Encode;
        #my $result = JSON->new->utf8(0)->decode(decode_utf8($res->decoded_content));
        #$req->content(JSON->new->latin1->encode($data));
        my $result            = JSON::XS::decode_json($res->decoded_content);
        if ($result->{Error}) {
            warn encode('utf-8', $result->{Error}{Message}), "\n";
        }
        else {
            #*********************************
            # グリーのAPIデータと置換文字の設定
            # 置き換え文字はgsa_xxxyy
            #*********************************
            $api_key .= '_other_';
            map { $obj->{$api_key . $_} = MyClass::WebUtil::convertByNKF('-s', $result->{entry}->[0]{$_} ) } keys %{ $result->{entry}->[0] };
            #*********************************
            # cacheの名前空間 gsa_user_nickname:{id}
            #*********************************
            $self->memcached->add("$namespace:$toid", $obj, 1800);
        }
=cut
    }

    return $obj;
}





#******************************************************
# @desc     マイアイテムボックス
# @param    重要事項：キャッシュの利用でアイテム購入、使用、一覧取得がうまく動かないから
# @param    一旦キャッシュの利用を停止 2011/04/26
#           関連行￥ 387 388 389 466行目付近
#           関連クラス ItemShop TestItemShop->finish_order
#
# @return   
#******************************************************
sub view_my_itembox {
    my $self = shift;
    my $q               = $self->query();
    my $gree_user_id    = $self->opensocial_owner_id;
    my $a               = $q->param('a');
    my $o               = $q->param('o');
    my $offset          = $q->param('off') || 0;
    my $record_limit    = 5;
    my $condition_limit = $record_limit+1;

    my $namespace       = $self->waf_name_space() . '_gsa_user_itembox';
    #my $obj             =  $self->memcached->get("$namespace:$gree_user_id:offest:$offset");
    ## Modified 2011/05/09 ページング時のキャッシュ操作がせいじょうではないでのキャシュやめ
    ## 関連部分は671行目
    #if (!$obj) {
    my $obj;
        my $dbh    = $self->getDBConnection();
        $self->setDBCharset("sjis");

    ## 全アイテム取得
        my $Item = MyClass::JKZDB::Item->new($dbh);
        my $maxrec = $Item->getCountSQL(
            {
                columns     => 'item_id',
                whereSQL    => 'status_flag=2 AND item_categorym_id IN(?,?,?,?,?)',
                orderbySQL  => 'item_categorym_id DESC',
                limitSQL    => "$offset, $condition_limit",
                placeholder => ["2000", "3000", "4000", "5000", "8000"],
            }
        );

        my @navilink;
        ## レコード数が1ページ上限数より多い場合
        if ($maxrec > $record_limit) {
           my $url = sprintf("%sa=%s&o=%s", $self->MY_ITEMBOX_URL, $a, $o);

            ## 前へリンクの生成
            if (0 != $offset) { ## 最初のページじゃない場合（2ページ目以降の場合）
                $obj->{'IfExistsPreviousPage'} = 1;
                $obj->{'PreviousPageUrl'}       = sprintf("%s&off=%s", $url, ($offset - $record_limit));
            }

            ## 次へリンクの生成
            if (($offset + $record_limit) < $maxrec) {
                $obj->{'IfExistsNextPage'} = 1;
                $obj->{'NextPageUrl'}       = sprintf("%s&off=%s", $url, ($offset + $record_limit));
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

            $obj->{'pagenavi'} = join(' ', @navilink);
        }

        my $sql = sprintf("SELECT
 i.item_name, i.item_id, i.item_categorym_id, i.item_description, COUNT(IF(m.gree_user_id=? AND m.status_flag=2, m.my_item_id, NULL)) AS QTY
 FROM %s.tItemM i LEFT JOIN %s.tMyItemF m
 ON (i.item_categorym_id+i.item_id)=m.itemm_id
 WHERE i.status_flag=2 AND i.item_categorym_id IN(?,?,?,?,?)
 GROUP BY i.item_categorym_id,i.item_id
 ORDER BY i.item_categorym_id DESC LIMIT %s, %s;", $self->waf_name_space, $self->waf_name_space, $offset, $condition_limit);

        my $aryref = $dbh->selectall_arrayref($sql, { Columns => {} }, $gree_user_id, "2000", "3000", "4000", "5000", "8000");

        $obj->{LoopMyItemList} = ( $#{$aryref} >= $record_limit ) ? $#{ $aryref } -1 : $#{ $aryref };
        map {
            my $cnt = $_;
            foreach my $key (keys %{ $aryref }) {
                $obj->{$key}->[$cnt]                            = $aryref->[$cnt]->{$key};
                $obj->{itemm_id}->[$cnt]                        = ($obj->{item_categorym_id}->[$cnt] + $obj->{item_id}->[$cnt]);
                $obj->{LITEMIMAGE_SCRIPTDATABASE_URL}->[$cnt]   = $self->ITEMIMAGE_SCRIPTDATABASE_URL();
                $obj->{LMYPAGE_URL}->[$cnt]                     = $self->MYPAGE_URL();
                $obj->{IfItemIsPower}->[$cnt]                   = 1 if "8000" == $obj->{item_categorym_id}->[$cnt] && 0 < $obj->{QTY}->[$cnt];
            }

        } 0..$obj->{LoopMyItemList};


        #$self->memcached->add("$namespace:$gree_user_id:offest:$offset", $obj, 6000);
#    }

    return $obj;
}


#******************************************************
# @desc     アイテムの使用
#           Getの場合アイテム使用確認 Postの場合はアイテムの使用実行
# @param    IfConfirmUserMyItem IfDoneUseMyItem
# @param    
# @return   
#******************************************************
sub use_my_item {
    my $self         = shift;
    my $gree_user_id = $self->opensocial_owner_id;
    my $q            = $self->query;

    my $obj = $self->gsaUserStatus;


    if (!$q->MethPost) {
        my $i = $q->param('i');

        if ("" eq $i || !$i) {
            $obj->{IfInvalidItemError} = 1;
            $self->action('error');
            return $obj;
        }

        $obj->{IfConfirmUserMyItem} = 1;

        my $dbh    = $self->getDBConnection();
        $self->setDBCharset("sjis");
        my $myItem = MyClass::JKZDB::MyItem->new($dbh);
        my $aryref = $myItem->fetchMyItemByItemID(
            {
                gree_user_id    => $gree_user_id,
                itemm_id        => $i,
                status_flag     => 2,
            }
        );
        map {
            my $cnt = $_;
            foreach my $key (keys %{ $aryref }) {
                $obj->{$key}->[$cnt]     = $aryref->[$cnt]->{$key};
                $obj->{itemm_id}->[$cnt] = $i;
            }
        } 0..$#{ $aryref };
        $obj->{LoopMyItemList} = $#{ $aryref };
        $obj->{Encodeditem_name} = $q->escape($obj->{item_name}->[0]);
    }
    if ($q->MethPost) {
        my $mii     = $q->param('mii');
        my ($my_item_id, $item_id) = split(/:/, $mii);
                                                    
        #**************************
        # item_idが8000番台の場合のアイテムはぱわぁ
        #**************************
        if ($item_id > 8000 && $item_id < 9000) {
            $obj->{ITEMISPOWER} = 1;

## アイテムのチェック
## アイテムの無効化
## ぱわぁログに追加
## ステータスの更新

            my $dbh      = $self->getDBConnection();
            $self->setDBCharset("sjis");
            my $attr_ref = MyClass::UsrWebDB::TransactInit($dbh);
            my $myItem   = MyClass::JKZDB::MyItem->new($dbh);

        #******************************
        # アイテムが使用可能かチェック
        # SELECT
        #******************************
            # アイテムは無効かない
            if (!$myItem->checkMyItemIfValid({my_item_id => $my_item_id, gree_user_id => $gree_user_id })) {
                $obj->{IfInvalidItemError} = 1;
                $self->action('error');
                return $obj;
            }

            # item_idが8001 8002 8003の場合はそれぞれ 1 2 5ぱわぁを追加する
            my $ADDPOWER =  8001 == $item_id ? 1 :
                            8002 == $item_id ? 2 :
                            8003 == $item_id ? 5 :
                                               0 ;

            my $UserPowerLog = MyClass::JKZDB::GsaUserPowerLog->new($dbh);
            my $UserStaus    = MyClass::JKZDB::GsaUserStatus->new($dbh);

            eval {
            #******************************
            # status_flagの値としてアイテム無効の１にする UPDATE
            #******************************
                $myItem->updateMyItemStatus({ my_item_id => $my_item_id, status_flag => 1 });

            #******************************
            # ぱぁーの増減ログ アイテム使用してのぱわぁの値は 2
            # INSERT
            #******************************
                $UserPowerLog->executeUpdate({
                    id              => -1,
                    gree_user_id    => $gree_user_id,
                    power           => $ADDPOWER,
                    type_of_power   => 2,
                    id_of_type      => $my_item_id,
                });
            
            #******************************
            # ユーザーのステータス情報更新
            # UPDATE
            #******************************
                $UserStaus->updateMyPower({
                    gree_user_id    => $gree_user_id,
                    my_power        => $ADDPOWER,
                }, 1);

                $dbh->commit();
            };
            if ($@) {
                $dbh->rollback();
                $obj->{IfUseMyItemError} = 1;
            }
            else {
                MyClass::UsrWebDB::TransactFin($dbh, $attr_ref, $@);
                #**************************
                # 使用完了変数
                #**************************
                $obj->{IfUseMyItemSuccess} = 1;
                $obj->{used_item_name}     = $q->param('Encodeditem_name');
                $obj->{used_item_name}     = $q->unescape($obj->{used_item_name});
            }

            undef $myItem;
            undef $UserPowerLog;
            undef $UserStaus;

            my $namespace           = $self->waf_name_space();
            my $namespace_userstaus = sprintf("%s_userstatus", $namespace);
            ## ユーザーステータスのキャッシュを削除
            $self->memcached->delete("$namespace_userstaus:$gree_user_id");
        }
    }

    $obj->{s}           = $self->userid_ciphered;

    return $obj;
}


#******************************************************
# @desc     ゲームに使用するアイテムの取得
# @param    
# @param    
# @return   
#******************************************************
sub fetchMyItemForFlashGame {
    my $self = shift;
    my $gree_user_id = $self->opensocial_owner_id;
    my $namespace    = $self->waf_name_space() . '_gsa_user_gameitem';
    my $obj          =  $self->memcached->get("$namespace:$gree_user_id");

    if (!$obj) {
        my $dbh    = $self->getDBConnection();
        $self->setDBCharset("sjis");
        my $myItem = MyClass::JKZDB::MyItem->new($dbh);
        my $aryref = $myItem->fetchMyItemForFlashGame($gree_user_id);
        if ( 0 <= $#{ $aryref } ) {
            map {
                my $cnt = $_;
                foreach my $key (keys %{ $aryref }) {
                    $obj->{$key}->[$cnt]    = $aryref->[$cnt]->{$key};
                }
            } 0..$#{ $aryref };

            $obj->{LoopMyItemForFlashGameList} = $#{ $aryref };
            $obj->{IfExistsMyItemForFlashGame} = 1;
        }
        else {
            $obj->{IfNotExistsMyItemForFlashGame} = 1;
        }

        $self->memcached->add("$namespace:$gree_user_id", $obj, 600);
    }

    return $obj;
}



#******************************************************
# Flashゲームに関するメソッド
#******************************************************

#******************************************************
# @access   FlashがPOSTに対応できないため処理追加
# @desc     
# @param    
# @param    
# @return   
#******************************************************
sub fplay_flash_game {
    my $self = shift;

    my $gree_user_id = $self->opensocial_owner_id;
    my $obj;

    my $q = $self->query;
    #if ($self->query->MethPost) {}



    my $namespace    = $self->waf_name_space();
    my $api_key      = 'gsa';
    my $namespace_gree_user  = sprintf("%s_%s_me_self", $namespace, $api_key);
    
    $obj                  = $self->memcached->get("$namespace_gree_user:$gree_user_id");

    if (!$obj) {
        $self->makeRequest2PeopleAPI();
        $obj =  $self->memcached->get("$namespace_gree_user:$gree_user_id");
    }

    #*************************************
    # ユーザーのステータス情報
    # %&my_power&%
    # %&my_stopwatch_id&%
    # %&my_latest_flashgame_record_time&%
    # %&my_getimage_total&%
    # %&my_completecharacter_total&%
    # %&my_tomemoeLv&%
    # %&my_compmoeLv&%
    #*************************************
    my $userstatusobj = $self->gsaUserStatus();
    map { $obj->{$_} = $userstatusobj->{$_} } keys %{ $userstatusobj };

    $obj->{my_power} < 1 ? $obj->{IfOutOfMyPower} = 1 : $obj->{IfEnoughOfMyPower} = 1;

    $obj->{my_power_graph_id} = convert2graph_id($obj->{my_power});

    my $character_id  = $self->query->param('p');
    ## キャラクタIDはcontents_id + : category_id でユニーク値を生成してある
    my ($contentsm_id, $categorym_id) = split(/:/, $character_id);

    unless ($contentsm_id) {
        my $msg = MyClass::WebUtil::convertByNKF('-s', $self->ERROR_MSG('ERR_MSG11'));
        return $self->printErrorPage($msg);
    }

    ## コンテンツのキャッシュをチェック
    my $namespace_contents = $namespace . 'contents';
    my $key        = $character_id;
    #my $key           = join (';', (int($contentsm_id), int($categorym_id)));
    my $contents_name = $self->memcached->get("$namespace_contents:$key");

    if (!$contents_name) {
        $self->setDBCharset("sjis");
        my $myContents = MyClass::JKZDB::Contents->new($self->getDBConnection());
        $contents_name = $myContents->is_Valid_Contents($contentsm_id);

        if ( !$contents_name || !defined($contents_name) ) {
            my $msg = MyClass::WebUtil::convertByNKF('-s', $self->ERROR_MSG('ERR_MSG11'));
            return $self->printErrorPage($msg);
        }

        $self->memcached->add("$namespace:$key", $contents_name, 3600);
    }

    $obj->{contents_name}   = $contents_name;
    $obj->{character_id}    = sprintf("%s:%s", $contentsm_id, $categorym_id);
    $obj->{EncodedNickName} = $self->query->escape($obj->{gsa_nickname});


    if ($q->param('go')) {
        my $mii = $q->param('mii');
        my ($my_item_id, $item_id);

        if ($mii eq "") {
            $item_id = '1001';
        }
        else {
            ($my_item_id, $item_id) = split(/:/, $mii);
        }
        my ($contents_id, $category_id) = split(/:/, $q->param('p'));
        my $stopwatch_id = $q->param('msi') || '6001';

        my $s   = $q->param('s');
        my $a   = $q->param('a');
        my $o   = $q->param('o');
        my $p   = $q->param('p');
        my $nn  = $q->param('nn');
        my $msi = $q->param('msi');

        ## Modified 2011/05/12 キャラのxy座標はパラメータからではだめ
        #my $xy  = $q->param('xy');
        ## ｷｬﾗ画像のxyの値をオブジェクトから取得
        my $contents_obj= $self->getFromObjectFile({ CONFIGURATION_VALUE => 'CONTENTSLIST_OBJ', subject_id=> $contents_id });

        my @tmp = split(/,/, $contents_obj->{make_set_xy_value});
        my @xy_value = map { log($_) / log(2) } @tmp; 
        my $xy = ( grep($_ == $category_id, @xy_value) ) ? 1 : 0;

        ## パラメータ値
        my $param  = sprintf("?s=%s&p=%s&mii=%s&msi=%s&a=%s&o=%s&nn=%s&xy=%s", $s, $p, $mii,$msi, $a, $o, $nn, $xy);

        my $swf_id = sprintf("%s:%03d%02d:%s", $item_id, $contents_id, $category_id, $stopwatch_id);

        ## パラメータ値
        $obj->{GETURLTOSWF} = sprintf("s=%s&p=%s&mii=%s&msi=%s&a=%s&o=%s&nn=%s&xy=%s", $s, $p, $mii,$msi, $a, $o, $nn, $xy);
        $obj->{IfPrintGetUrlToFlashGame} = 1;
        return $obj;
    }
    else {




    ## ゲームで使用できるアイテムリストの取得
    my $itemobj = $self->fetchMyItemForFlashGame();
    map { $obj->{$_} = $itemobj->{$_} } keys %{ $itemobj };


    $obj->{s} = $self->query->param('s');

    # アイテム選択画面
    $obj->{IfPrepareForFlashGame} = 1;

    #************************
    # 各コンテンツ閲覧ログ収集
    #************************
=pod
     my $logger = MyClass::JKZLogger->new({
         carrier       => $self->user_carriercode(),
         contents_id   => $contents_id,
         contents_name => $contents_name,
     });
     $logger->saveContentsViewLog();
     $logger->closeLogger();
=cut
    return $obj;

}
}


#******************************************************
# @access   
# @desc     
# @param    
# @param    
# @return   
#******************************************************
sub fcheck_flash_game {
    my $self = shift;
    my $q    = $self->query();
    my $s    = $q->param('s');
    my $a    = $q->param('a');
    my $o    = $q->param('o');
    my $p    = $q->param('p');
    my $nn   = $q->param('nn');
    my $mii  = $q->param('mii');
    my $msi  = $q->param('msi');
    my $xy   = $q->param('xy');

    my ($gree_user_id, $encrypt) = split(/:/, $s);

    my ($my_item_id, $item_id);
    if ($mii ne "") {
        ($my_item_id, $item_id) = split(/:/, $mii);
    }
    else {
        #$item_id = '1001';
        $item_id = undef;
    }

    my ($contents_id, $category_id) = split(/:/, $p);

    # error_code
    # 9 はクリア済み 99 ぱわぁ不足 89 アイテム使用済み
    my $ec = 1;

    my $dbh  = $self->getDBConnection();
    $self->setDBCharset("sjis");
    my $myUserStatus = MyClass::JKZDB::GsaUserStatus->new($dbh);

    # 所持パワー
    my $mypower = $myUserStatus->checkMyPower($gree_user_id);

    $ec = 99  if $mypower < "1.00";

    ## 所持パワー不足でない場合はその他のチェック開始
    # アイテム
    unless ($ec == 99) {
        if ("" ne $my_item_id || defined($my_item_id)) {

        #*******************************
        # アイテムチェックをして、無効アイテムの場合はec=89にする。
        # 有効なアイテムの場合はアイテムのステータスを1(使用済み)にする。
        #
        #*******************************
            my $myItemStatus = MyClass::JKZDB::MyItem->new($dbh);
            if (1 != $myItemStatus->checkMyItemIfValid({ gree_user_id => $gree_user_id, my_item_id => $my_item_id })) {
                $ec = 89;
            }
        }

        unless (89 == $ec) {
            my $UserFlashGameLog = MyClass::JKZDB::GsaUserFlashGameLog->new($dbh);
            ## pow(2)された数値が戻ってくる
            my $check_result_flag = $UserFlashGameLog->checkResultFlag({
                                        gree_user_id => $gree_user_id,
                                        contentsm_id => $contents_id,
                                        categorym_id => $category_id,
                                    });
            $ec = 9 if 2 == $check_result_flag;
        }
    }

    #my $ec_code = sprintf("ec=%s", 1); # テスト用に常に1を返す設定

    my $ec_code = sprintf("ec=%s", $ec);

    print $self->query->header('text/plain');
    print $ec_code;

    1;

}


#******************************************************
# @access   ガジェットサーバーを通さないのでクエリパラメータで値を取得する必要がある
# @desc     Flashゲーム結果の書き込み。ストップボタンを押したときの処理
# @param    処理完了後にFlashに結果を返す。ユーザー画面はまだFlash
# @param    
# @return   ec=xx 
#******************************************************
sub fstop_flash_game {
    my $self = shift;
    my $q    = $self->query;
    my $obj  = {};

    ## 会員暗号処理文字がない
    if (!$q->param('s')) {
        return;
    }

    # Modified 複数画像ゲットアイテム使用判定フラグ default=0 2011/05/13
    # アイテムのIDが5001 ｷﾞｶﾞいなずまにたいしてのフラグ
    my $SP_ITEM_FLAG = 0;

    my $s           = $q->param('s');
    my $a           = $q->param('a');
    my $o           = $q->param('o');
    my $p           = $q->param('p');
    my $nn          = $q->param('nn');
    my $mii         = $q->param('mii');
    my $msi         = $q->param('msi');
    my $xy          = $q->param('xy');
    my $record_time = $q->param('rc');
# このパラメータはここでは送信されてこない
#    my $result_flag = $q->param('rs');

#******************************
# レコードの減点分を算出 5秒以上の場合は rc-5 5秒以下の場合 5 -rc
# 結果が1より大きい場合は1のまま
#******************************
    my $base_count  = 5;
    my $minus_time;
    if ($record_time > $base_count) {
        # テスト用に5秒以上の場合は成功とするたマイナスを０に設定
        $minus_time = $record_time - $base_count;
        #$minus_time = 0;
    }
    else {
        $minus_time = 5 - $record_time;
    }
    $minus_time =  1 if $minus_time > 1;

    my $result_flag = (5 == $record_time) ? 1 : 0;

    my ($gree_user_id, $encrypt) = split(/:/, $s);

    ## キャラクタIDはcontents_id + : category_id でユニーク値を生成してある
    my ($contentsm_id, $categorym_id) = split(/:/, $p);

    my $namespace           = $self->waf_name_space();
    my $api_key             = 'gsa';
    my $namespace_userstaus = sprintf("%s_userstatus", $namespace);
    my $namespace_gree_user = sprintf("%s_%s_me_self", $namespace, $api_key);
    my $gsa_usr_obj         = $self->memcached->get("$namespace_gree_user:$gree_user_id");

# Modified 2011/05/10 コンテンツデータをキャッシュからではなくシリアライズオブジェクトから取得することに変更 BEGIN
    ## contentsの全データが格納されてるキャッシュ
    #my $namespace_contents  = $namespace . 'contents';
    #my $contents_obj      = $self->memcached->get("$namespace_contents:$contentsm_id");

    my $contents_obj= $self->getFromObjectFile({ CONFIGURATION_VALUE => 'CONTENTSLIST_OBJ', subject_id=> $contentsm_id });
    my $contents_name = MyClass::WebUtil::convertByNKF('-s', $contents_obj->{name});

# Modified 2011/05/10 コンテンツデータをキャッシュからではなくシリアライズオブジェクトから取得することに変更 END

    my $dbh  = $self->getDBConnection();
    $self->setDBCharset("sjis");

    #*****************************
    # アイテム使用の処理
    #*****************************
    if ($mii ne "") {
        my ($my_item_id, $item_id) = split(/:/, $mii);
        my $myItem = MyClass::JKZDB::MyItem->new($dbh);
        $myItem->updateMyItemStatus({ my_item_id => $my_item_id, status_flag => 1 });
        my $namespace    = sprintf("%s_gsa_user_gameitem", $self->waf_name_space);
        $self->memcached->delete("$namespace:$gree_user_id");

        ## Modified ギガいなずま使用であればフラグを立てる 2011/05/13
        $SP_ITEM_FLAG = 1 if (5001 == $item_id || "5001" eq $item_id);
    }

    # キャッシュミス発生時の対処
#    if (!$contents_name) {
#        my $myContents = MyClass::JKZDB::Contents->new($dbh);
#        $contents_name = $myContents->is_Valid_Contents($contentsm_id);
#    }

    my $UserFlashGameLog    = MyClass::JKZDB::GsaUserFlashGameLog->new($dbh);
    my $UserStatus          = MyClass::JKZDB::GsaUserStatus->new($dbh);
    my $UserPowerLog        = MyClass::JKZDB::GsaUserPowerLog->new($dbh);
    # Modified 2011/05/10 追加
    my $MyContentsStatus    = MyClass::JKZDB::MyContentsStatus->new($dbh);

    ## pow(2)された数値が戻ってくる
    my $check_result_flag = $UserFlashGameLog->checkResultFlag({
                                gree_user_id => $gree_user_id,
                                contentsm_id => $contentsm_id,
                                categorym_id => $categorym_id,
                            });

    ## autocommit設定をoffにしてトランザクション開始
    my $attr_ref = MyClass::UsrWebDB::TransactInit($dbh);

    eval {
        ## 結果フラグが１の場合はまだクリアできてないためアップデート フラグがなければ初回のためインサート 
        ( !$check_result_flag || !defined($check_result_flag) ) ? $UserFlashGameLog->executeUpdate({
                                                                    gree_user_id        => $gree_user_id,
                                                                    contentsm_id        => $contentsm_id,
                                                                    result_flag         => ( 2 ** $result_flag),
                                                                    record_time         => $record_time,
                                                                    gree_user_nickname  => $gsa_usr_obj->{gsa_nickname},
                                                                    #contents_name => $contents_obj->{name},
                                                                    contents_name       => $contents_name,
                                                                    categorym_id        => $categorym_id,
                                                                    },
                                                                  -1)
        :
        ( 1 == $check_result_flag )                             ? $UserFlashGameLog->updateUserFlashGameLog({
                                                                    result_flag  => $result_flag,
                                                                    record_time  => $record_time,
                                                                    gree_user_id => $gree_user_id,
                                                                    contentsm_id => $contentsm_id,
                                                                    categorym_id => $categorym_id
                                                                  })
                                                                : ""
                                                                  #$UserFlashGameLog->updateGameCount({
                                                                  #    gree_user_id => $gree_user_id,
                                                                  #    contentsm_id => $contentsm_id,
                                                                  #    categorym_id => $categorym_id
                                                                  #})
                                                                ;

        #******************************************
        # 画像ゲット処理開始
        #******************************************
        ## 未取得画像をゲットの場合はMyContentsStatusの更新
        ## 条件：check_result_flag != 2 (tGsaUserFlashGameLogG.result_flag !=2)
        ## 条件 result_flag == 1
        if (2 != $check_result_flag && 1 == $result_flag) {
            # 複数画像ゲットアイテム使用時の付与するキャラ画像IDの合計値
            my $EXT_GET_IMAGE_SUM_CATEGORY_ID = 0;
            # 最終的なゲットしたキャラ画像IDの合計値
            my $POW_GET_IMAGE_SUM_CATEGORY_ID;

            ## ｺﾝﾌﾟﾘｰﾄ場合はswの付与が必要
            my $sum_category_id = $MyContentsStatus->getOneValueSQL({
                                    column      => 'sum_category_id',
                                    whereSQL    => 'gree_user_id=? AND contentsm_id=?',
                                    placeholder => [$gree_user_id, $contentsm_id]
                                  });

            # Modified 2011/05/13 複数画像ゲットアイテムの使用時の処理 BEGIN
            if ($SP_ITEM_FLAG) {
                # 未取得キャラカテゴリIDの取得して2つの合計値を追加画像に設定
                my @tmp = split(/,/, $MyContentsStatus->getNotCompletedSetOfCategoryIDByContentsID({ gree_user_id => $gree_user_id, contentsm_id => $contentsm_id, categorym_id => $categorym_id }));
                # 初チャレンジの場合
                if ($#tmp < 0) {
                    @tmp = (2,4,8,16,32,64);
                    my $idx;
                    map { $idx = $_ if $categorym_id == $tmp[$_] } 0..$#tmp;
                    splice @tmp, $idx, 1;
                }

                $EXT_GET_IMAGE_SUM_CATEGORY_ID = $tmp[0] + $tmp[1];
            }

            $POW_GET_IMAGE_SUM_CATEGORY_ID = ((2 ** $categorym_id) + $EXT_GET_IMAGE_SUM_CATEGORY_ID);

            ## 既存のカテゴリIDの合計と今回のカテゴリIDの合計が126の場合はコンプリート
            if ( 126 == ($sum_category_id + $POW_GET_IMAGE_SUM_CATEGORY_ID) ) {

                my $my_item_id = MyClass::WebUtil::createHash(join('', $s, time, $$, rand(9999)), 32);
                my $myItem = MyClass::JKZDB::MyItem->new($dbh);
                $myItem->executeUpdate({
                    my_item_id          => $my_item_id,
                    gree_user_id        => $gree_user_id,
                    status_flag         => 2,
                    item_type           => 16,
                    item_categorym_id   => 11000,
                    itemm_id            => $contents_obj->{stopwatch_id},
                    item_name           => $contents_name,
                }, -1);
            }

            $MyContentsStatus->executeUpdate({
                gree_user_id    => $gree_user_id,
                contentsm_id    => $contentsm_id,
                sum_category_id => $POW_GET_IMAGE_SUM_CATEGORY_ID,
                stopwatch_id    => $contents_obj->{stopwatch_id},
                contents_name   => $contents_name,
            }, -1);
        }

        #*************************
        # ぱわぁーログ マイナスがない場合はログをのこさない。
        #*************************
        if (0 < $minus_time) {
            $UserPowerLog->executeUpdate({
                id              => -1,
                gree_user_id    => $gree_user_id,
                power           => ($minus_time * -1),
                type_of_power   => 4,
            });
        }

        #*************************
        # ユーザーのステータス
        #*************************
        $UserStatus->updatePowerAndRecordTime({ gree_user_id => $gree_user_id, my_power => ($minus_time * -1), my_lastest_flashgame_record_time => $record_time });

        $dbh->commit();
    };

    ## 失敗のロールバック
    if ($@) {
        $dbh->rollback();
        ## トランザクションエラーのメッセージ
        $obj->{IfInsertDBError} = 1;
    }
    else {
        MyClass::UsrWebDB::TransactFin($dbh, $attr_ref, $@);
    }

    undef $UserFlashGameLog;
    undef $UserStatus;
    undef $UserPowerLog;
    undef $MyContentsStatus;

    #*************************
    # ここでレベルアップ処理
    #*************************
    my $callProcedure = sprintf("CALL procMoetomeLvUp(%s);", $gree_user_id);
    $dbh->do($callProcedure);

    ## ユーザーステータスのキャッシュを削除
    $self->memcached->delete("$namespace_userstaus:$gree_user_id");

        1;
}


#******************************************************
# @access   
# @desc     
# @param    
# @param    
# @return   
#******************************************************
sub fresult_flash_game {
    my $self         = shift;
    my $q            = $self->query;
    my $obj          = {};

    my $result_flag  = $q->param('rs');
    my $character_id = $q->param('p');

    if ( 1 == $result_flag ) {
#        $obj->{contentsm_id} = $contentsm_id;
        $q->param(-name=>'p', -value=> $character_id);
        #$q->param(-name=>'contents_name', -value=> $contents_name);
        $self->action('detail_my_image');
        return $self->detail_my_image();
    }
    else {
        $self->action('view_mypage');
        return $self->view_mypage;
    }
}


#**************************************************************************************************
# 取得コンテンツ・画像関連
#**************************************************************************************************

#******************************************************
# @desc     コンテンツのリスト表示
#           引数がある場合は他のユーザーのコンテンツ表示
#
# @param    リスト内容はACTIVECONTENTSLIST_OBJから取得する
# @param    $self->cfg->param('ACTIVECONTENTSLIST_OBJ')
# @return   
#******************************************************
sub viewlist_my_contents {
    my $self = shift;
    my $q    = $self->query();
    my $a    = $q->param('a');
    my $o    = $q->param('o');

    #***********************
    # 他ユーザー・ユーザー自身の判定
    #***********************
    my $gree_user_id;
    my $url;
    # 引数があれば引数のgree_user_idのステータスを取得してなければ現在のgree_user_idのステータス
    if (0 < @_) {
        $gree_user_id   = shift;
        $url = sprintf("%sa=%s&o=%s&toid=%s", $self->OTHERPAGE_URL, $a, $o, $gree_user_id);

    } else {
        $gree_user_id   =  $self->opensocial_viewer_id;
        $url = sprintf("%sa=%s&o=%s", $self->MYPAGE_URL, $a, $o);
    }

    my $offset          = $q->param('off') || 0;
    my $record_limit    = 9;
    my $condition_limit = $record_limit+1;

    my $contentsobj     = $self->getFromObjectFile({ CONFIGURATION_VALUE => 'ACTIVECONTENTSLIST_OBJ' });

    # コンプリート済みコンテンツのIDを取得
    my $myContents          = MyClass::JKZDB::MyContentsStatus->new($self->getDBConnection);
    my @completedcontents   = $myContents->fetchCompleteContents($gree_user_id);

    my $obj;
    if ($contentsobj) {
        my $totalrec = $#{ $contentsobj } + 1;
        my @navilink;

        ## レコード数が1ページ以上場合
        if ($totalrec > $record_limit) {
            ## 2ページ目以降の場合 前へリンクの生成
            if (0 < $offset) {
                $obj->{'IfExistsPreviousPage'} = 1;
                $obj->{'PreviousPageUrl'} = sprintf("%s&off=%s", $url, ($offset - $record_limit));
            }
            ## 次へリンクの生成
            if (($offset + $record_limit) < $totalrec) {
                $obj->{'IfExistsNextPage'} = 1;
                $obj->{'NextPageUrl'} = sprintf("%s&off=%s", $url, ($offset + $record_limit));
            }

            ## ページ番号生成
            for (my $i = 0; $i < $totalrec; $i += $record_limit) {

                my $pageno = int ($i / $record_limit) + 1;

                if ($i == $offset) { ###現在表示してるﾍﾟｰｼﾞ分
                    push (@navilink, $pageno);
                } else {
                    my $pagenate_url = sprintf("%s&off=%s", $url, $i);
                    push (@navilink, $self->query->a({-href=>$pagenate_url}, $pageno));
                }
            }

            @navilink = map{ "$_\n" } @navilink;

            $obj->{'pagenavi'} = join(' ', @navilink);
        }

        $obj->{'totalrecord'} = $totalrec;

      ## コンテンツ数とオフセットの差が1ページ表示数以上であれば1ページ表示数分のループ。以下であればその差をループ
        $obj->{'LoopMyContentsList'} = ( $record_limit < ($totalrec - $offset) ) ? ( $record_limit - 1 ) : ( $totalrec - $offset - 1 );

       map {
            # objectから取得しているから毎回全レコードをループしている。
            # 取得するデータもとはループ回数目＋オフセットが必要
            my $idx = $_;
            my $cnt =  ($idx + $offset);

            foreach my $key ( qw[contents_id name] ) {
                $obj->{$key}->[$idx] = $contentsobj->[$cnt]->{$key};
                $obj->{'LMYPAGE_URL'}->[$idx] = $self->MYPAGE_URL;
                $obj->{'LMYCONTENTS_SAMPLE_IMAGE_SCRIPTDATABASE_URL'}->[$idx] = sprintf("%s%s", $self->MAIN_URL, $self->CONFIGURATION_VALUE('CONTENTS_SAMPLE_IMAGE_SCRIPTDATABASE_NAME'));
                $obj->{'LMYCONTENTS_IMAGE_SCRIPTDATABASE_URL'}->[$idx] = sprintf("%s%s", $self->MAIN_URL, $self->CONFIGURATION_VALUE('CONTENTS_IMAGE_SCRIPTDATABASE_NAME'));
                ## コンプリート済みかの判定
                ( grep($_ eq $obj->{contents_id}->[$idx], @completedcontents) ) ? $obj->{IfCompletedContents}->[$idx] = 1 : $obj->{IfNotCompletedContents}->[$idx] = 1;
            }

            if ( $obj->{'LoopMyContentsList'} == $idx ) {
                $obj->{'IfTDandTDandTREnd'}->[$idx] = 1 if ( 0 == $idx % 3 );
                $obj->{'IfTDandTREnd'}->[$idx]      = 1 if ( 1 == $idx % 3 );
            }
            $obj->{'IfTREnd'}->[$idx]   = 1 if ( 2 == $idx % 3 );
            $obj->{'IfTRBegin'}->[$idx] = 1 if ( 0 == $idx % 3 );

        } 0..$obj->{'LoopMyContentsList'};

        #( 0 < $totalrec ) ? $obj->{'ExistsMyContents'} = 1 : $obj->{'IfNotExistsMyContents'} = 1;
        $obj->{IfExistsMyContents} = 1

    } else {
        $obj->{'IfNotExistsMyContents'} = 1;
    }
    warn Dumper($obj);
    return $obj;

}


#******************************************************
# @desc     コンテンツの詳細
# @param    
# @param    
# @return   
#******************************************************
sub detail_my_contents {
    my $self    = shift;
    my $q       = $self->query();
    my $a       = $q->param('a');
    my $o       = $q->param('o');
    my $p       = $q->param('p');

    my $gree_user_id = $self->opensocial_owner_id;

    #*************************
    # コンテンツの情報取得
    #*************************
    my $obj = $self->getFromObjectFile({ CONFIGURATION_VALUE => 'CONTENTSLIST_OBJ', subject_id => $p });
    # 血液型を日本語変換
    $obj->{bloodtypeDescription}     = MyClass::WebUtil::convertByNKF('-s', $self->fetchOneValueFromConf('BLOODTYPE', ($obj->{bloodtype}-1)));
    # 星座を日本語変換
    $obj->{constellationDescription} = MyClass::WebUtil::convertByNKF('-s', $self->fetchOneValueFromConf('CONSTELLATION', $obj->{constellation}));

    #*************************
    # コンプリート状況と比較する
    # tMyContentsStatusの値が126の場合はコンプリート済み
    #
    #*************************
    my $myContents = MyClass::JKZDB::MyContentsStatus->new($self->getDBConnection);
    # クリア済みキャラクタのカテゴリ取得 クリア済みの場合は合計6つの値が入ってる
    my @tmp         = split(/,/, $myContents->makeSetOfCategoryID({ gree_user_id => $gree_user_id, contentsm_id => $p }));
    my @complete    = map { log($_) / log(2) } @tmp;

    ## コンプリート済みかの判定
    ## 本当は@tmpの合計値が126かで判定するべきだけど面倒だから配列の数で判定
    (6 == scalar @tmp) ? $obj->{IfCompletedContents} = 1 : $obj->{IfNotCompletedContents} =1;

    my $categorylist = $self->getFromObjectFile( { CONFIGURATION_VALUE => 'CATEGORYLIST_OBJ' } );
    $obj->{LoopMyCharacterList}  = $#{ $categorylist } - 1;

    map {
        my $idx = $_;
        $obj->{contentsm_id}->[$idx]     = $obj->{contents_id};
        $obj->{category_id}->[$idx]      = $categorylist->[$idx+1]->{'category_id'};
        $obj->{category_name}->[$idx]    = $categorylist->[$idx+1]->{'category_name'};

        $obj->{'LCONTENTS_SAMPLE_IMAGE_SCRIPTDATABASE_URL'}->[$idx] = sprintf("%s%s", $self->MAIN_URL, $self->CONFIGURATION_VALUE('CONTENTS_SAMPLE_IMAGE_SCRIPTDATABASE_NAME'));
        $obj->{'LMYCONTENTS_IMAGE_SCRIPTDATABASE_URL'}->[$idx]      = sprintf("%s%s", $self->MAIN_URL, $self->CONFIGURATION_VALUE('CONTENTS_IMAGE_SCRIPTDATABASE_NAME'));

        $obj->{'LMYPAGE_URL'}->[$idx]    = $self->MYPAGE_URL;


        # 未コンプリートの場合はクリア済み画像かの判定
        unless ($obj->{IfCompletedContents}) {
            ( grep(/$obj->{category_id}->[$idx]/, @complete) ) ? $obj->{IfMyGetImage}->[$idx] = 1 : $obj->{IfNotMyGetImage}->[$idx] = 1;
        }

        $obj->{IfTREnd}->[$idx]    = 1 if ( 2 == $idx % 3 );
        $obj->{IfTRBegin}->[$idx]  = 1 if ( 0 == $idx % 3 );
    } 0..$obj->{LoopMyCharacterList};

    return $obj;
}


#******************************************************
# @desc     取得画像表示
# @param    
# @param    
# @return   
#******************************************************
sub detail_my_image {
    my $self = shift;

    # パラメータpはcontents_id:category_idだから分解する
    my ($contentsm_id, $categorym_id) =  split(/:/, $self->query->param('p'));

#    my $namespace     = $self->waf_name_space() . 'contents';
#    my $contents_name = $self->memcached->get("$namespace:$contentsm_id");

    my $contentsobj = $self->getFromObjectFile({ CONFIGURATION_VALUE => 'CONTENTSLIST_OBJ', subject_id => $contentsm_id });
    my $obj;
    $obj->{contents_name} = $contentsobj->{name};
    $obj->{contentsm_id}  = sprintf("%s:%s", $contentsm_id, $categorym_id);

   return $obj;
}


#******************************************************
# グラフ用に値を変更する
#******************************************************
sub convert2graph_id {
    my $value = shift;
    my $tmpval                  = sprintf "%1.1f", $value;
    return ( 
            0 == $tmpval                    ? 73 :
            0 < $tmpval && 0.8 > $tmpval    ? 74 :
            0.7 < $tmpval && 1.4 > $tmpval  ? 75 :
            1.3 < $tmpval && 1.8 > $tmpval  ? 76 :
            1.7 < $tmpval && 2.4 > $tmpval  ? 77 :
            2.3 < $tmpval && 2.8 > $tmpval  ? 78 :
            2.7 < $tmpval && 3.4 > $tmpval  ? 79 :
            3.3 < $tmpval && 3.8 > $tmpval  ? 80 :
            3.7 < $tmpval && 4.4 > $tmpval  ? 81 :
            4.3 < $tmpval && 5.0 > $tmpval  ? 82 :
                                              83 );

}


1;
__END__