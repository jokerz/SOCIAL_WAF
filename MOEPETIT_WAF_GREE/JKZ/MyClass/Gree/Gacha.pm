#******************************************************
# $Id: ,v 1.0 2011/mm/dd RyoIwahase Exp $
# @desc      ガチャガチャ
# 
# @package   MyClass::Gree::Gacha
# @access    
# @author    Iwahase Ryo
# @create    2011/05/12
# @update    
# @version   1.0
#******************************************************
package MyClass::Gree::Gacha;

use strict;
use warnings;
no warnings 'redefine';
use 5.008005;
our $VERSION = '1.00';

use base qw(MyClass::Gree::MyPage);

use MyClass::WebUtil;

use MyClass::JKZDB::GsaUserGachaLog;
use MyClass::JKZDB::Item;
use MyClass::JKZDB::MyItem;
use MyClass::JKZDB::GsaUserStatus;

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


sub run {
    my $self = shift;

    $self->SUPER::run();
}



sub fcheck_play_gacha {
    my $self = shift;
    return;
}


sub fresult_play_gacha {
    my $self            = shift;
    my $gree_user_id    = $self->opensocial_owner_id;
    my $s               = $self->query->param('s');
    my $obj;

    my $dbh = $self->getDBConnection();
    $self->setDBCharset("sjis");
    #******************************
    # 本日のガチャ済みチェック
    #******************************
    ## 本日のガチャ確認 (ガチャ済みは戻りが1)
    my $myGacha = MyClass::JKZDB::GsaUserGachaLog->new($dbh);
    !$myGacha->checkGachaToday($gree_user_id) ? $obj->{IfGachaForToday} = 1 : $obj->{IfGachaNoMoreForToday} = 1;

    if ($obj->{IfGachaNoMoreForToday}) {
        return $obj;
    }

    #******************************
    # ガチャアイテム情報
    #******************************
    my $namespace_gacha_item = sprintf("%s_gacha_item", $self->waf_name_space);
    my $gachaobj = $self->memcached->get("$namespace_gacha_item");
    if (!$gachaobj) {
        my $Item = MyClass::JKZDB::Item->new($dbh);

        $gachaobj = $Item->fetchGachaItem();
        $gachaobj->{itemm_id} = ($gachaobj->{item_categorym_id} + $gachaobj->{item_id});
        $self->memcached->add("$namespace_gacha_item", $gachaobj, 3600);
    }

#**************************
# ガチャ実行・計算
#**************************
    my $gacha_item1 = 1;    # 1枚チケット 90%の確立
    my $gacha_item3 = 3;    # 3枚チケット  8%の確立
    my $gacha_item5 = 5;    # 5枚チケット  2%の確立

    my $get_gacha_item_qty; # 取得したアイテム数

#**************************
# 通常のアイテム item_type item_categorym_id, itemm_id, item_name
#**************************
    my $item2001     = MyClass::WebUtil::convertByNKF('-s', 'よくみえぇる');
    my $item3001     = MyClass::WebUtil::convertByNKF('-s', 'ゆっくりみえぇる');
    my $item4001     = MyClass::WebUtil::convertByNKF('-s', 'いなずま');
    my $item5001     = MyClass::WebUtil::convertByNKF('-s', 'ｷﾞｶﾞいなずま');
    my $item8001     = MyClass::WebUtil::convertByNKF('-s', 'ぱわぁ1');
    my $item8002     = MyClass::WebUtil::convertByNKF('-s', 'ぱわぁ2');
    my $item8003     = MyClass::WebUtil::convertByNKF('-s', 'ぱわぁ5');
    my $present_item = {
        item2001    => [ 2, 2000, 2001, $item2001 ],
        item3001    => [ 2, 3000, 3001, $item3001 ],
        item4001    => [ 2, 4000, 4001, $item4001 ],
        item5001    => [ 2, 5000, 5001, $item5001 ],
        item8001    => [ 2, 8000, 8001, $item8001 ],
        item8002    => [ 2, 8000, 8002, $item8002 ],
        item8003    => [ 2, 8000, 8003, $item8003 ],
    };

    ## --- 乱数を発生
    srand;
    my $x = rand;
    my $y = rand; # 通常アイテム用

    # $x は 0 から 100 までの整数値を返す
    $x = int($x * 100);
    $y = int($y * 100);
    #*******************************************
    # 確立での計算
    # 下記の三項演算は順に90% 8% 2%
    #*******************************************
    $get_gacha_item_qty =
        ($x < 90) ? $gacha_item1 :
        ($x < 98) ? $gacha_item3 :
                    $gacha_item5 ;

    #*******************************************
    #
    # 75% 10% 6% 4% 3% 1% 1%
    #*******************************************
    my $get_present_item_key =
        ($y < 75) ? 'item8001' :
        ($y < 85) ? 'item8002' :
        ($y < 91) ? 'item2001' :
        ($y < 95) ? 'item3001' :
        ($y < 98) ? 'item4001' :
        ($y < 99) ? 'item8003' :
                    'item5001' ;

    my $myGachaLog  = MyClass::JKZDB::GsaUserGachaLog->new($dbh);
    my $myGachaItem = MyClass::JKZDB::MyItem->new($dbh);
    my $myItem      = MyClass::JKZDB::MyItem->new($dbh);
#    my $UserPowerLog = MyClass::JKZDB::GsaUserPowerLog->new($dbh);
    my $UserStaus   = MyClass::JKZDB::GsaUserStatus->new($dbh);

    my $attr_ref    = MyClass::UsrWebDB::TransactInit($dbh);

    eval {

    #************************
    # 一度は共通のmy_item_id
    #************************
        my $my_gitem_id = MyClass::WebUtil::createHash(join('', $s, time, $$, rand(9999)), 32);
        my $my_item_id  = MyClass::WebUtil::createHash(join('', $s, time, $$, rand(9999)), 32);

        $myGachaLog->switchMRG_MyISAMTableSQL( { separater => '_', value => MyClass::WebUtil::GetTime("5") } );
        $myGachaLog->executeUpdate({
            gree_user_id => $gree_user_id,
            my_item_id   => $my_item_id,
            itemm_id     => $gachaobj->{itemm_id},
            item_name    => $gachaobj->{item_name},
        }, -1);


        $myGachaItem->executeUpdate({
            my_item_id          => $my_gitem_id,
            gree_user_id        => $gree_user_id,
            status_flag         => 2,
            item_type           => $gachaobj->{item_type},
            item_categorym_id   => $gachaobj->{item_categorym_id},
            itemm_id            => $gachaobj->{itemm_id},
            item_name           => $gachaobj->{item_name},
        }, -1);


        $myItem->executeUpdate({
            my_item_id          => $my_item_id,
            gree_user_id        => $gree_user_id,
            status_flag         => 2,
            item_type           => $present_item->{$get_present_item_key}->[0],
            item_categorym_id   => $present_item->{$get_present_item_key}->[1],
            itemm_id            => $present_item->{$get_present_item_key}->[2],
            item_name           => $present_item->{$get_present_item_key}->[3],
        }, -1);

    #******************************
    # ぱぁーの増減ログ アイテム使用してのぱわぁの値は 2
    # INSERT
    #******************************
=pod
        $UserPowerLog->executeUpdate({
            id              => -1,
            gree_user_id    => $gree_user_id,
            power           => $ADDPOWER,
            type_of_power   => 2,
            id_of_type      => $my_item_id,
        });
=cut
    #******************************
    # 1日1度のパワー付与をここで実行
    # UPDATE
    #******************************
        $UserStaus->updateMyPower({
            gree_user_id    => $gree_user_id,
            my_power        => 5,
        }, 1);


        #**************************
        # アイテム取得数が２枚以上の場合
        #**************************
        if (1 < $get_gacha_item_qty) {
            map {

                my $my_gitem_id = MyClass::WebUtil::createHash(join('', $s, time, $$, rand(9999)), 32);
                $myItem->executeUpdate({
                    my_item_id          => $my_gitem_id,
                    gree_user_id        => $gree_user_id,
                    status_flag         => 2,
                    item_type           => $gachaobj->{item_type},
                    item_categorym_id   => $gachaobj->{item_categorym_id},
                    itemm_id            => $gachaobj->{itemm_id},
                    item_name           => $gachaobj->{item_name},
                }, -1);

            } 1..($get_gacha_item_qty - 1);
        }

        $dbh->commit();
    };
    if ($@) {
        $dbh->rollback();
        $obj->{IfGetGachaItemFailure} = 1;
    }
    else {
        $obj->{IfGetGachaItemSuccess} = 1;
        $obj->{gacha_item_name}    = $gachaobj->{item_name};
        $obj->{get_gacha_item_qty} = $get_gacha_item_qty;
        $obj->{normal_item_id}     = $present_item->{$get_present_item_key}->[2];
        $obj->{normal_item_name}   = $present_item->{$get_present_item_key}->[3];

        my $namespace           = $self->waf_name_space();
        my $namespace_userstaus = sprintf("%s_userstatus", $namespace);
        ## ユーザーステータスのキャッシュを削除
        $self->memcached->delete("$namespace_userstaus:$gree_user_id");

        MyClass::UsrWebDB::TransactFin($dbh, $attr_ref, $@);

        #*****************************
        # アクティビティAPI処理用 2011/06/08 END
        #*****************************
        if ($get_gacha_item_qty == 5) {
use JSON;
use MIME::Base64;
use Digest::HMAC_SHA1;
use HTTP::Request;
use LWP::UserAgent;
use Data::Dumper;
                my $nonce           = generate_nonce();
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

                my $ACTIVITY_TITLE = $self->cfg->param('ACTIVITYE_API_PHRASE2');
                my $data            = {
                    title   => $ACTIVITY_TITLE,
                    url     => 'http://mpf.gree.jp/1370',
                };

                my $req = HTTP::Request->new(POST => 'http://os.gree.jp/api/rest/activities/@me/@self/@app') or die 'Failed to initialize HTTP::Request'; # 商用環境

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
            #*****************************
            # アクティビティAPI処理用 2011/06/08 END
            #*****************************

    }

    return $obj;
}


1;
__END__

    #*******************************************
    # 確立での計算
    #*******************************************
=pod

    my $gacha_item1;    # 1枚チケット 50%の確立
    my $gacha_item2;    # 2枚チケット 20%の確立
    my $gacha_item3;    # 3枚チケット 20%の確立
    my $gacha_item3;    # 4枚チケット  8%の確立
    my $gacha_item3;    # 5枚チケット  2%の確立

    my $get_gacha_item; # 取得したアイテム変数

## --- 乱数を発生
    srand;
    $x = rand;

    # $x は 0 から 100 までの整数値を返す
    $x = int($x * 100);

    # 順に 確立 50% 20% 20% 8% 2%
    $get_gacha_item =
        ($x < 50) ? $gacha_item1 :
        ($x < 70) ? $gacha_item2 :
        ($x < 90) ? $gacha_item3 :
        ($x < 98) ? $gacha_item4 :
                    $gacha_item5;

=cut
