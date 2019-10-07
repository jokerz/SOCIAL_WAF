#******************************************************
# $Id: ,v 1.0 2011/mm/dd RyoIwahase Exp $
# @desc      
# 
# @package   MyClass::Gree::ItemExchange
# @access    
# @author    Iwahase Ryo
# @create    yyyy/mm/dd
# @update    
# @version   1.0
#******************************************************
package MyClass::Gree::ItemExchange;


use strict;
use warnings;
no warnings 'redefine';
use 5.008005;
our $VERSION = '1.00';

use base qw(MyClass::Gree::MyPage);

use MyClass::WebUtil;
#use MyClass::JKZSession;
use MyClass::JKZDB::MyItem;
use MyClass::JKZDB::ItemCategory;
use MyClass::JKZDB::Item;
use MyClass::JKZDB::ItemImage;

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



#******************************************************
# @desc     アイテム交換実行
# @param    
# @param    
# @return   
#******************************************************
sub exchange_my_item {
    my $self         = shift;
    my $gree_user_id = $self->opensocial_owner_id;
    my $q            = $self->query;
    my $obj;

    my $dbh     = $self->getDBConnection();
    $self->setDBCharset('sjis');

    # Get Post ともに必要なパラメータ(アイテムのID)
    my $i = $q->param('i');

    # Getの場合確認画面へ遷移
    if (!$q->MethPost) {

        if ("" eq $i || !$i) {
            $obj->{IfInvalidItemError} = 1;
            $self->action('error');
            return $obj;
        }

        $obj->{IfConfirmExchangeMyItem} = 1;
        my $myItem  = MyClass::JKZDB::MyItem->new($dbh);
        my $aryref  = $myItem->fetchMyItemByItemID({ gree_user_id => $gree_user_id, itemm_id => 12001, status_flag => 2 });

        $obj->{item_name}   = $aryref->[0]->{item_name};
        $obj->{item_qty}    = scalar @{ $aryref };
        $obj->{MII}         = join(':', map { $aryref->[$_]->{my_item_id} } 0..9 );
        $obj->{S}           = $self->userid_ciphered;
    }
    elsif($q->MethPost) { # POSTの場合は交換処理実行
        my @mii         = split(/:/, $q->param('mii'));# miiパラメータを配列に格納 10個なければNG
        if(10 != scalar @mii) {
            $obj->{IfInvalidItemError} = 1;
            $self->action('error');
            return $obj;
        }

        ## SQL共通の部分 不正チェック時とデータ更新時に使用
        my $whereSQL = "WHERE my_item_id IN(?,?,?,?,?,?,?,?,?,?) AND status_flag=2;";

        #************************************************************
        # 不正チェック。ブラウザボタンで戻って再度交換とのチェック
        # my_item_idのstatus_flagが2であることを条件で戻り値が10以外は不正とみなす。
        # 交換するアイテムチケットは10枚
        #************************************************************
        my $checkSQL = sprintf("SELECT COUNT(my_item_id) FROM dMOEPETIT.tMyItemF %s", $whereSQL);
        my $rv  = $dbh->selectrow_array($checkSQL, undef, @mii);
        if (10 != $rv) {
            $obj->{IfInvalidItemError} = 1;
            $self->action('error');
            return $obj;
        }

        my $s               = $q->param('s');
        $obj->{item_name}   = $q->unescape($q->param('Esc_item_name'));

        # update SQL
        my $updateSQL = sprintf("UPDATE dMOEPETIT.tMyItemF SET status_flag=1 %s", $whereSQL);

        #************************
        # my_item_id生成
        #************************
        my $my_item_id = MyClass::WebUtil::createHash(join('', $s, time, $$, rand(9999)), 32);

        #****************************
        # 交換する所持アイテム処理と新規に追加するアイテム処理
        # Update -> Insert
        #****************************
        my $myItem      = MyClass::JKZDB::MyItem->new($dbh);
        my $newItem     = MyClass::JKZDB::MyItem->new($dbh);
        my $attr_ref    = MyClass::UsrWebDB::TransactInit($dbh);

        eval {
            #**************************
            # アイテム付与
            #**************************
            $newItem->executeUpdate({
                my_item_id          => $my_item_id,
                gree_user_id        => $gree_user_id,
                status_flag         => 2,
                item_type           => 2, # 本来は取得した消費系の値８
                item_categorym_id   => 12000,
                itemm_id            => $i,
                item_name           => $obj->{item_name},
            }, -1);

            #**************************
            # 交換アイテムチケット無効処理
            #**************************
            my $rc =  $dbh->do($updateSQL, undef, @mii);

            $dbh->commit();
        };
        if ($@) {
        $dbh->rollback();
            $obj->{IfExchangeMyItemError} = 1;
        }
        else {
            $obj->{IfExchangeMyItemSuccess} = 1;
        }

        MyClass::UsrWebDB::TransactFin($dbh, $attr_ref, $@);
    }

    return $obj;
}


