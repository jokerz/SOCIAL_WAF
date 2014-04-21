#******************************************************
# @desc       オープンソーシャルサイト用
# @package    MyClass::MyOpenSocialApp
# @access     public
# @author     Iwahase Ryo
# @create     2011/11/17
# @update     
# @version    1.00
# ----- oauth アプリケーション　API  ← 検索ワード-----
#******************************************************
package MyClass::MyOpenSocialApp;
use 5.008005;
our $VERSION = '1.00';
use strict;
use warnings;
no warnings 'redefine';

=pod
use constant {
    CONSUMERKEY           => '5jaoKv2wOxMOW8Z5',
    CONSUMERSECRET        => '_qs[Dz31a?AEid2en2u3ilk3M1EwZtrY',
    PEOPLEAPIENDPOINTSELF => 'http://sb.app.appli-hills.com/api.php/social/rest/people/@me/@self',
    PEOPLEAPIENDPOINTALL  => 'http://sb.app.appli-hills.com/api.php/social/rest/people/@me/@all',
    PAYMENTAPIENDPOINT    => 'http://sb.app.appli-hills.com/api.php/social/rest/payment/@me/@self/@app',
};
=cut



use base qw(MyClass);

use MyClass::UsrWebDB;
use MyClass::WebUtil;
use MyClass::JKZHtml;
#use MyClass::JKZLogger;
#use MyClass::JKZDB::Member;

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


#**************************
# テスト時に__verify_oauth_signature処理をパスするようにフラグを設定
# @value 1     == test
#        undef == 商用環境 
##**************************
my $TEST_FLAG = undef;

