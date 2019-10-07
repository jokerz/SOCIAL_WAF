#******************************************************
# @desc       
# @package    MyClass::Gree
# @access     public
# @author     Iwahase Ryo
# @create     2011/01/28
# @create     2011/06/07  gree_defaultにACTIVITYAPI処理を追加
# @version    1.00
# ----- oauth アプリケーション　API  ← 検索ワード-----
#******************************************************
package MyClass::Gree;
use 5.008005;
our $VERSION = '1.00';
#use strict;
use warnings;
no warnings 'redefine';


#******************************************************
# @desc     サンドボックス環境の情報
#       PEOPLEAPIENDPOINTSELF  アプリユーザー本人の情報
#       PEOPLEAPIENDPOINTALL   アプリユーザーの友達情報
#
#   このエンドポイントはサンドボックス用。商用は要変更
#
# @param    
# @return    
#******************************************************
=pod
use constant {
    CONSUMERKEY           => 'c2738b54fcca',
    CONSUMERSECRET        => '2e70647b46f13a1f871a143e87d1ba58',
    PEOPLEAPIENDPOINTSELF => 'http://os-sb.gree.jp/api/rest/people/@me/@self',
    PEOPLEAPIENDPOINTALL  => 'http://os-sb.gree.jp/api/rest/people/@me/@all',
    PAYMENTAPIENDPOINT    => 'http://os-sb.gree.jp/api/rest/payment/@me/@self/@app',
};
=cut
# 本番用
#=pod
use constant {
    CONSUMERKEY           => '4ff8ae05472a',
    CONSUMERSECRET        => 'a7f01f571aec458d8341e34056259640',
    PEOPLEAPIENDPOINTSELF => 'http://os.gree.jp/api/rest/people/@me/@self',
    PEOPLEAPIENDPOINTALL  => 'http://os.gree.jp/api/rest/people/@me/@all',
    PAYMENTAPIENDPOINT    => 'https://os.gree.jp/api/rest/payment/@me/@self/@app',
};
#=cut


use base qw(MyClass);

use MyClass::UsrWebDB;
use MyClass::WebUtil;
use MyClass::JKZHtml;
use MyClass::JKZGsaLogger;
use MyClass::JKZDB::GsaMember;

use Data::Dumper;


use HTTP::Request;
use LWP::UserAgent;
use OAuth::Lite;
use OAuth::Lite::ServerUtil;
use OAuth::Lite::Util qw/parse_auth_header gen_random_key create_signature_base_string build_auth_header encode_param/;
# 下記だとﾗﾝﾀﾞﾑ文字の生成を行える gen_random_key(); 引数に長さを指定できる。デフォルトは10文字
#use OAuth::Lite::Util qw/parse_auth_header gen_random_key/;
use OAuth::Lite::Consumer; # ためしに使ってみる
use Digest::HMAC_SHA1 qw(hmac_sha1);
use MIME::Base64;

