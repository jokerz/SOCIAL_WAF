#******************************************************
# @desc      
# @desc      ItemShopのクラス
# @package   MyClass::Gree::ItemShop
# @access    public
# @author    Iwahase Ryo
# @create    2011/04/04
# @update    
# @version    1.00
#******************************************************
package MyClass::Gree::ItemShop;

use 5.008005;
our $VERSION = '1.00';
use strict;
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
use constant {
    CONSUMERKEY           => '487e3dfca60b',
    CONSUMERSECRET        => '4a566cdaeb2f311e2f914181dcf3c83b',
    PEOPLEAPIENDPOINTSELF => 'http://os-sb.gree.jp/api/rest/people/@me/@self',
    PEOPLEAPIENDPOINTALL  => 'http://os-sb.gree.jp/api/rest/people/@me/@all',
    PAYMENTAPIENDPOINT    => 'http://os-sb.gree.jp/api/rest/payment/@me/@self/@app',
    REQUEST_METHOD  =>  'POST',
    REQUEST_URI     =>  'http://os-sb.gree.jp/api/rest/payment/@me/@self/@app',
};


use base qw(MyClass::Gree);

use MyClass::WebUtil;
use MyClass::JKZSession;

use MyClass::JKZDB::ItemCategory;
use MyClass::JKZDB::Item;
use MyClass::JKZDB::ItemImage;
use MyClass::JKZDB::GsaUserItemOrder;

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


sub run {
    my $self = shift;

    $self->SUPER::run();
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
    #$str =>  s!([^a-zA-Z0-9_.> -])!sprintf '%%%02X',ord($1)!ge;
    $str =~  s!([^a-zA-Z0-9_.> -])!sprintf '%%%02X',ord($1)!ge;
    $str;
}

sub uri_encode() {
	foreach(@_) {
		$_ =~ s|([^a-zA-Z0-9\-\._\~])|
			my $x = '%' . unpack('H2', $1);
			$x =~ tr/a-f/A-F/;	#重要!!
			$x;
		|eg;
	}
}


