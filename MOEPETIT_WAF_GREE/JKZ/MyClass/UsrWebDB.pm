#******************************************************
# * @package MyClass::UsrWebDB
# * @access  public
# * @author  RyoIwahase
# * @create  2004/12/28
# * @version 1.00
# * @update 2008/07/10 MemcacheInitを追加
# * @update 2009/12/22 不要・開発時のコード・コメント削除
#******************************************************

package MyClass::UsrWebDB;

use strict;
use DBI;

our $VERSION = '1.0';

#******************************************************
# @access    public
# @desc        Connect to Database
# @param    
# @return   
# @author   
#******************************************************
sub connect {
    my $dbinfo = shift;
    ## default info
    $dbinfo = {
        dbaccount => "dbmaster",
        dbpasswd  => "h2g8p200",
        dbname    => "dMOEPETIT",
    } if !exists ($dbinfo->{dbaccount});

    #my $host_name = "localhost";
    #my $host_name = "127.0.0.1";
    my $host_name = "192.168.1.101";

    my $dsn = "DBI:mysql:host=$host_name;database=" . $dbinfo->{dbname};
    $dsn    .= ";mysql_read_default_group=dbdmysql;mysql_read_default_file=" . $dbinfo->{mycnf} if exists ($dbinfo->{mycnf});

    return (
            DBI->connect($dsn, $dbinfo->{dbaccount}, $dbinfo->{dbpasswd},
                            #{PrintError => 0, RaiseError=> 1}
                            {PrintError => 1, RaiseError=> 0}
                        )
            );
}


#******************************************************
# @access    public
# @desc        Transactionの開始
# @param    
# @return        
#******************************************************
sub TransactInit {
    my $dbh = shift;
    my $attr_ref = {};
    $attr_ref->{RaiseError} = $dbh->{RaiseError};
    $attr_ref->{PrintError} = $dbh->{PrintError};
    $attr_ref->{AutoCommit} = $dbh->{AutoCommit};
    $dbh->{RaiseError} = 1;
    $dbh->{PrintError} = 0;
    $dbh->{AutoCommit} = 0;

    return ($attr_ref);
}


#******************************************************
# @access    public
# @desc        Transactionの終了
# @param    
# @return        
#******************************************************
sub TransactFin {
    my ($dbh,$attr_ref,$error) = @_;

    #プログラム側で$dbh->rollback () を実行してもUsrWebDB::TransactFin ($DBH,$attr_ref, $@);として
    #このファンクションでrollbackでもOK
    if ($error) {
        ## 開発時にエラー内容の出力するときはコメントを外す
        #print "トランザクションROLLBACK \nエラー：\n $error \n";
        #warn "トランザクションROLLBACK \nエラー：\n $error \n";
        eval { $dbh->rollback(); };
    }

    #####@もとの状態に戻す
    $dbh->{AutoCommit} = $attr_ref->{AutoCommit};
    $dbh->{PrintError} = $attr_ref->{PrintError};
    $dbh->{RaiseError} = $attr_ref->{RaiseError};
}


#******************************************************
# @access    public
# @desc        Cache::Memcached::Fastを処理を行う
# @param    
# @return    undef if no Cache::Memcached::Fast is installed
#******************************************************
sub MemcacheInit {
    my $serverinfo;
    $serverinfo = @_ ? shift
                :
                {
                    #'servers'            => ["192.168.1.200:11211"],
                    #servers            => ["127.0.0.1:11211"],
                    servers            => ["192.168.1.201:11211"],
                    namespace          => 'MOEPETIT:',
                    compress_threshold => 10_000,
                    compress_ratio     => 0.9,
                }
                ;
    ## Cache::Memcached::Fastがない場合はundefを返す
    eval("require Cache::Memcached::Fast;"); return undef if $@;
    return (
        Cache::Memcached::Fast->new($serverinfo)
            );
}


sub runSQL {
    my ($sqlMoji) = @_;

    require MyClass::WebUtil;
    my $now = MyClass::WebUtil::GetTime("10");

    warn "\n\n-------------------------------\n No SQL has benn Executed \n-------------------------------\n\n" unless defined ($sqlMoji);
    warn "\n\n-------------------------------\n" . $now . " [SQL EXECUTED:] $sqlMoji \n-------------------------------\n\n";
}


#******************************************************
# @access    public
# @desc        ＳＱＬとホルダーの値の確認をしたいとき
# @param    $sql \@placeholder
# @return        
#******************************************************
sub checkSQLValues {
    my ($sqlMoji, $placeholder) = @_;
    require Data::Dumper;
    require MyClass::WebUtil;
    my $now = MyClass::WebUtil::GetTime ("10");

    warn "\n\n-------------------------------\n No SQL is EMPTY \n-------------------------------\n\n" unless defined ($sqlMoji);
    warn "\n\n-------------------------------\n" . '[' . $now . ' SQL:] ' . $sqlMoji . "\n-------------------------------\n\n";
    warn "\n\n-------------------------------\n" . '[' . $now . ' PLACEHODER:] ';
    #warn Dumper ($placeholder), "\n-------------------------------\n\n";
}
1;
__END__
