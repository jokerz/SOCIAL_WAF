#******************************************************
# @desc     決済処理
#           決済APIサーバーかリクエストが送信されてから5秒以内に HTTPステータスを200のレスポンスが必要
#           ない場合は決済失敗とみなされる
#           ユーザーアイテム注文テーブルのステータス更新とユーザーのマイアイテムテーブルにデータのUPDATE / INSERTが完了したらすぐに
#           HTTPステータスを返すこと
# @package   MyClass::GREE::PaymentApp
# @access    public
# @author    Iwahase Ryo
# @create    2011/04/04
# @update    
# @version    1.00
#******************************************************
package MyClass::Gree::PaymentApp;

use strict;
use warnings;
no warnings 'redefine';
use 5.008005;
our $VERSION = '1.00';

use base qw(MyClass::Gree);

use MyClass::WebUtil;
use MyClass::JKZDB::GsaUserItemOrder;
use MyClass::JKZDB::MyItem;


#use NKF;

use Data::Dumper;

#******************************************************
# @access    public
# @desc        コンストラクタ
# @param    
# @return    
#******************************************************
=pod
sub new {
    my ($class, $cfg) = @_;

    return $class->SUPER::new($cfg);
}
=cut

sub run {
    my $self = shift;
    my $q    = $self->query;

    warn ">"x 120, "\n PAYMENT APP BEGINS \n","<"x120, "\n";


    unless ($self->__verify_oauth_signature()) {
        return $self->printErrorPage("invalid method call");
    } else {
        $self->userid_ciphered();


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

    ## 下記の値は認証ヘッダーから取得しなくてはならない
    my $paymentId               = $params->{paymentId}->[-1];
    my $status                  = $params->{status}->[-1];
    my $orderedTime             = $params->{orderedTime}->[-1];
    my $executedTime            = $params->{executedTime}->[-1];

    my $opensocial_app_id       = $q->param('opensocial_app_id');
    my $opensocial_viewer_id    = $q->param('opensocial_viewer_id');
    my $opensocial_owner_id     = $q->param('opensocial_owner_id');

    $self->connectDB();
    my $dbh         = $self->getDBConnection();
    $self->setDBCharset("sjis");

    my $myItemOrder = MyClass::JKZDB::GsaUserItemOrder->new($dbh);
    my $myMyItem    = MyClass::JKZDB::MyItem->new($dbh);
    my $attr_ref    = MyClass::UsrWebDB::TransactInit($dbh);

    eval {

        $myItemOrder->updateOrderStatusByPaymentID($paymentId, $status);

        #**************************
        # 決済完了ステータスが2の場合はアイテム注文テーブルからアイテム情報を取得
        # アイテムの購入数分アイテムの付与をしなくてはいけない。
        #**************************
        if (2 == $status) {
            #**************************
            # paymentId
            # status
            # orderTime
            # gree_user_id
            # itemm_id
            # item_type
            # item_categorym_id
            # item_name
            # qty
            # item_unit_price
            #**************************
            my $ref = $myItemOrder->fetchItemOrderDataByPaymentID($paymentId);

            # アイテムの購入数分アイテムの付与
            foreach (1..$ref->{qty}) {
                ## paymentId元に32文字のmy_item_idを生成
                my $my_item_id = MyClass::WebUtil::createHash(join('', $paymentId, time, $$, rand(9999)), 32);

                $myMyItem->executeUpdate(
                    {
                        my_item_id          => $my_item_id,
                        gree_user_id        => $opensocial_viewer_id,
                        status_flag         => 2,
                        item_type           => $ref->{item_type},
                        item_categorym_id   => $ref->{item_categorym_id},
                        itemm_id            => $ref->{itemm_id},
                        item_name           => $ref->{item_name},
                    },
                    -1
                );
            }
        }

        $dbh->commit();
    };

    if ($@) {
        $dbh->rollback();
        warn '-' x 72, "\n", "Event PaymentApp Failure \n", '-' x 72, "\n", $paymentId;
        #**********************************
        # アイテム付与失敗の場合は決済サーバーレスポンスをしない
        #**********************************
    }
    else {
        #**********************************
        # アイテム付与完了のHTTP200を決済サーバーに返す
        #**********************************
        my $namespace    = $self->waf_name_space() . '_gsa_user_gameitem';
        $self->memcached->delete("$namespace:$opensocial_viewer_id");

        print $self->query->header(-status => '200 OK');
        warn '-' x 72, "\n", "Event PaymentApp Success \n", '-' x 72, "\n", $paymentId;
    }

    MyClass::UsrWebDB::TransactFin($dbh, $attr_ref, $@);
    $self->disconnectDB();
    }
}


1;
__END__

=pod
        # session_idをアイテム固有のユニークIDとして管理する。
        #use CGI::Session;
        #my $session    = CGI::Session->new(undef, undef, { Directory=>'/tmp' });
        #my $my_item_id = $session->id;
        #$session->close;
        #$session->delete;
=cut