use JSON;


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
# @desc     
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

    #******************************************************
    # oauth_signatureの検証OKの場合のみ
    #******************************************************

    if(2 == $self->user_carriercode) {
        $obj = $self->printSoftBankPage("No SoftBank");
    }
    else {
    unless ($self->__verify_oauth_signature()) {
        $obj = $self->oauth_verification_failure();
    } else {
        $self->userid_ciphered();
        my $method = $self->action();
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

        $obj->{SITEIMAGE_SCRIPTDATABASE_URL}              = sprintf("%s%s", $self->MAIN_URL, $self->CONFIGURATION_VALUE('SITEIMAGE_SCRIPTDATABASE_NAME'));
        $obj->{ITEMIMAGE_SCRIPTDATABASE_URL}              = $self->ITEMIMAGE_SCRIPTDATABASE_URL;
        $obj->{CONTENTS_SAMPLE_IMAGE_SCRIPTDATABASE_URL}  = sprintf("%s%s", $self->MAIN_URL, $self->CONFIGURATION_VALUE('CONTENTS_SAMPLE_IMAGE_SCRIPTDATABASE_NAME'));
        $obj->{CONTENTS_IMAGE_SCRIPTDATABASE_URL}         = sprintf("%s%s", $self->MAIN_URL, $self->CONFIGURATION_VALUE('CONTENTS_IMAGE_SCRIPTDATABASE_NAME'));
        $obj->{CONTENTS_RESIZED_IMAGE_SCRIPTDATABASE_URL} = sprintf("%s%s", $self->MAIN_URL, $self->CONFIGURATION_VALUE('CONTENTS_RESIZED_IMAGE_SCRIPTDATABASE_NAME'));
		$obj->{FLASH_SCRIPTFILE_URL}                      = sprintf("%s%s", $self->MAIN_URL, $self->CONFIGURATION_VALUE('FLASH_SCRIPTFILE_NAME'));
        $obj->{opensocial_app_id}            = $self->opensocial_app_id;
        $obj->{opensocial_viewer_id}         = $self->opensocial_viewer_id;
        $obj->{opensocial_owner_id}          = $self->opensocial_owner_id;



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


    $self->processHtml($obj);

    $self->disconnectDB();
}


#******************************************************
# @desc     GREE認証後表示ページ
# @param    
# @return   
#******************************************************
sub gree_default {
    my $self = shift;
    my $gree_user_id = $self->opensocial_viewer_id;
    
    my $member = MyClass::JKZDB::GsaMember->new($self->getDBConnection);
    if ($member->chechGreeUserStatus($gree_user_id)) {
        $member->startGreeUserStatus($gree_user_id);

        my $consumersecret  = sprintf("%s&%s", $self->cfg->param('CONSUMERSECRET'), $self->oauth_token_secret);
        my $api_endpoint    = sprintf("%s/\@me/\@self/\@app", $self->cfg->param('GREE_ACTIVITY_API_ENDPOINT'));
        my $method          = "POST";

        ### リクエストパラメータの準備
        my %oauth = (
            oauth_version           => '1.0',
            oauth_nonce             => generate_nonce(),
            oauth_timestamp         => time,
            oauth_consumer_key      => $self->cfg->param('CONSUMERKEY'),
            oauth_token             => $self->oauth_token,
            oauth_signature         => undef,
            oauth_signature_method  => 'HMAC-SHA1',
            xoauth_requestor_id     => $self->opensocial_viewer_id,
        );

        my $params;
        $params->{oauth_consumer_key}      = $oauth{oauth_consumer_key};
        $params->{oauth_token}             = $oauth{oauth_token};
        $params->{oauth_signature_method}  = $oauth{oauth_signature_method};
        $params->{oauth_timestamp}         = $oauth{oauth_timestamp};
        $params->{oauth_nonce}             = $oauth{oauth_nonce};
        $params->{oauth_version}           = '1.0';
        $params->{xoauth_requestor_id}     = $oauth{xoauth_requestor_id};

        my $param = join '&', map {
            join '=', $_, $params->{$_};
        } sort keys %{ $params };

        &uri_encode($method, $api_endpoint, $param);
        my $msg                 = "$method&$api_endpoint&$param";
        $oauth{oauth_signature} = _encode_base64(Digest::HMAC_SHA1::hmac_sha1($msg,$consumersecret));
        &uri_encode($oauth{oauth_signature});

        my $data            = {
            title   => $self->cfg->param('ACTIVITYE_API_PHRASE1'),
            url     => 'http://mpf.gree.jp/1370',
        };
        my $req = HTTP::Request->new(POST => 'http://os.gree.jp/api/rest/activities/@me/@self/@app') or die 'Failed to initialize HTTP::Request';

        $req->header( 'Authorization' => get_oauth_header(%oauth) );
        $req->content_type('application/json');
        $req->content(JSON->new->latin1->encode($data));

        my $ua  = LWP::UserAgent->new or die 'Failed to initialize LWP::UserAgent';
        my $res = $ua->request($req) or die 'Failed to request';

        if ($res->is_success) {
            warn "-"x20, "ACTIVITY API RESPONSE", "-"x20,"\n", Dumper($res);
        } else {
            warn $res->status_line;
        }

    }

    return;
}


#******************************************************
# @desc     萌えぷちエンター後のページ(サイトトップ)
# API接続とデータ取得
# バッチとリクエストではパラメータが違う
# API接続に必用なOAUTHパラメータ
#
# <<リクエスト>>
# oauth_consumer_key
# oauth_nonce
# oauth_timestamp
# oauth_token
# oauth_signature_method
# oauth_version
# xoauth_requestor_id
#
# <<バッチ>>
# oauth_consumer_key
# oauth_nonce
# oauth_timestamp
# oauth_signature_method
# oauth_version
#
# << 手順 >>
# step1) 
# step2) signatureのベースstringを生成
#        httpメソッド・API接続URL・パラメータをURLエンコードして、"＆"でつなげる
# step3) OAuth Signatureの生成
#        Consumer Secretとoauth_token_secretを"&"で連結してOAuth Signature用のキーを生成
#
#******************************************************
sub enter_top {
    my $self = shift;
    my $q    = $self->query();
    #my $obj  = $self->__requestToPoepleAPI;
    my $obj  = $self->makeRequest2PeopleAPI;
    return $obj;
}


#******************************************************
# @desc     oauth
# @param    
# <<Authパラメーター>
#  パラメータ名               内容                                                 取得方法
#  auth_consumer_key          アプリ毎固有のConsumer Key                           アプリケーション登録時にGREEが発行する。 サンドボックス環境と本番環境では値が違うので要注意
#  ConsumerSecret             アプリ毎固有のConsumer Secret                        アプリケーション登録時にGREEが発行する。 サンドボックス環境と本番環境では値が違うので要注意
#  oauth_nonce                リクエスト毎にユニークな値                           generate_nonce メソッドで生成 こっちのサーバーで生成 
#  oauth_timestamp            UNIXタイムスタンプ                                   time 関数で                   こっちのサーバーで生成
#  oauth_token                アクセストークン                                     $params->{oauth_token}        ガジェットサーバーからのリクエストに含まれるAuthorizationヘッダのoauth_tokenの値
#  oauth_token_secret         OAuth Token Secret                                   $params->{oauth_token_secret} ガジェットサーバーからのリクエストに含まれるAuthorizationヘッダのoauth_token_secretの値
#  oauth_signature_method     署名方式                                             HMAC-SHA1固定
#  oauth_version              OAuthのバージョン                                    1.0固定
#  xoauth_requestor_id        アプリケーションを実行しているGREEユーザーID         ガジェットサーバーからのリクエストに含まれるクエリパラメータ opensocial_viwer_idの値
# $paramsのdumpデータ
# $VAR1 = {
#           'oauth_timestamp' => '1296457750',
#           'oauth_consumer_key' => '64bcce7250bb',
#           'opensocial_owner_id' => [
#                                      '13748'
#                                    ],
#           'opensocial_app_id' => [
#                                    '3408'
#                                  ],
#           'opensocial_viewer_id' => [
#                                       '13748'
#                                     ],
#           'oauth_signature' => 'yBlVdApw0GdH9O0WYxJaELF5NJg=',
#           'oauth_nonce' => 'e706b03753d04901293ebe308801688f',
#           'oauth_token' => '7062bb151be18f08d4c433cec46fff41',
#           'oauth_token_secret' => 'bc8d3588e1a19df4069a8b97dff544d9',
#           'oauth_version' => '1.0',
#           'oauth_signature_method' => 'HMAC-SHA1'
#         };
#******************************************************
sub __verify_oauth_signature {
    my $self = shift;
    my $q    = $self->query();


#warn '-'x100, "\n", "GadgetServerHeader \n", '-'x100, "\n",Dumper($ENV{HTTP_AUTHORIZATION});


    my ($realm, $params) = parse_auth_header($ENV{HTTP_AUTHORIZATION});

    for my $key ($q->url_param) {
        $params->{$key} = [$q->url_param($key)];
    }

    if (uc $q->request_method eq 'POST'
        && $q->content_type =~ m{^\Qapplication/x-www-form-urlencoded})
    {
        for my $key ($q->param) {
            $params->{$key} = [$q->param($key)];
        }
    }


    my $util = OAuth::Lite::ServerUtil->new(strict => 0);

#    $util->allow_extra_param('oauth_token_secret');
#    $util->allow_extra_param('xoauth_requestor_id');




    $util->support_signature_method('HMAC-SHA1');



#warn "\n\n\n\n\n", "="x100,"\n METHOD ",$q->request_method, "\n URL ", $q->url, "\n PARAMS : \n", Dumper($params), "<"x100;


#=pod
    ## signature検証
    if ($util->verify_signature(
        method          => $q->request_method,
        url             => $q->url,
        params          => $params,
        consumer_secret => CONSUMERSECRET,
        token_secret    => $params->{oauth_token_secret},
    )) {

#    warn "="x20, "\n", create_signature_base_string($q->request_method, $q->url, $params); 
# my $param_without_oauth_token_secret = $params;
# delete $param_without_oauth_token_secret->{oauth_token_secret};
#    warn "="x20, "\n", create_signature_base_string($q->request_method, $q->url, $param_without_oauth_token_secret); 

        $self->{opensocial_app_id}    = $params->{opensocial_app_id}->[0];
        $self->{opensocial_viewer_id} = $params->{opensocial_viewer_id}->[0];
        $self->{opensocial_owner_id}  = $params->{opensocial_owner_id}->[0];

        $self->{oauth_signature}    = $params->{oauth_signature};
        $self->{oauth_token_secret} = $params->{oauth_token_secret};
        $self->{oauth_token}        = $params->{oauth_token};

#warn "\n METHOD GET : ","<"x130,Dumper($util), "\n",">"x130;

        return 1;
    }

#    warn "\n","<"x130,Dumper($util), "\n",">"x130;
    return undef;
}


#******************************************************
# @desc     request to People API
# @param    
#******************************************************
sub makeRequest2PeopleAPI {
    my $self         = shift;
    my $obj          = {};
    my $api_key      = 'gsa';
    my $namespace    = sprintf("%s_%s_me_self", $self->waf_name_space(), $api_key);
    my $gree_user_id = $self->opensocial_viewer_id;
    #my $memcached    = $self->memcached();
    $obj             = $self->memcached->get("$namespace:$gree_user_id");

    #************************
    # cacheにユーザー本人情報がない場合はAPIにリクエスト
    #************************
    if (!$obj) {
        my $api_endpoint = PEOPLEAPIENDPOINTSELF;
        my $ua           = LWP::UserAgent->new();

        $ua->agent($ENV{'HTTP_USER_AGENT'});

        my $request_url = $api_endpoint;
        my $consumer    = OAuth::Lite::Consumer->new(
            consumer_key         => CONSUMERKEY,
            consumer_secret      => CONSUMERSECRET,
            realm                => '',
        #   xoauth_requestor_id  => $self->opensocial_viewer_id,
        #   oauth_token          => $self->oauth_token,
        );

        my $res         = $consumer->request(
            method => 'GET',
            url    => $request_url,
            params => {
                        xoauth_requestor_id  => $self->opensocial_viewer_id,
#                        opensocial_owner_id  => $self->opensocial_owner_id,
#                        opensocial_app_id    => $self->opensocial_app_id,
#                        opensocial_viewer_id => $self->opensocial_viewer_id,
                      },
        );
warn "="x25, __LINE__, "PEOPLE API res = request(req)", "="x25, "\n", Dumper($res), "\n", "="x25;
        use Encode;
        my $result = JSON->new->utf8(0)->decode(decode_utf8($res->decoded_content));

        if ($result->{Error}) {
            warn encode('utf-8', $result->{Error}{Message}), "\n";
        }
        else {
warn __LINE__, "First CHECH THE CACHE \n";
warn Dumper($obj);
            #*********************************
            # グリーのAPIデータと置換文字の設定
            # 置き換え文字はgsa_xxxyy
            #*********************************
            $api_key .= '_';
            map { $obj->{$api_key . $_} = MyClass::WebUtil::convertByNKF('-s', $result->{entry}{$_}) } keys %{ $result->{entry} };

            #*********************************
            # cacheの名前空間 gsa_me_self:{id}
            #*********************************
            #my $namespace = $self->waf_name_space() . '_me_self';
            $self->memcached->add("$namespace:$gree_user_id", $obj, 1800);
warn __LINE__, "Second CHECH THE CACHE \n";
warn Dumper($obj);
        }
    }

    return $obj;
}


#******************************************************
# @desc     会員設定パラメータ
# @param    
#******************************************************
sub userid_ciphered {
    my $self = shift;
    my $userid_ciphered;
    if(!$self->query->param('s')) {
        $self->{userid_ciphered}  = join('::', $self->opensocial_owner_id(), MyClass::WebUtil::cipher($self->opensocial_owner_id()));
    }
    else {
        my ($userid, $ciphered) = split(/::/, $self->query->param('s'));
        $self->{userid_ciphered} =
            ( $self->opensocial_owner_id() == $userid && MyClass::WebUtil::decipher( $self->opensocial_owner_id(), $ciphered ) ) ? $self->query->param('s') : undef ;
    }

    return $self->{userid_ciphered};
}


sub __member_param {
    my $self = shift;
=pod
    my $userid_ciphered;
    if(!$self->query->param('s')) {
        $userid_ciphered  = join('::', $self->opensocial_owner_id(), MyClass::WebUtil::cipher($self->opensocial_owner_id()));
    }
    else {
        my ($userid, $ciphered) = split(/::/, $self->query->param('s'));
        $userid_ciphered =
            ( $self->opensocial_owner_id() == $userid && MyClass::WebUtil::decipher( $self->opensocial_owner_id(), $ciphered ) ) ? $self->query->param('s') : undef ;
    }
    $self->{__member_param} = sprintf("s=%s&", $userid_ciphered);
    return $self->{__member_param};
=cut
    $self->{__member_param} = sprintf("s=%s&", $self->userid_ciphered);
    return $self->{__member_param};
}


=pod
sub __session_obj {
    my $self = shift;

    my $gree_user_id            = $self->opensocial_owner_id();
    my $gree_user_id_ciphered   = $self->userid_ciphered();

    my $namespace = sprintf("%s_gsa_user_status", $self->waf_name_space());
    my $obj       =  $self->memcached->get("$namespace:$gree_user_id_ciphered");


## 本日のガチャ確認 (ガチャ済みは戻りが1)
my $myGacha = MyClass::JKZDB::GsaUserGachaLog->new($dbh);
$myGacha->checkGachaToday($gree_user_id);


   if (!$obj) {
   my $sess_ref;
   if (defined ($sess_ref = MyClass::JKZSession->open($gree_user_id_ciphered, {expire => 3600}))) {
        if (1 == $sess_ref->session_is_valid()) {
            #my $session_obj = $sess_ref->attrData("user_moepetit_status");
            my $user_status_obj;
        }
   }
    else {
        $sess_ref = MyClass::JKZSession->open( $userid, {flag => 1} );

#****************************
オブジェクトの識別子はグリーのID
名前空間はuser_moepetit_status
コンテンツid: 1 と 2を例にとる
game_statusはコンテンツ数分存在する

    {
        power           => int,
        stopwatch_id    => int, # ストップウォッチのid カスタマイズストップはそのid
        stopwatch_name  => char,# ストップウォッチの名前
        game_status     => {
                                contents_id:1 => {
                                    contents_character_id       => [ 1001, 1002, 1003, 1004, 1005, 1006 ],  # contents_character_id[x] x番目のstatusはcontents_character_status[x] xはカテゴリid-1の値
                                    contents_character_status   => [    1,    0,    0,    1,    1,    0 ],  # 縦に連動 
                                    getimage                    => 3,                                       # 上のcontents_character_statusの値が1の総数
                                    status                      => 0,
                                },
                                contents_id:2 => {
                                    contents_character_id       => [ 2001, 2002, 2003, 2004, 2005, 2006 ],  # contents_character_id[x] x番目のstatusはcontents_character_status[x]
                                    contents_character_status   => [    1,    1,    1,    1,    1,    1 ],  # 縦に連動 このステータスが1のゲームはクリア済みとなる
                                    getimage                    => 6,                                       # 上のcontents_character_statusの値が1の総数
                                    status                      => 1,                                       # このコンテンツはコンプリート済み
                                },
        },
        total_game_getimage  => 9,
        total_game_completed => 1,
    }




            @{ $user_status_obj->{game_status} } = (
                contents_id
            );
    }

}
=cut


#******************************************************
# @desc     
#******************************************************
sub MAINURL {
    my $self =shift;

    $self->{MAINURL} = sprintf("%s/%s?%s", $self->MAIN_URL(), $self->CONFIGURATION_VALUE('BASE_CONTROLER_NAME'), $self->__member_param());

    return $self->{MAINURL};
}


#******************************************************
# @desc     
#******************************************************
sub MYPAGE_URL {
    my $self =shift;
    $self->{MYPAGE_URL} = sprintf("%s/%s?%s", $self->MAIN_URL(), $self->CONFIGURATION_VALUE('MYPAGE_APP_NAME'), $self->__member_param());

    return $self->{MYPAGE_URL};
}


#******************************************************
# @desc     
#******************************************************
sub OTHERPAGE_URL {
    my $self =shift;
    $self->{OTHERPAGE_URL} = sprintf("%s/%s?%s", $self->MAIN_URL(), $self->CONFIGURATION_VALUE('OTHERPAGE_APP_NAME'), $self->__member_param());

    return $self->{OTHERPAGE_URL};
}


#******************************************************
# @desc     ユーザーの所持しているアイテムぼっくす
#******************************************************
sub MY_ITEMBOX_URL {
    my $self =shift;

    #$self->{MY_ITEMBOX_URL} = sprintf("%s/%s?%s", $self->MAIN_URL(), $self->CONFIGURATION_VALUE('MY_ITEMBOX_APP_NAME'), $self->__member_param());
    $self->{MY_ITEMBOX_URL} = $self->MYPAGE_URL(); #暫定的にMyPageクラスで処理をする

    return $self->{MY_ITEMBOX_URL};
}


#******************************************************
# @desc     
#******************************************************
sub MY_STOPWATCH_URL {
    my $self =shift;
    $self->{MY_STOPWATCH_URL} = sprintf("%s/%s?%s", $self->MAIN_URL(), $self->CONFIGURATION_VALUE('MY_STOPWATCH_APP_NAME'), $self->__member_param());

    return $self->{MY_STOPWATCH_URL};
}


#******************************************************
# @desc     
#******************************************************
sub MY_LIBRARY_URL {
    my $self =shift;
    $self->{MY_LIBRARY_URL} = sprintf("%s/%s?%s", $self->MAIN_URL(), $self->CONFIGURATION_VALUE('MY_LIBRARY_APP_NAME'), $self->__member_param());

    return $self->{MY_LIBRARY_URL};
}


#******************************************************
# @desc     
#******************************************************
sub MY_GETIMAGE_URL {
    my $self =shift;
    $self->{MY_GETIMAGE_URL} = sprintf("%s/%s?%s", $self->MAIN_URL(), $self->CONFIGURATION_VALUE('MY_GETIMAGE_APP_NAME'), $self->__member_param());

    return $self->{MY_GETIMAGE_URL};
}


#******************************************************
# @desc     
#******************************************************
sub ITEMSHOP_URL {
    my $self =shift;
    $self->{ITEMSHOP_URL} = sprintf("%s/%s?%s", $self->MAIN_URL(), $self->CONFIGURATION_VALUE('ITEMSHOP_APP_NAME'), $self->__member_param());

    return $self->{ITEMSHOP_URL};
}


#******************************************************
# @desc     
#******************************************************
sub ITEMEXCHANGE_URL {
    my $self =shift;
    $self->{ITEMEXCHANGE_URL} = sprintf("%s/%s?%s", $self->MAIN_URL(), $self->CONFIGURATION_VALUE('ITEMEXCHANGE_APP_NAME'), $self->__member_param());

    return $self->{ITEMEXCHANGE_URL};
}


#******************************************************
# @desc     サイト内画像表示
#******************************************************
sub SITEIMAGE_SCRIPTDATABASE_URL {
    my $self = shift;
    $self->{SITEIMAGE_SCRIPTDATABASE_URL} = sprintf("%s%s", $self->MAIN_URL, $self->CONFIGURATION_VALUE('SITEIMAGE_SCRIPTDATABASE_NAME'));

    return $self->{SITEIMAGE_SCRIPTDATABASE_URL};
}


#******************************************************
# @desc     コンテンツサンプル画像表示
#******************************************************
sub CONTENTS_SAMPLE_IMAGE_SCRIPTDATABASE_URL {
    my $self = shift;
    $obj->{CONTENTS_SAMPLE_IMAGE_SCRIPTDATABASE_URL} = sprintf("%s%s", $self->MAIN_URL, $self->CONFIGURATION_VALUE('CONTENTS_SAMPLE_IMAGE_SCRIPTDATABASE_NAME'));

    return $self->{CONTENTS_SAMPLE_IMAGE_SCRIPTDATABASE_URL};
}


#******************************************************
# @desc     コンテンツ画像表示
#******************************************************
sub CONTENTS_IMAGE_SCRIPTDATABASE_URL {
    my $self = shift;
    $obj->{CONTENTS_IMAGE_SCRIPTDATABASE_URL} = sprintf("%s%s", $self->MAIN_URL, $self->CONFIGURATION_VALUE('CONTENTS_IMAGE_SCRIPTDATABASE_NAME'));

    return $self->{CONTENTS_IMAGE_SCRIPTDATABASE_URL};
}


#******************************************************
# @desc     図鑑画像表示
#******************************************************
sub LIBRARY_IMAGE_SCRIPTDATABASE_URL {
    my $self = shift;
    $obj->{LIBRARY_IMAGE_SCRIPTDATABASE_URL} = sprintf("%s%s", $self->MAIN_URL, $self->CONFIGURATION_VALUE('LIBRARY_IMAGE_SCRIPTDATABASE_NAME'));

    return $self->{LIBRARY_IMAGE_SCRIPTDATABASE_URL};
}


#******************************************************
# @desc     称号画像表示
#******************************************************
sub DEGREE_IMAGE_SCRIPTDATABASE_URL {
    my $self = shift;
    $obj->{DEGREE_IMAGE_SCRIPTDATABASE_URL} = sprintf("%s%s", $self->MAIN_URL, $self->CONFIGURATION_VALUE('DEGREE_IMAGE_SCRIPTDATABASE_NAME'));

    return $self->{DEGREE_IMAGE_SCRIPTDATABASE_URL};
}


#******************************************************
# @desc     コンテンツ縮小画像表示
#******************************************************
sub CONTENTS_RESIZED_IMAGE_SCRIPTDATABASE_URL {
    my $self = shift;
    $obj->{CONTENTS_RESIZED_IMAGE_SCRIPTDATABASE_URL} = sprintf("%s%s", $self->MAIN_URL, $self->cfg->param('CONTENTS_RESIZED_IMAGE_SCRIPTDATABASE_NAME'));

    return $self->{CONTENTS_RESIZED_IMAGE_SCRIPTDATABASE_URL};
}


#******************************************************
# @desc     フラッシュ呼び出し
#******************************************************
sub FLASH_SCRIPTFILE_URL {
    my $self = shift;
    $obj->{FLASH_SCRIPTFILE_URL} = sprintf("%s%s", $self->MAIN_URL, $self->CONFIGURATION_VALUE('FLASH_SCRIPTFILE_NAME'));

    return $self->{FLASH_SCRIPTFILE_URL};
}


#******************************************************
# @desc     
#******************************************************
sub ITEMIMAGE_SCRIPTDATABASE_URL {
    my $self = shift;
    $self->{ITEMIMAGE_SCRIPTDATABASE_URL} = sprintf("%s%s", $self->MAIN_URL, $self->CONFIGURATION_VALUE('ITEM_IMAGE_SCRIPTDATABASE_NAME'));

    return $self->{ITEMIMAGE_SCRIPTDATABASE_URL};
}


sub opensocial_param {
    my $self = shift;

    $self->{opensocial_param} = sprintf("opensocial_app_id=%s&opensocial_owner_id=%s&opensocial_viewer_id=%s", $self->opensocial_app_id, $self->opensocial_owner_id, $self->opensocial_viewer_id);
    return $self->{opensocial_param};
}

#******************************************************
# @desc     アクセスされているGREEアプリのID
# @param    
# @return   
#******************************************************
sub opensocial_app_id {
    return shift->{opensocial_app_id};
}


#******************************************************
# @desc     アプリケーションを実行しているGREEユーザーID
# @param    
# @return   
#******************************************************
sub opensocial_viewer_id {
    return shift->{opensocial_viewer_id};
}


#******************************************************
# @desc     アクセスされているGREEアプリをインストールしているユーザーのID
# @param    
# @return   
#******************************************************
sub opensocial_owner_id {
    return shift->{opensocial_owner_id};
}

sub oauth_signature {
    return shift->{oauth_signature};
}

sub oauth_token {
    return shift->{oauth_token};
}


sub oauth_token_secret {
    return shift->{oauth_token_secret};
}


#******************************************************
# @desc     oauth 失敗
#******************************************************
sub oauth_verification_failure {
    my $self = shift;
    my $obj  = {};
    $obj->{ERRMSG} = MyClass::WebUtil::convertByNKF('-s', "OAUTH Error");
    $self->action('oauth_error');
    
    return $obj;
}


#******************************************************
# memcachedのイニシャライズ
#******************************************************
sub memcached {
    my $self = shift;

    $self->{memcached} = MyClass::UsrWebDB::MemcacheInit(
                {
                    servers            => ["192.168.1.201:11211"],
                    namespace          => 'gsa:',
                    compress_threshold => 10_000,
                    compress_ratio     => 0.9,
                }
    );

    return $self->{memcached};
}



#******************************************************
# @desc     oauth_nonce を生成する
# @param    
# @return   
#******************************************************
=pod
sub generate_nonce {
    my $str = _encode_base64 (pack 'C*', map { int rand 256 } 1..12 );
    # 記号は除く
    $str =>  tr!+=/!012!;
    $str;
}
=cut




#******************************************************
# @access    public
# @desc        サイト内説明・そのた事務的なページ用
# @param    str queryのpgの値をテンプレートに設定
#           パラメータ値が無い場合はエラーページ処理
#******************************************************
sub view_help {
    my $self       = shift;
    my $obj        = {};
    my $tmplt_name = $self->query->param('pg') || 'error';

    $self->action($tmplt_name);

    return $obj;
}


#******************************************************
# @desc    必須パラメータが付与されている会員専用のURL
#******************************************************
sub MEMBERMAINURL {
    my $self = shift;

    #$self->{MEMBERMAINURL} = sprintf("%s?%s", $self->MEMBER_MAIN_URL(), $self->__member_param());
    $self->{MEMBERMAINURL} = $self->MEMBER_MAIN_URL();

    $self->{MEMBERMAINURL};
}


#******************************************************
# @access  
# @desc    Softbank エラーページの表示
# @param   
# @return  
#******************************************************
sub printSoftBankPage {
    my ($self, $msg) = @_;
    my $obj;
    $obj->{ERROR_MSG} = $msg;

    $self->action('softbankerror');

    return $obj;
}


### oauth_nonce を生成する
sub generate_nonce {
    my $str = _encode_base64 (pack 'C*', map { int rand 256 } 1..12 );
    # 記号は除く
    $str =~  tr!+=/!012!;
    chomp $str;
    $str;
}


### OAuth HTTP ヘッダ文字列の生成する
sub get_oauth_header {
    my (%param) = @_;
    'OAuth '. join ',', map {
        sprintf '%s="%s"', $_, $param{$_};
    } keys %param;
}


### POST するデータ文字列を生成する
sub get_content {
    my (%param) = @_;
    join '&', map {
        sprintf '%s=%s', $_, $param{$_};
    } keys %param;
}


### データを MIME::Base64 エンコードする
sub _encode_base64 {
    my ($str) = @_;
    $str = MIME::Base64::encode ($str);
    # エンコードされた文字列の末尾に改行コードがくっついてくるっぽい
    $str =~  s/^\s+|\s+$//g;
    $str;
}

### 文字列を URL エンコードする
sub _encode_url {
    my ($str) = @_;
    $str =~  s!([^a-zA-Z0-9_.> -])!sprintf '%%%02X',ord($1)!ge;
    $str;
}


sub uri_encode() {
    foreach(@_) {
        $_ =~ s|([^a-zA-Z0-9\-\._\~])|
            my $x = '%' . unpack('H2', $1);
            $x =~ tr/a-f/A-F/;    #重要!!
            $x;
        |eg;
    }
}


1;

__END__