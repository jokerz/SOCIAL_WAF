#******************************************************
# @desc      Apache::SessionとMySQLでセッションを管理する
# @package   MyClass::Session
# @access    public
# @author    Iwahase Ryo
# @create    2006/05/15
# @version   1.00
#******************************************************

package MyClass::Session;

use strict;
use DBI;
use Apache::Session::MySQL;

$MyClass::Session::errstr = "";


#******************************************************
# @desc     コンストラクタ sessionを開始します
# @access   public
# @param    $dbhandle
#           $session_id
# @return        
#******************************************************
sub open {
    my ($type, $dbh, $sess_id) = @_;
    my %session;
    my %attr;

    #my $dsn = "DBI:mysql:host=localhost;database=devil;mysql_read_default_group=dbdmysql;mysql_read_default_file=/etc/my.cnf";
    my $dsn = "DBI:mysql:host=192.168.10.20;database=ApacheSession";
    my $user_name = "dbmaster";
    my $password = "h2g8p200";

    if (defined ($dbh))    {
        %attr = (
                Handle     => $dbh,
                LockHandle => $dbh
        );
    }
    else {
        %attr = (
                DataSource     => $dsn,
                UserName       => $user_name,
                Password       => $password,
                LockDataSource => $dsn,
                LockUserName   => $user_name,
                LockPassword   => $password
        );
    }
    eval {
        tie %session, "Apache::Session::MySQL", $sess_id, \%attr;
    };
    if ($@) {
        $MyClass::Session::errstr = $@;
        return undef;
    }

    return (bless (\%session, $type));
}


#******************************************************
# @desc        有効期限付きでsessionを開始します
# @access    public
# @param    $dbhandle
#            $session_id
# @return    
#******************************************************
sub open_with_expiration {
    my $self = &open (@_);

    if (defined($self) && defined ($self->expires()) && $self->expires () < $self->now()) {
        $MyClass::Session::errstr = sprintf ("Session %s has expired", $self->session_id());
        $self->delete();
        $self = undef;
    }

    return ($self);
}


#******************************************************
# @desc      アクセッサメソッド
#            引数が1つの場合はセッション項目を設定
#            引数が2つの場合はセッション項目に値を設定
# @access    public
# @param     $string_name
#            $string_value
# @return    
#******************************************************
sub attr {
    my $self = shift;

    return (undef) unless @_;
    $self->{$_[0]} = $_[1] if @_ > 1;

    return ($self->{$_[0]});
}


#******************************************************
# @desc        セッションIDを返す
# @access    public
# @param    
# @return    session_id
#******************************************************
sub session_id {
    my $self = shift;

    return ($self->{_session_id});
}


#******************************************************
# @desc        
# @access    private
# @param    
# @return    
#******************************************************
sub expires_1 {
    my $self = shift;

    return ($self->attr ("#<expires>#", @_));
}

use Time::Local;


#******************************************************
# @desc        有効期限を設定
# @access    public
# @param    
# @return    
#******************************************************
sub expires {
    my $self = shift;
    my $expires;

    $self->{"#<expires>#"} = [ gmtime ($_[0]) ] if @_;
    #$self->{"#<expires>#"} = [ $_[0] ] if @_;

    #$expires = $self->{"#<expires>#"};
    $expires = timegm (@{$expires}) if defined ($expires);

    return ($expires);
}


#******************************************************
# @desc        現在の時間
# @access    public
# @param    
# @return    time
#******************************************************
sub now { return (time()); }


#******************************************************
# @desc        セッションを閉じます/session_idを引数に
#            セッションをopenで再度セッションを復元
# @access    public
# @param    
# @return    
#******************************************************
sub close {
    my $self = shift;

    untie (%{$self});
}


#******************************************************
# @desc        セッションを削除
#            削除したセッションへは再アクセスできない
# @access    public
# @param    
# @return    time
#******************************************************
sub delete {
    my $self = shift;

    tied (%{$self})->delete();
}

1;