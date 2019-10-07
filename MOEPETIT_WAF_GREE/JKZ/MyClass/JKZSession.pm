#******************************************************
# @desc      
#            
# @package   MyClass::JKZSession
# @access    public
# @author    Iwahase Ryo AUTO CREATE BY ./createClassDB
# @create    Tue Feb  5 2009
# @version   1.0
# @update    2009/03/05 シリアライズ・デシリアライズ方法をバイナリ保存ではDBから取り出した時に復元できないため、
#                        pach,unpackする方法に変更（カラムをbinaryにしたらOKかも）
# @update    2009/03/17    method _initを_initializeに変更。他のクラスメソッド名と統一するため
# @update    2010/01/29  saveメソッドを追加。
#                        save_closeメソッドはsaveメソッドとcloseメソッド呼び出しに変更
#******************************************************
package MyClass::JKZSession;

use 5.008005;
use strict;
our $VERSION ='1.10';
use Storable qw(nfreeze thaw);
use MyClass::UsrWebDB;


#******************************************************
# @access    public
# @desc        コンストラクタ
# @param    sessionid, hash->flag, expire--hour
# @return    
#******************************************************
sub open {
    my $class = shift;
    my $session_id = shift;
    ## 新規データの場合は１以外はundef
    my $opt  = shift || undef;
    my $dbh  = MyClass::UsrWebDB::connect({ dbaccount => 'dbmaster', dbpasswd => 'h2g8p200', dbname => 'dMOEPETIT' });
    my $self = {
        dbh     => $dbh,
        table   => 'dMOEPETIT.tJKZSessionF',
        columns => {},
    };
    $self->{columns}->{id} = $session_id;
    
    bless($self, $class);

    return (!defined ($self->_initialize($opt)) ? undef : $self);
}


#******************************************************
# @access    private
# @desc        イニシャライザー
# @param    
# @return    
#******************************************************
sub _initialize {
    my ($self, $opt) = @_;

    my $placeholder = $self->{columns}->{id};

    my $sql = 
            exists($opt->{expire}) ?
            (sprintf "SELECT data, IF((NOW() <= DATE_ADD(timeref, INTERVAL %s second)), 1, 9) AS timeref FROM %s WHERE id=?;", $opt->{expire}, $self->{table}) :
            exists($opt->{flag})   ?
            (sprintf "INSERT INTO %s (id, timeref) VALUES (?, NOW()) ON DUPLICATE KEY UPDATE timeref=NOW();", $self->{table}) :
            (sprintf "SELECT data, timeref FROM %s WHERE id=?;", $self->{table})
            ;

    ## 新規
    if (exists($opt->{flag})) {
        $self->{dbh}->do($sql, undef, $placeholder) || die "$self->{dbh}->errstr\n";
    } else {
        unless (
            (
                $self->{columns}->{data},
                $self->{columns}->{timeref}
            ) = $self->{dbh}->selectrow_array( $sql, undef, $placeholder )
        ) {
            return undef;
        }
        $self->unserialize();
    }

    return $self;
}


sub session_id {
    my $self = shift;

    return $self->{columns}->{id};
}


sub session_is_valid {
    my $self = shift;

    return $self->{columns}->{timeref};
}

#******************************************************
# @desc        アクセッサ
# @param    
# @return    
#******************************************************
sub attrData {
    my $self = shift;
    ## 引数が無い場合はunserializeしたhashデータを返す
    return ($self->{data}) unless @_;

    $self->{data}->{$_[0]} = $_[1] if @_ > 1;

    return ($self->{data}->{$_[0]});
}


#******************************************************
# @desc        データをシリアライズする
# @param    
# @return    
#******************************************************
sub serialize {
    my $self = shift;

    $self->{serialized} = pack("u", nfreeze($self->attrData()));

    return $self->{serialized};
}


#******************************************************
# @desc        シリアライズされたデータをhashに戻す
# @param    
# @return    hash
#******************************************************
sub unserialize {
    my $self = shift;

    $self->{data} = thaw(unpack("u", $self->{columns}->{data}));

    return $self->{data};
}


#******************************************************
# @access    
# @desc        最終処理を実施
# @desc        データベース切断
# @param    
# @return    
#******************************************************
sub close {
    my $self = shift;

    $self->{dbh}->disconnect();
}


#******************************************************
# @access	
# @desc		シリアライズしたデータを更新
# @param	
# @param	
# @return	
#******************************************************
sub save {
    my $self = shift;
    my $sql   = sprintf "UPDATE %s SET data=? WHERE id=?;", $self->{table};
    my $store = $self->serialize();
    $self->{dbh}->do($sql, undef, $store, $self->session_id) if defined($store);
}

#******************************************************
# @access    
# @desc        最終処理を実施
# @desc        dataの更新とデータベース切断
# @param    
# @return    
#******************************************************
sub save_close {
    my $self  = shift;
#    my $sql   = sprintf "UPDATE %s SET data=? WHERE id=?;", $self->{table};
#    my $store = $self->serialize();
#    $self->{dbh}->do($sql, undef, $store, $self->session_id) if defined($store);
    $self->save();
    $self->close();
}


#******************************************************
# @access    
# @desc        現在のセッション情報の削除
# @param    
# @return    
#******************************************************
sub clear_session {
    my $self = shift;
    my $sql  = sprintf "DELETE FROM %s WHERE id=?;", $self->{table};
    my $rv   = $self->{dbh}->do($sql, undef, $self->session_id());
    ## dbハンドルをきちんと閉じる
    $self->close();

    return $rv;
}

1;

__END__
