#******************************************************
# @desc      ライフサイクルイベント処理クラス アプリ削除
# @package   MyClass::GREE::RemoveApp
# @access    public
# @author    Iwahase Ryo
# @create    2011/02/04
# @update    
# @version    1.00
#******************************************************
package MyClass::Gree::SuspendApp;

use strict;
use warnings;
use 5.008005;
our $VERSION = '1.00';

use base qw(MyClass::Gree);

use MyClass::WebUtil;
use MyClass::JKZDB::GsaMember;
use MyClass::JKZDB::GsaUserRegistLog;

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

    $self->__verify_oauth_signature();

    $self->connectDB();

    my $dbh             = $self->getDBConnection();
    my $myMember        = MyClass::JKZDB::GsaMember->new($dbh);
    my $myUserRegistLog = MyClass::JKZDB::GsaUserRegistLog->new($dbh);
    my $attr_ref        = MyClass::UsrWebDB::TransactInit($dbh);

    eval {
        $myMember->removeGreeUser(\@id);
        $dbh->commit();
    };
    if ($@) {
        $dbh->rollback();
        warn '-' x 72, "\n", "Event RemoveApp Failuer Deleting From Member DataBase \n", '-' x 72, "\n", Dumper(@id);
    }

    foreach my $user_id (@id) {
        eval {
             ## 退会ログ
             $myUserRegistLog->executeUpdate(
               {
                 id                  => -1,
                 gree_user_id        => $user_id,
                 status_flag         => 4,
                 date_of_transaction => MyClass::WebUtil::GetTime("10"),
               }
             );

            $dbh->commit();
        };

        if ($@) {
            $dbh->rollback();
            warn '-' x 72, "\n", "Event RemoveApp Failure \n", '-' x 72, "\n", Dumper($user_id);
        }
    }

    print $self->query->header(-status => '200 OK');

    warn '-' x 72, "\n", "Event RemoveApp Success \n", '-' x 72, "\n", Dumper(@id);

    MyClass::UsrWebDB::TransactFin($dbh, $attr_ref, $@);
    $self->disconnectDB();
}


1;

__END__