my $DBH;

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
    $self->memcached();
    $self->setMicrotime("t0");

    $DBH = $self->dbh();
    #******************************************************
    # oauth_signatureの検証OKの場合のみ
    #******************************************************
    if(2 == $self->user_carriercode) {
        $obj = $self->printSoftBankPage("No SoftBank");
    }
    else {
        unless ($self->__verify_oauth_signature()) {
            $obj = $self->oauth_verification_failure();
        }
        else {
            $self->userid_ciphered();
            my $method = $self->action();
            $method  ||= $self->action('default_page');
            $obj       =
                exists ($self->class_component_methods->{$method}) ? $self->call($method) :
                $self->can($method)                                ? $self->$method()     :
                                                                     $self->printErrorPage("invalid method call");

            #*****************************
            # 定数として
            #*****************************
#            $obj->{MAINURL}             = $self->MAINURL;
            $obj->{MYPAGE_URL}          = $self->query->escape($self->MYPAGE_URL);
            $obj->{OTHERPAGE_URL}       = $self->query->escape($self->OTHERPAGE_URL);
            $obj->{MY_ITEMBOX_URL}      = $self->query->escape($self->MY_ITEMBOX_URL);
            $obj->{MY_STOPWATCH_URL}    = $self->query->escape($self->MY_STOPWATCH_URL);
            $obj->{MY_LIBRARY_URL}      = $self->query->escape($self->MY_LIBRARY_URL);
            $obj->{MY_GETIMAGE_URL}     = $self->query->escape($self->MY_GETIMAGE_URL);
            $obj->{DEGREE_EVENT_URL}    = $self->query->escape($self->DEGREE_EVENT_URL);  # 2011/07/12 称号/イベント用
            $obj->{ITEMSHOP_URL}        = $self->query->escape($self->ITEMSHOP_URL);
            $obj->{ITEMEXCHANGE_URL}    = $self->query->escape($self->ITEMEXCHANGE_URL);

            $obj->{SITEIMAGE_SCRIPTDATABASE_URL}              = sprintf("%s%s", $self->MAIN_URL, $self->CONFIGURATION_VALUE('SITEIMAGE_SCRIPTDATABASE_NAME'));
            $obj->{ITEMIMAGE_SCRIPTDATABASE_URL}              = $self->ITEMIMAGE_SCRIPTDATABASE_URL;
            $obj->{CONTENTS_SAMPLE_IMAGE_SCRIPTDATABASE_URL}  = sprintf("%s%s", $self->MAIN_URL, $self->CONFIGURATION_VALUE('CONTENTS_SAMPLE_IMAGE_SCRIPTDATABASE_NAME'));
            $obj->{CONTENTS_IMAGE_SCRIPTDATABASE_URL}         = sprintf("%s%s", $self->MAIN_URL, $self->CONFIGURATION_VALUE('CONTENTS_IMAGE_SCRIPTDATABASE_NAME'));
            $obj->{CONTENTS_RESIZED_IMAGE_SCRIPTDATABASE_URL} = sprintf("%s%s", $self->MAIN_URL, $self->CONFIGURATION_VALUE('CONTENTS_RESIZED_IMAGE_SCRIPTDATABASE_NAME'));
            $obj->{FLASH_SCRIPTFILE_URL}                      = sprintf("%s%s", $self->MAIN_URL, $self->CONFIGURATION_VALUE('FLASH_SCRIPTFILE_NAME'));
            $obj->{TUTORIAL_URL}                              = sprintf("%s/mod-perl/serveFlashTutorial.mpl?signed=1", $self->MAIN_URL); # Modified 2011/10/19
            $obj->{opensocial_app_id}       = $self->opensocial_app_id;
            $obj->{opensocial_viewer_id}    = $self->opensocial_viewer_id;
            $obj->{opensocial_owner_id}     = $self->opensocial_owner_id;

            #************************
            # 各ログ収集
            #************************
            my $logger     = MyClass::JKZLogger->new({ user_id => $self->opensocial_viewer_id });
            $logger->saveLoginLog      if 'enter_top' eq $self->action(); ## 会員はmethod がmember_defaultの場合にログインログを取得
            $logger->closeLogger();
        }
    }

  #************************
  # サイト名
  #************************
    $obj->{MAINURL}     = $self->MAINURL();
    $obj->{SITE_NAME}   = $self->cfg->param('SITE_NAME');

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
        MAINURL                         => undef,
        SITE_NAME                       => undef,
        IfDoCoMo                        => undef,
        IfSoftBank                      => undef,
        IfAu                            => undef,
        IfIsNonMobile                   => undef,
    };

    map { exists($obj->{$_}) ? $footer_tags->{$_} = $obj->{$_} : delete $footer_tags->{$_} } keys %{ $footer_tags };

    my $tmpobj          = $self->_getTmpltFile('FOOTER_HTML');
    my $footer_obj      = MyClass::JKZHtml->new({}, $tmpobj, 1, 0);
    $obj->{FOOTER_HTML} = $footer_obj->convertHtmlTags( $footer_tags );

    $self->processHtml($obj);

    $self->disconnectDB();
}


#******************************************************
# @desc     認証後表示ページ
# @param    
# @return   
#******************************************************
sub default_page {
    my $self = shift;
    $self->action('enter_top');
    $self->enter_top();
}


#******************************************************
# @desc     エンター後のページ(サイトトップ)
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
    my $self    = shift;
    my $user_id = $self->opensocial_viewer_id;
    my $obj     = {};

    my $member = MyClass::JKZDB::Member->new($DBH);
    if ($member->checkUserStatus($user_id)) {
        $member->startUserStatus($user_id);
        $obj->{IfTutorial} = 1;
    }
    else {
        $obj                    = $self->makeRequest2PeopleAPI;
        $obj->{IfNotTutorial}   = 1;
    }

    return $obj;
}


#************************************************************************************************************
# @desc     SOCIAL APPLICATION METHODS BEGINS
#************************************************************************************************************

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
    $util->support_signature_method('HMAC-SHA1');

    ## signature検証
    if ($util->verify_signature(
        method          => $q->request_method,
        url             => $q->url,
        params          => $params,
        consumer_secret => CONSUMERSECRET,
        token_secret    => $params->{oauth_token_secret},
    )) {
        $self->{opensocial_app_id}      = $params->{opensocial_app_id}->[0];
        $self->{opensocial_viewer_id}   = $params->{opensocial_viewer_id}->[0];
        $self->{opensocial_owner_id}    = $params->{opensocial_owner_id}->[0];
        $self->{oauth_signature}        = $params->{oauth_signature};
        $self->{oauth_token_secret}     = $params->{oauth_token_secret};
        $self->{oauth_token}            = $params->{oauth_token};
        $self->{wakuwaku_access_token}  = $params->{wakuwaku_access_token}->[0] if exists($params->{wakuwaku_access_token});

        return 1;
    }

    # テスト
    #return undef;
    return ( $TEST_FLAG ? 1 : undef);
}