#******************************************************
# @desc     アイテム交換所
#           萌えチケットが10枚以上ある場合はアイテムと交換できる処理
#           交換はmy_item_id10個を : でつなげて送信する
# @param    
# @return   
#******************************************************
sub view_itemexchange {
    my $self = shift;
    my $gree_user_id    = $self->opensocial_owner_id;
    my $q               = $self->query();
    my $obj;

    my $dbh = $self->getDBConnection();
    $self->setDBCharset('sjis');
    my $myItem = MyClass::JKZDB::MyItem->new($dbh);

    #*****************************
    # return { itemm_id, item_name, item_qty }
    # 下記オブジェクトの内容
    #*****************************
    $obj = $myItem->getCountOfMyItemByItemId({ gree_user_id => $gree_user_id, itemm_id => 12001, status_flag => 2 });
    ## 萌えﾁｹｯﾄが10枚以上ある場合アイテム交換ができる。my_item_idは10だけ必要のためループ処理を10回に制限
    if(10 <= $obj->{item_qty}) {
        $obj->{IfExChangeMoeTicketOK}   = 1;
    }
    else {
        $obj->{IfExChangeMoeTicketNG} = 1;
    }

    ## 萌えﾁｹｯﾄが10枚以上ある場合アイテム交換ができる。my_item_idは10だけ必要のためループ処理を10回に制限
    if(10 <= $obj->{item_qty}) {
        $obj->{IfExChangeMoeTicketOK}   = 1;
    }
    else {
        $obj->{IfExChangeMoeTicketNG} = 1;
    }

#if ($q->param('mii')) {
#    my @mii = split(/:/, $q->param('mii'));
#    $obj->{DUMP} = Dumper(\@mii);
#}




#    (10 <= $obj->{item_qty}) ? $obj->{IfExChangeMoeTicketOK} = 1 : $obj->{IfExChangeMoeTicketNG} = 1;


   # my $myItem = MyClass::JKZDB::MyItem->new($dbh);
   # my $aryref = $myItem->fetchMyItemForItemExchange($gree_user_id);
    ## アイテムの所持数が短順にチケット数になるから
   # $obj->{item_qty} = scalar @{ $aryref };

=pod

    my $namespame         = $self->waf_name_space() . 'ExchangeItemListByItemCategory';
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

    $obj->{LoopItemList} = ( $#{ $obj->{item_id} } >= $record_limit ) ? $#{ $obj->{item_id} } - 1 : $#{ $obj->{item_id} };
    if (0 <= $obj->{LoopItemList}) {
        $obj->{IfExistsItemList} = 1;
        map {
            $obj->{ITEM_ID}->[$_]                       = ($obj->{item_categorym_id}->[$_] + $obj->{item_id}->[$_]);
            $obj->{Esc_item_name}->[$_]                 = $q->escape($obj->{item_name}->[$_]);
            $obj->{Esc_item_description}->[$_]          = $q->escape($obj->{item_description}->[$_]);
            $obj->{Esc_item_detail}->[$_]               = $q->escape($obj->{item_detail}->[$_]);

            ## 額縁は7000番台 複数購入OK？？今回は複数購入OK処理
            ## 購入時に複数購入OKアイテムか単品だけかの処理分岐
            (6000 == $item_categorym_id || 11000 == $item_categorym_id) ? $obj->{IfItemIsSetItem}->[$_] = 1 : $obj->{IfItemIsUseItem}->[$_] = 1;

            $obj->{item_detail}->[$_]                   = MyClass::WebUtil::escapeTags($obj->{item_detail}->[$_]);
            $obj->{LITEMIMAGE_SCRIPTDATABASE_URL}->[$_] = sprintf("%s/%s", $self->MAIN_URL, $self->CONFIGURATION_VALUE('ITEM_IMAGE_SCRIPTDATABASE_NAME'));
            $obj->{LITEMSHOP_URL}->[$_]                 = $self->ITEMSHOP_URL;
            $obj->{S}->[$_]                             = $self->userid_ciphered;
        }0..$obj->{LoopItemList};
    }
    else {
        $obj->{IfNotExistsItemList} = 1;
    }

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
        $obj->{ITEMEXCHANGE_URL}->[$idx]      = $self->ITEMEXCHANGE_URL;

        $obj->{IfOtherItemCategory}->[$idx] = ( $item_category_id != $obj->{item_category_id}->[$idx] ) ? 1 : 0;
        $obj->{SEPARATER}->[$idx]           = ( 0 == $idx ) ? "" : '|';
        $obj->{lgree_user_id}->[$idx] = $self->opensocial_viewer_id;
        $idx++;
    }
    $obj->{item_category_description_now} = $itemcategoryobj->[$item_category_id]->{item_category_description};
    $obj->{item_category_warning_now} = $itemcategoryobj->[$item_category_id]->{item_category_warning};
    $obj->{LoopItemCategoryList} = $idx - 1;

=cut


    return $obj;
}



1;
__END__