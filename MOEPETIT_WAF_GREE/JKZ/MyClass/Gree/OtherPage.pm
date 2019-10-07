#******************************************************
# @desc      OtherPageのクラス
# @desc      他のユーザーページ
#
# @package   MyClass::Gree::OtherPage
# @access    public
# @author    Iwahase Ryo
# @create    2011/04/11
# @update    
# @version    1.00
#******************************************************
package MyClass::Gree::OtherPage;

use strict;
use warnings;
no warnings 'redefine';
use 5.008005;
our $VERSION = '1.00';

use base qw(MyClass::Gree::MyPage);

use MyClass::WebUtil;
use MyClass::JKZSession;
use MyClass::JKZDB::GsaUserFlashGameLog;
use MyClass::JKZDB::Contents;
use MyClass::JKZDB::Item;
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
# @access    public
# @desc      公開情報設定
# @param    
# @return
#  %&other_my_power&%
#  %&other_my_stopwatch_id&%
#  %&other_my_latest_flashgame_record_time&%
#  %&other_my_getimage_total&%
#  %&other_my_completecharacter_total&%
#  %&other_my_tomemoeLv&%
#  %&other_my_compmoeLv&%
#  %&other_my_nickname&%
#  
#******************************************************
sub view_otherpage {
    my $self = shift;

    my $gree_user_id        = $self->opensocial_owner_id;
    my $gree_other_user_id  = $self->query->param('toid');

    # ユーザーが自分自身を訪問した場合の処理
    if ($gree_user_id == $gree_other_user_id) {
        $self->action('view_mypage');
        return $self->view_mypage;
    }

    my $obj;

    #*****************************
    # Check if you are ignored
    #*****************************
    if ($self->__checkIfIAmIgnored($gree_other_user_id)) {
        $obj->{IfUReIgnored} = 1;
        $self->action('error');
        return $obj;
    }


    #************************
    # ユーザーのパワーなどのステータスじょうほう
    #************************
	my $userstatusobj = $self->gsaUserStatus($gree_other_user_id);
	map { $obj->{$_} = $userstatusobj->{$_} } keys %{ $userstatusobj };

    return $obj;
}


#******************************************************
# @desc     コンテンツのリスト表示
# @param    
# @param    
# @return   
#******************************************************
sub viewlist_other_contents {
    my $self = shift;
    my $gree_other_user_id  = $self->query->param('toid');

    my $obj = $self->SUPER::viewlist_my_contents($gree_other_user_id);
    my $userstatusobj = $self->gsaUserStatus($gree_other_user_id);
    map { $obj->{$_} = $userstatusobj->{$_} } keys %{ $userstatusobj };

    return $obj;
}


#******************************************************
# @desc     check if you're ignored
# @param    
# @param    
# @return   boolean
#******************************************************
sub __checkIfIAmIgnored {
    my ($self, $toid) = @_;
    my $gree_user_id = $self->opensocial_owner_id;
    #my $api_endpoint = sprintf("%s/\@me/\@all/%s", $self->cfg->param('GREE_IGNORELIST_API_ENDPOINT'), $toid);
    #my $api_endpoint = sprintf("%s/\@me/\@all/%s", $self->cfg->param('GREE_IGNORELIST_API_ENDPOINT'), $gree_user_id);
    my $api_endpoint = sprintf("%s/%s/\@all/%s", $self->cfg->param('GREE_IGNORELIST_API_ENDPOINT'), $toid, $gree_user_id);

    my $consumer_key    = $self->cfg->param('CONSUMERKEY');
    my $consumer_secret = $self->cfg->param('CONSUMERSECRET');

    use JSON::XS;
    use OAuth::Lite::Consumer;

    my $consumer        = OAuth::Lite::Consumer->new(
                             consumer_key         => $consumer_key,
                             consumer_secret      => $consumer_secret,
                             realm                => '',
                         );

    my $res             = $consumer->request(
                            method => 'GET',
                            url    => $api_endpoint,
                            params => {
                                        xoauth_requestor_id  => $self->opensocial_viewer_id,
                                        opensocial_owner_id  => $self->opensocial_owner_id,
                                     },
                        );

    my $result            = JSON::XS::decode_json($res->decoded_content);
    if ($result->{Error}) {

        warn encode('utf-8', $result->{Error}{Message}), "\n";
    }
    else {

        no strict('refs');
        if (exists($result->{entry}{ignorelistId}) && $gree_user_id == $result->{entry}{ignorelistId}) {
        #if (exists($result->{entry}{ignorelistId}) && $toid == $result->{entry}{ignorelistId}) {
            return 1;
        }
        else {
            return;
        }
    }

}


1;
__END__