#******************************************************
# @desc      ライフサイクルイベント処理クラス アプリ登録
# @package   MyClass::GREE::ResumeApp
# @access    public
# @author    Iwahase Ryo
# @create    2011/02/04
# @update    
# @version    1.00
#******************************************************
package MyClass::Gree::ResumeApp;

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

             $myMember->executeUpdate(
               {
                 gree_user_id => $user_id,
                 status_flag  => 2,
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