#******************************************************
# @desc     request to People API
# @param    
#******************************************************
sub makeRequest2PeopleAPI {
    my $self        = shift;
    my $obj         = {};
    my $namespace   = sprintf("%s_me_self", $self->waf_name_space());
    my $user_id     = $self->opensocial_viewer_id;
    $obj            = $self->memcached->get("$namespace:$user_id");

    #************************
    # cacheにユーザー本人情報がない場合はAPIにリクエスト
    #************************
    if (!$obj) {
            my $nonce           = generate_nonce();
            my $consumersecret  = sprintf("%s&%s", $self->cfg->param('CONSUMERSECRET'), $self->oauth_token_secret);
            my $api_endpoint      = PEOPLEAPIENDPOINTSELF;
            my $method          = "GET";

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

            my $req = HTTP::Request->new(GET => PEOPLEAPIENDPOINTSELF) or die 'Failed to initialize HTTP::Request'; # ステージング
            $req->header( 'Authorization' => get_oauth_header(%oauth) );
            my $ua      = LWP::UserAgent->new or die 'Failed to initialize LWP::UserAgent';
            my $res     = $ua->request($req) or die 'Failed to request';
            my $result  = JSON::XS::decode_json($res->decoded_content);

        if ($result->{Error}) {
            #warn encode('utf-8', $result->{Error}{Message}), "\n";
            warn Dumper($result);
        }
        else {
            #*********************************
            # グリーのAPIデータと置換文字の設定
            # 置き換え文字はgsa_xxxyy
            #*********************************
            map { $obj->{$_} = MyClass::WebUtil::convertByNKF('-s', $result->{person}{$_}) } keys %{ $result->{person} };

            #*********************************
            # cacheの名前空間 gsa_me_self:{id}
            #*********************************
            $self->memcached->add("$namespace:$user_id", $obj, 1800);
        }
    }

    return $obj;
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


#************************************************************************************************************
# @desc     SOCIAL APPLICATION METHODS END
#************************************************************************************************************

#******************************************************
# @desc     
#******************************************************
sub MAINURL {
    my $self =shift;

    $self->{MAINURL} = sprintf("%s/%s?%s", $self->MAIN_URL(), $self->CONFIGURATION_VALUE('BASE_CONTROLER_NAME'), $self->__member_param());

    #$self->{MAINURL} = $self->{MAINURL};

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
# @desc     サイト内画像表示
#******************************************************
sub SITEIMAGE_SCRIPTDATABASE_URL {
    my $self = shift;
    $self->{SITEIMAGE_SCRIPTDATABASE_URL} = sprintf("%s%s", $self->MAIN_URL, $self->CONFIGURATION_VALUE('SITEIMAGE_SCRIPTDATABASE_NAME'));

    return $self->{SITEIMAGE_SCRIPTDATABASE_URL};
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
    #return (defined($self->query->param('wakuwaku_access_token')) ? sprintf("%s&wakuwaku_access_token=%s", $self->{userid_ciphered}, $self->query->param('wakuwaku_access_token')) : $self->{userid_ciphered});
}


sub __member_param {
    my $self = shift;
    $self->{__member_param} = sprintf("s=%s&", $self->userid_ciphered);
    #$self->{__member_param} = defined($self->query->param('wakuwaku_access_token')) ? sprintf("s=%s&wakuwaku_access_token=%s&", $self->userid_ciphered, $self->query->param('wakuwaku_access_token')) : sprintf("s=%s&", $self->userid_ciphered);
    return $self->{__member_param};
}


1;
__END__