#******************************************************
# @access    public
# @desc      itemshopトップ
# @param    
# @return    
#******************************************************
sub view_itemshop {
    my $self = shift;
    my $q    = $self->query();
    my $obj;
    ## デフォルトで「ぱわぁ」アイテムの表示
    my $item_category_id  = $q->param('ic') || 8;
    my $a                 = $q->param('a');
    my $o                 = $q->param('o');
    my $offset            = $q->param('off') || 0;
    my $record_limit      = 5;
    my $condition_limit   = $record_limit+1;

    my $namespame         = $self->waf_name_space() . 'ItemListByItemCategory';
    my $item_categorym_id = $item_category_id * 1000;
    $obj                  = $self->memcached->get("$namespame:$item_categorym_id:offset:$offset");

    if (!$obj) {
        my $dbh = $self->getDBConnection();
        $self->setDBCharset('sjis');

        my $Item = MyClass::JKZDB::Item->new($dbh);
        my $maxrec = $Item->getCountSQL(
            {
                columns     => 'item_id',
                whereSQL    => 'item_categorym_id = ? AND status_flag= ?',
                orderbySQL  => 'item_id ASC',
                limitSQL    => "$offset, $condition_limit",
                placeholder => [$item_categorym_id, 2]
            }
        );

        my @navilink;
        ## レコード数が1ページ上限数より多い場合
        if ($maxrec > $record_limit) {
           my $url = sprintf("%sa=%s&o=%s&ic=", $self->ITEMSHOP_URL, $a, $o, $item_category_id);

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


        my $ItemList = MyClass::JKZDB::Item->new($dbh);
        $ItemList->executeSelectList({
                whereSQL    => 'item_categorym_id = ? AND status_flag= ?',
                orderbySQL  => 'item_id ASC',
                limitSQL    => "$offset, $condition_limit",
                placeholder => [$item_categorym_id, 2]
        });
        map { $obj->{$_} = $ItemList->{columnslist}->{$_} } keys %{ $ItemList->{columnslist} };

        $self->memcached->add("$namespame:$item_categorym_id:offset:$offset", $obj, 6000);
    }


    #$obj->{LoopItemList} = $#{ $obj->{item_id} };
    $obj->{LoopItemList} = ( $#{ $obj->{item_id} } >= $record_limit ) ? $#{ $obj->{item_id} } - 1 : $#{ $obj->{item_id} };
    if (0 <= $obj->{LoopItemList}) {
        $obj->{IfExistsItemList} = 1;
#        my $itemcategoryobj = $self->getFromObjectFile( { CONFIGURATION_VALUE => 'ITEMCATEGORYLIST_OBJ' } );
        map {
            $obj->{ITEM_ID}->[$_]                       = ($obj->{item_categorym_id}->[$_] + $obj->{item_id}->[$_]);
            $obj->{Esc_item_name}->[$_]                 = $q->escape($obj->{item_name}->[$_]);
            $obj->{Esc_item_description}->[$_]          = $q->escape($obj->{item_description}->[$_]);
            $obj->{Esc_item_detail}->[$_]               = $q->escape($obj->{item_detail}->[$_]);
#            $obj->{Esc_item_name}->[$_]                 = $obj->{item_name}->[$_];
#            $obj->{Esc_item_description}->[$_]          = $obj->{item_description}->[$_];
#            $obj->{Esc_item_detail}->[$_]               = $obj->{item_detail}->[$_];

			## 額縁は7000番台 複数購入OK？？今回は複数購入OK処理
			## 購入時に複数購入OKアイテムか単品だけかの処理分岐
			(6000 == $item_categorym_id || 11000 == $item_categorym_id) ? $obj->{IfItemIsSetItem}->[$_] = 1 : $obj->{IfItemIsUseItem}->[$_] = 1;
			#(6 == $item_category_id || 11 == $item_category_id) ? $obj->{IfItemIsSetItem}->[$_] = 1 : $obj->{IfItemIsUseItem}->[$_] = 1;

            $obj->{item_detail}->[$_]                   = MyClass::WebUtil::escapeTags($obj->{item_detail}->[$_]);
            $obj->{LITEMIMAGE_SCRIPTDATABASE_URL}->[$_] = sprintf("%s/%s", $self->MAIN_URL, $self->CONFIGURATION_VALUE('ITEM_IMAGE_SCRIPTDATABASE_NAME'));
            $obj->{LITEMSHOP_URL}->[$_]                 = $self->ITEMSHOP_URL;
            $obj->{S}->[$_]                             = $self->userid_ciphered;
            #$obj->{ITEMTYPEJP}->[$_]             = MyClass::WebUtil::convertByNKF('-s', $self->fetchOneValueFromConf('ITEMTYPEJP', ( log($obj->{item_type}->[$_]) / log(2) ) ));
        }0..$obj->{LoopItemList};
    }
    else {
        $obj->{IfNotExistsItemList} = 1;
    }
warn Dump($obj);
    #*************************
    # アイテムのカテゴリ取得
    #*************************
    my $itemcategoryobj = $self->getFromObjectFile( { CONFIGURATION_VALUE => 'ITEMCATEGORYLIST_OBJ' } );

    my $idx = 0;

    foreach my $aryref ( @{ $itemcategoryobj} ) {
        next if 2 != $aryref->{status_flag};
        next if 1 == $aryref->{item_category_id};
        last if 8 < $aryref->{item_category_id};
        $obj->{item_category_name}->[$idx] = $aryref->{item_category_name};
        $obj->{item_category_id}->[$idx]   = $aryref->{item_category_id};
        $obj->{LITEMSHOP_URL}->[$idx]      = $self->ITEMSHOP_URL;

        $obj->{IfOtherItemCategory}->[$idx] = ( $item_category_id != $obj->{item_category_id}->[$idx] ) ? 1 : 0;
        $obj->{SEPARATER}->[$idx]           = ( 0 == $idx ) ? "" : '|';
        $obj->{lgree_user_id}->[$idx] = $self->opensocial_viewer_id;
        $idx++;
    }
    $obj->{item_category_description_now} = $itemcategoryobj->[$item_category_id]->{item_category_description};
    $obj->{item_category_warning_now} = $itemcategoryobj->[$item_category_id]->{item_category_warning};
    $obj->{LoopItemCategoryList} = $idx - 1;

    return $obj;
}


#******************************************************
# @desc     アイテム注文終了画面
# @param    paymentId 決済APIサーバーからのパラメータ
# @return    
#******************************************************
sub finish_order {
    my $self        = shift;
    my $paymentId   = $self->query->param('paymentId');

    my $dbh = $self->getDBConnection();
    $self->setDBCharset('sjis');

    my $myItemOrder = MyClass::JKZDB::GsaUserItemOrder->new($dbh);
    my $obj         = $myItemOrder->fetchItemOrderDataByPaymentID($paymentId);

    (2 == $obj->{status}) ? $obj->{IfOrderStatusIsCompleted}    = 1 :
    (3 == $obj->{status}) ? $obj->{IfOrderStatusIsCanceled}     = 1 :
    (4 == $obj->{status}) ? $obj->{IfOrderStatusIsExpired}      = 1 :
                            $obj->{IfOrderStatusIsInCompleted}  = 1;

    return $obj;
}




#******************************************************
# @access    public
# @desc      アイテム注文処理
# @param    
# @return    
#******************************************************
sub confirm_order {
    my $self = shift;
    my $q    = $self->query();
    $q->autoEscape(0);
    my $obj;


    if(1 > $q->param('qty')) {
        $obj->{IfNoQTYError} = 1;
        $self->action('error');
        return $obj;
    }

    my $item_id                  = $q->param('i');
    my $item_unit_price          = $q->param('iup');
    my $item_categorym_id        = $q->param('ic');
    my $quantity                 = $q->param('qty');
    my $encoded_item_name        = $q->param('Esc_item_name');
    my $encoded_item_description = $q->param('Esc_item_description');
    my $encoded_item_detail      = $q->param('Esc_item_detail');

    $obj->{S}                    = $q->param('s');

    $obj->{ITEM_ID}              = $item_id;
    $obj->{item_unit_price}      = $item_unit_price;
    $obj->{qty}                  = $q->param('qty');
    $obj->{item_name}            = $q->unescape($q->param('Esc_item_name'));
    $obj->{item_description}     = $q->unescape($q->param('Esc_item_description'));
    $obj->{item_detail}          = $q->unescape($q->param('Esc_item_detail'));
    $obj->{item_total_price}     = ( $item_unit_price * $quantity );
    $obj->{item_category_id}     = $item_categorym_id;
    $obj->{Esc_item_name}        = $q->escape($q->param('Esc_item_name'));
    $obj->{Esc_item_description} = $q->escape($q->param('Esc_item_description'));
    $obj->{Esc_item_detail}      = $q->escape($q->param('Esc_item_detail'));

#    unless ($q->param('proceed')) {
#        return $obj;
#    }
#    if ($q->param('proceed')) {

        my $imageUrl = sprintf("%s?ii=%s", $self->ITEMIMAGE_SCRIPTDATABASE_URL, $obj->{ITEM_ID});

=pod
        my $data = {
            callbackUrl     => 'http://st.moepetit.jp/event/paymentapp.mpl',
            finishPageUrl   => 'http://st.moepetit.jp/itemshop_app.mpl?a=finish&o=order',
            message         => $obj->{Esc_item_detail},
            paymentItems    => [
                {
                    itemId      => $obj->{ITEM_ID},
                    itemName    => $obj->{item_name},
                    unitPrice   => $obj->{item_unit_price},
                    quantity    => $obj->{qty},
                    imageUrl    => $imageUrl,
                    description => $obj->{item_description},
                },
            ],
        };
=cut

#$obj->{utf8_item_detail} = item_id$obj->{item_detail});
#$obj->{utf8_item_name} = MyClass::WebUtil::convertByNKF('-w', $obj->{item_name});
#$obj->{utf8_item_description} = MyClass::WebUtil::convertByNKF('-w', $obj->{item_description});

#$obj->{utf8_item_detail}      = $q->unescape($obj->{utf8_item_detail});
#$obj->{utf8_item_name}        = $q->unescape($obj->{utf8_item_name});
#$obj->{utf8_item_description} = $q->unescape($obj->{utf8_item_description});



#$item_id                  
#$item_unit_price          
#$item_categorym_id        
#$quantity                 
#$encoded_item_name        = MyClass::WebUtil::convertByNKF('-w', $encoded_item_name);
#$encoded_item_description = MyClass::WebUtil::convertByNKF('-w', $encoded_item_description);
#$encoded_item_detail      = MyClass::WebUtil::convertByNKF('-w', $encoded_item_detail);



        my $data = {
            callbackUrl     => 'http://st.moepetit.jp/event/paymentapp.mpl',
            finishPageUrl   => 'http://st.moepetit.jp/itemshop_app.mpl?a=finish&o=order',
            message         => $encoded_item_detail,
            paymentItems    => [
                {
                    itemId      => $item_id,
                    itemName    => $encoded_item_name,
                    unitPrice   => $item_unit_price,
                    quantity    => $quantity,
                    imageUrl    => $imageUrl,
                    description => $encoded_item_description,
                },
            ],
        };



        use JSON::XS;
        use OAuth::Lite;
        use OAuth::Lite::Consumer;

    my $nonce          = generate_nonce();
    my $consumersecret = sprintf("%s&%s", CONSUMERSECRET, $self->oauth_token_secret);

    ### リクエストパラメータの準備
    my %oauth = (
        oauth_consumer_key      => CONSUMERKEY,
        oauth_token             => $self->oauth_token,
        oauth_signature_method  => 'HMAC-SHA1',
        oauth_timestamp         => time,
        oauth_nonce             => generate_nonce(),
        oauth_version           => '1.0',
        xoauth_requestor_id     => $self->opensocial_viewer_id,
    );


    my ($realm, $params) = parse_auth_header($ENV{HTTP_AUTHORIZATION});

    for my $key ($q->url_param) {
        $params->{$key} = [$q->url_param($key)];
    }

    if (uc $q->request_method eq 'POST'
        && $q->content_type =~ m{^\Qapplication/x-www-form-urlencoded})
    {
        for my $key ($q->param) {
            $params->{$key} = $q->param($key);
        }
    }

#warn '-'x100, "\n", "Parameters1 \n", '-'x100, "\n",Dumper($params);

    delete $params->{opensocial_owner_id};
    delete $params->{opensocial_viewer_id};
    delete $params->{opensocial_app_id};
#delete $params->{};


## BaseStringが一致しないのでこのパラムを削除 2011/04/18 BEGIN
#$params->{Esc_item_name}        = $q->escape($params->{Esc_item_name});
#$params->{Esc_item_description} = $q->escape($params->{Esc_item_description});
#$params->{Esc_item_detail}      = $q->escape($params->{Esc_item_detail});
    delete $params->{a};
    delete $params->{Esc_item_description};
    delete $params->{Esc_item_detail};
    delete $params->{Esc_item_name};
    delete $params->{i};
    delete $params->{ic};
    delete $params->{iup};
    delete $params->{o};
    delete $params->{qty};
## BaseStringが一致しないのでこのパラムを削除 2011/04/18 END

warn '-'x100, "\n", "Parameters2 \n", '-'x100, "\n",Dumper($params);


## ここでもparamに挿入して順番をそろえる必要がある そして$msg3に代入する
=pod
$params->{oauth_consumer_key}      = CONSUMERKEY;
$params->{oauth_token}             = $self->oauth_token;
$params->{oauth_signature_method}  = 'HMAC-SHA1';
$params->{oauth_timestamp}         = time;
$params->{oauth_nonce}             = $oauth{oauth_nonce};
$params->{oauth_version}           = '1.0';
$params->{xoauth_requestor_id}     = $self->opensocial_viewer_id;
$params->{oauth_consumer_key}      = CONSUMERKEY;
=cut

    $params->{oauth_consumer_key}      = $oauth{oauth_consumer_key};
    $params->{oauth_token}             = $oauth{oauth_token};
    $params->{oauth_signature_method}  = $oauth{oauth_signature_method};
    $params->{oauth_timestamp}         = $oauth{oauth_timestamp};
    $params->{oauth_nonce}             = $oauth{oauth_nonce};
    $params->{oauth_version}           = '1.0';
    $params->{xoauth_requestor_id}     = $oauth{xoauth_requestor_id};


warn '-'x100, "\n", "Parameters3 \n", '-'x100, "\n",Dumper($params);


    my $param = join '&', map {
        join '=', $_, $params->{$_};
    } sort keys %{ $params };


#warn '-'x100, "\n", "Param\n", '-'x100, "\n",Dumper($param);

my $msg1 = 'POST';
my $msg2 = REQUEST_URI;
my $msg3 = $param;# . "&oauth_consumer_key=" . CONSUMERKEY;


    &uri_encode($msg1, $msg2, $msg3);
    my $msg = "$msg1&$msg2&$msg3";

warn '-'x100, "\n", "msg\n", '-'x100, "\n",Dumper($msg);


    $oauth{oauth_signature} = _encode_base64(Digest::HMAC_SHA1::hmac_sha1($msg,$consumersecret));


#warn '-'x100, "\n", "Signature\n", '-'x100, "\n",Dumper($oauth{oauth_signature});

    &uri_encode($oauth{oauth_signature});

## 順番が重要？？？
#my $header = get_oauth_header (%oauth);
#**************************
# oauth_version="1.0",
# oauth_nonce="CqWLVz8GkaL",
# oauth_timestamp="1272026745",
# oauth_consumer_key="d308e3ccg59e",
# oauth_token="abcdefghi",
# oauth_signature="McJbJB9kwTKOWSwVVf4FbWiCWNw%3D",
# oauth_signature_method="HMAC-SHA1",
# xauth_requestor_id="0123456"
#**************************

    my $header = sprintf("OAuth oauth_version=\"%s\",oauth_nonce=\"%s\",oauth_timestamp=\"%s\",oauth_consumer_key=\"%s\",oauth_token=\"%s\",oauth_signature=\"%s\",oauth_signature_method=\"%s\",xoauth_requestor_id=\"%s\"",
'1.0',
$oauth{oauth_nonce},
$oauth{oauth_timestamp},
$oauth{oauth_consumer_key},
$oauth{oauth_token},
$oauth{oauth_signature},
$oauth{oauth_signature_method},
$oauth{xoauth_requestor_id}
);

#warn '-'x100, "\n", "OAuthHeader\n", '-'x100, "\n",Dumper($header);



    my $req = HTTP::Request->new(REQUEST_METHOD, REQUEST_URI) or die 'Failed to initialize HTTP::Request';
#warn "\n",__LINE__, "\n";
    $req->header( 'Authorization' => get_oauth_header (%oauth) );
#warn "\n",__LINE__, "\n";
    $req->content_type('application/json');
#warn "\n",__LINE__, "\n";
    $req->content(JSON::XS::encode_json($data));
#warn "\n",__LINE__, "\n";


### リクエストを投げる
    my $ua = LWP::UserAgent->new or die 'Failed to initialize LWP::UserAgent';

#warn "\n",__LINE__, "\n";
    my $res = $ua->request($req) or die 'Failed to request';
#warn "\n",__LINE__, "\n";
#warn '-' x 72, "\n", "Response\n", '-' x 72, "\n", Dumper ($res);#DEBUG
#warn "\n",__LINE__, "\n";

        if ($res->is_success) {

#            use Encode;
        #*********************************
        # レスポンス
        # entry => {
        #    paymentId     => 数字ハイフン
        #    status        => int [ 1 (決済ID発行) 2 (決済完了) 3 (キャンセル) 4 (期限切れ) ]
        #    transctionUrl => 決済サーバーURL
        #    orderedTime   => yyyy-mm-dd hh:mm:ss
        # }
        #*********************************
            #my $result            = JSON->new->utf8(0)->decode(decode_utf8($res->decoded_content));
            my $result             = JSON::XS::decode_json($res->decoded_content);
            $obj->{paymentId}      = $result->{entry}[0]{paymentId};
            $obj->{status}         = $result->{entry}[0]{status};
            $obj->{transactionUrl} = $result->{entry}[0]{transactionUrl};
            $obj->{orderedTime}    = $result->{entry}[0]{orderedTime};


            return print "Location: $obj->{transactionUrl}\n\n";
            1;
#            return print "Location: $obj->{transactionUrl}\n\n";

        }
        else {
            warn $res->status_line;
            $obj->{DUMP} = Dumper($res);

            return $obj;
        }
}




1;

__END__

