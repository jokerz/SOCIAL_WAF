#******************************************************
# @desc      ライフサイクルイベント処理クラス アプリ登録
# @package   MyClass::GREE::AddApp
# @access    public
# @author    Iwahase Ryo
# @create    2011/02/04
# @update    2011/06/06 アプリ登録時にデフォルトでアイテムを付与する処理を追加
# @version    1.00
#******************************************************
package MyClass::Gree::AddApp;

use strict;
use warnings;
use 5.008005;
our $VERSION = '1.00';

use base qw(MyClass::Gree);

use MyClass::WebUtil;
use MyClass::JKZDB::GsaMember;
use MyClass::JKZDB::GsaUserRegistLog;
use MyClass::JKZDB::GsaUserStatus;
use MyClass::JKZDB::GsaUserPowerLog;

use NKF;

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
    my $q    = $self->query;

    my @id             = split(/,/, $q->param('id'));
    my $invite_from_id = $q->param('invite_from_id');
    my @user_hash      = split(/,/, $q->param('user_hash'));

    $self->__verify_oauth_signature();

    #*******************************************
    # アプリ登録時にデフォルトでアイテムを付与する処理を追加 2011/06/06
    #*******************************************
    my $item_cnt = 11;

    #******************************
    # item_type item_categorym_id itemm_id item_name
    #******************************
    my $item2001 = MyClass::WebUtil::convertByNKF('-s', 'よくみえぇる');
    my $item3001 = MyClass::WebUtil::convertByNKF('-s', 'ゆっくりみえぇる');
    my $item4001 = MyClass::WebUtil::convertByNKF('-s', 'いなずま');
    my $item5001 = MyClass::WebUtil::convertByNKF('-s', 'ｷﾞｶﾞいなずま');
    my $item8001 = MyClass::WebUtil::convertByNKF('-s', 'ぱわぁ1');
    my $item8002 = MyClass::WebUtil::convertByNKF('-s', 'ぱわぁ2');
    my $item8003 = MyClass::WebUtil::convertByNKF('-s', 'ぱわぁ5');

    #******************************
    # 付与するアイテム
    #******************************
    my $item = [
        [ 2, 2000, 2001, $item2001 ],
        [ 2, 3000, 3001, $item3001 ],
        [ 2, 4000, 4001, $item4001 ],
        [ 2, 4000, 4001, $item4001 ],
        [ 2, 4000, 4001, $item4001 ],
        [ 2, 4000, 4001, $item4001 ],
        [ 2, 4000, 4001, $item4001 ],
        [ 2, 5000, 5001, $item5001 ],
        [ 2, 8000, 8001, $item8001 ],
        [ 2, 8000, 8002, $item8002 ],
        [ 2, 8000, 8003, $item8003 ],
    ];

    my $insertsqlMoji = "INSERT INTO tMyItemF VALUES";

    $self->connectDB();

    my $dbh             = $self->getDBConnection();
    my $myMember        = MyClass::JKZDB::GsaMember->new($dbh);
    my $myUserRegistLog = MyClass::JKZDB::GsaUserRegistLog->new($dbh);
    my $myUserStatus    = MyClass::JKZDB::GsaUserStatus->new($dbh);
    my $myUserPowerLog  = MyClass::JKZDB::GsaUserPowerLog->new($dbh);

    my $attr_ref        = MyClass::UsrWebDB::TransactInit($dbh);

    my $idx = 0;

    ## 登録失敗等のフラグカウント
    my $FLAG = 0;
    my @failed_userid;

    foreach my $user_id (@id) {

        eval {

=pod Modified 2011/06/07 初期のstatusは1として、会員がアプリにアクセスしたときに２にする ActivityAPIをたたくため
             $myMember->executeUpdate(
               {
                 gree_user_id => $user_id,
                 status_flag  => 2,
                 user_hash    => $user_hash[$idx],
               }, -1
             );
=cut
             $myMember->executeUpdate(
               {
                 gree_user_id => $user_id,
                 status_flag  => 1,
                 user_hash    => $user_hash[$idx],
               }, -1
             );

             $myUserRegistLog->executeUpdate(
               {
                 id                  => -1,
                 gree_user_id        => $user_id,
                 status_flag         => 2,
                 date_of_transaction => MyClass::WebUtil::GetTime("10"),
               }
             );
        # 会員初期ステータス
            $myUserStatus->executeUpdate(
                {
                 gree_user_id        => $user_id,
                 my_power                 => "5",
                }
                , -1
            );

            $myUserPowerLog->executeUpdate(
                {
                 id                     => -1,
                 gree_user_id        => $user_id,
                 power                 => "5",
                 type_of_power         => 1,
                }
            );

            #***************************
            # デフォルトアイテム付与実行 BEGIN
            #***************************
            my @insert_values = ();
            my @my_item_id = map { MyClass::WebUtil::createHash(join('', $user_id, time, $$, rand(9999)), 32) } 1..$item_cnt;

            for (my $i = 0; $i < 11; $i++) {
                $insert_values[$i] = sprintf("('%s', %s, 2, %s, %s, %s, '%s', NOW())", $my_item_id[$i], $user_id, $item->[$i]->[0],  $item->[$i]->[1],  $item->[$i]->[2],  $item->[$i]->[3]);
            }

            my $sql = sprintf("%s %s;", $insertsqlMoji, join(',', @insert_values));
            $dbh->do("set names sjis");
            $dbh->do($sql);
            #***************************
            # デフォルトアイテム付与実行 END
            #***************************

            $idx++;
            $dbh->commit();
        };

        if ($@) {
            $dbh->rollback();
            push @failed_userid, $user_id;
            warn $@, "\n";
            $FLAG++
        }
    }

    
    if ($FLAG > 0) {
        warn '-' x 72, "\n", "Event AddApp Failure \n", '-' x 72, "\n", Dumper(@failed_userid);
    }
    else {
        print $self->query->header(-status => '200 OK');

        warn '-' x 72, "\n", "Event AddApp Success \n", '-' x 72, "\n", Dumper(@id);
   }

    MyClass::UsrWebDB::TransactFin($dbh, $attr_ref, $@);
    $self->disconnectDB();

}



1;
__END__