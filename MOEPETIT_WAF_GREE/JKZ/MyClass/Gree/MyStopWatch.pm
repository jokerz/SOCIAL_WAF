#******************************************************
# @desc      MyStopWatchのクラス
# @desc      マイページの情報やフラッシュゲーム処理、ユーザーアクション全般
#
# @package   MyClass::Gree::MyStopWatch
# @access    public
# @author    Iwahase Ryo
# @create    2011/03/30
# @update    
# @version    1.00
#******************************************************
package MyClass::Gree::MyStopWatch;

use strict;
use warnings;
no warnings 'redefine';
use 5.008005;
our $VERSION = '1.00';

use base qw(MyClass::Gree::MyPage);

use MyClass::WebUtil;
use MyClass::JKZDB::MyItem;
use MyClass::JKZDB::GsaUserStatus;
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
# @desc     SWの設定
#            tMyItemF/ tGsaUserStatusM のUPDATEを実行
#            必ずキャッシュを更新すること
# @param    miic  my_item_id:item_cateogym_id
# @return   
#******************************************************
sub set_my_stopwatch {
    my $self = shift;
    my ($my_item_id, $itemm_id) = split(/:/, $self->query->param('mii'));
    my $Encodeditem_name        = $self->query->param('Encodeditem_name');
    my $gree_user_id            = $self->opensocial_viewer_id;
    my $obj;

    #******************************
    # アイテムがSWであるかのチェック
    # 6000番台か11000番台
    #******************************
    unless (($itemm_id =~ /60\d\d/) || ($itemm_id =~ /110\d\d/)) {
         $obj->{IfInvalidItemError} = 1;
         $self->action('error');
         return $obj;
     }

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

    my $userStatus   = MyClass::JKZDB::GsaUserStatus->new($dbh);

    eval {

        # 設定するSWのstatus_flagは4にUPDATE
        # 対象のSW以外はstatus_flagを2にUPDATE
        $myItem->setMyStopWatch($my_item_id, $gree_user_id);

        $userStatus->executeUpdate({
            gree_user_id        => $gree_user_id,
            my_stopwatch_id     => $itemm_id,
            my_stopwatch_name   => $self->query->unescape($Encodeditem_name), 
        });

         $dbh->commit();
    };
     if ($@) {
         $dbh->rollback();
         $obj->{IfSetMyStopWatchError} =1;
    }
     else {
         MyClass::UsrWebDB::TransactFin($dbh, $attr_ref, $@);
         #**************************
         # 使用完了変数
         #**************************
         $obj->{IfSetMyStopWatchSuccess} = 1;

    }

    $obj->{used_item_name} = $self->query->unescape($Encodeditem_name);

#setMyStopWatch

    my $namespace  = sprintf("%s_userstatus", $self->waf_name_space());
    $self->memcached->delete("$namespace:$gree_user_id");
    my $namespace_sw = sprintf("%s_gsa_user_stopwatch", $self->waf_name_space());
    $self->memcached->delete("$namespace_sw:$gree_user_id");
    ## ここではgree_user_idの引数はあたえてはだめです。
    $self->gsaUserStatus();

    return $obj;
}


#******************************************************
# @desc     SWを外す
# @param    
# @param    
# @return   
#******************************************************
sub unset_my_stopwatch {
    my $self = shift;
    my ($my_item_id, $itemm_id) = split(/:/, $self->query->param('mii'));
    my $gree_user_id            = $self->opensocial_viewer_id;
    my $obj;
    #******************************
    # アイテムがSWであるかのチェック
    # 6000番台か11000番台
    #******************************
    unless (($itemm_id =~ /60\d\d/) || ($itemm_id =~ /110\d\d/)) {
         $obj->{IfInvalidItemError} = 1;
         $self->action('error');
         return $obj;
     }

    my $dbh        = $self->getDBConnection();
    $self->setDBCharset("sjis");
    my $attr_ref   = MyClass::UsrWebDB::TransactInit($dbh);
    my $myItem     = MyClass::JKZDB::MyItem->new($dbh);
    my $userStatus = MyClass::JKZDB::GsaUserStatus->new($dbh);

    eval {

        # MyItemのSWのstatus_flagは2にUPDATE
        $myItem->unsetMyStopWatch($my_item_id, $gree_user_id);
        # GsaUserStatusのSW関連部分の更新 値を空にする
        $userStatus->setDefaultStopWatch($gree_user_id);

         $dbh->commit();
    };
     if ($@) {
         $dbh->rollback();
         $obj->{IfUnSetMyStopWatchError} =1;
         $obj->{ERROR_MSG} = Dumper($@);
    }
     else {
         MyClass::UsrWebDB::TransactFin($dbh, $attr_ref, $@);
         #**************************
         # 使用完了変数
         #**************************
         $obj->{IfUnSetMyStopWatchSuccess} = 1;

    }

#setMyStopWatch

    my $namespace  = sprintf("%s_userstatus", $self->waf_name_space());
    $self->memcached->delete("$namespace:$gree_user_id");

    my $namespace_sw = sprintf("%s_gsa_user_stopwatch", $self->waf_name_space());
    $self->memcached->delete("$namespace_sw:$gree_user_id");
    ## ここではgree_user_idの引数はあたえてはだめです。
    #$self->gsaUserStatus();

    return $obj;
}



