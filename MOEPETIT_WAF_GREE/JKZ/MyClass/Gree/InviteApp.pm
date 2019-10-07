#******************************************************
# @desc      ライフサイクルイベント処理クラス 友達紹介
# @package   MyClass::GREE::InviteApp
# @access    public
# @author    Iwahase Ryo
# @create    2011/05/19
# @update    
# @version    1.00
#******************************************************
package MyClass::Gree::InviteApp;

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

    print $self->query->header(-status => '200 OK');

}


1;

__END__