#******************************************************
# @desc     SWのボックス
# @param    キャッシュの使用を停止
# @param    
# @return   
#******************************************************
sub viewlist_my_stopwatch {
    my $self = shift;
    my $q               = $self->query();
    my $gree_user_id    = $self->opensocial_owner_id;
    my $a               = $q->param('a');
    my $o               = $q->param('o');
    my $offset          = $q->param('off') || 0;
    my $record_limit    = 10;
    my $condition_limit = $record_limit+1;

    my $obj;
    my $dbh    = $self->getDBConnection();
    $self->setDBCharset("sjis");

    ## 全アイテム取得
    my $Item = MyClass::JKZDB::MyItem->new($dbh);
    my $maxrec = $Item->getCountSQL(
        {
            columns     => 'my_item_id',
            whereSQL     => 'gree_user_id=? AND item_categorym_id IN(?, ?)',
            limitSQL    => "$offset, $condition_limit",
            orderbySQL  => 'itemm_id DESC',
            placeholder => [$gree_user_id, "6000", "11000"],
        }
    );

    my @navilink;
    ## レコード数が1ページ上限数より多い場合
    if ($maxrec > $record_limit) {
       my $url = sprintf("%sa=%s&o=%s", $self->MY_STOPWATCH_URL, $a, $o);

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
 my_item_id, status_flag, item_name, itemm_id, item_categorym_id
 FROM %s.tMyItemF WHERE gree_user_id=? AND item_categorym_id IN(?, ?)
 ORDER BY itemm_id DESC LIMIT %s, %s;", $self->waf_name_space, $offset, $condition_limit);

    my $aryref = $dbh->selectall_arrayref($sql, { Columns => {} }, $gree_user_id, "6000", "11000");

    $obj->{LoopMyStopWatchList} = ( $#{$aryref} >= $record_limit ) ? $#{ $aryref } -1 : $#{ $aryref };
    if (0 <= $obj->{LoopMyStopWatchList}) {
        $obj->{IfExistsMyStopWatchList} = 1;
        map {
            my $cnt = $_;
            foreach my $key (keys %{ $aryref }) {
                $obj->{$key}->[$cnt]                          = $aryref->[$cnt]->{$key};
                #$obj->{itemm_id}->[$cnt]                      = ($obj->{item_categorym_id}->[$cnt] + $obj->{item_id}->[$cnt]);
                $obj->{Encodeditem_name}->[$cnt]              = $q->escape($aryref->[$cnt]->{item_name});
                $obj->{LITEMIMAGE_SCRIPTDATABASE_URL}->[$cnt] = $self->ITEMIMAGE_SCRIPTDATABASE_URL();
                $obj->{LMY_STOPWATCH_URL}->[$cnt]             = $self->MY_STOPWATCH_URL();
                $obj->{IfStopWatchIsSet}->[$cnt]              = 1 if 4 == $obj->{status_flag}->[$cnt];
                $obj->{IfStopWatchIsNotSet}->[$cnt]           = 1 if 2 == $obj->{status_flag}->[$cnt];
            }

        } 0..$obj->{LoopMyStopWatchList};
    }
    else {
        $obj->{IfNotExistsMyStopWatchList} = 1;
    }

    return $obj;
}


1;
__END__