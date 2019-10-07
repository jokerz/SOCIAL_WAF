#******************************************************
# @desc    サイト基本設定「管理」
#          
# @package MyClass::JKZApp::AppGeneralENV
# @access  public
# @author  Iwahase Ryo
# @create  2009/08/27
# @version 1.00
#******************************************************
package MyClass::JKZApp::AppGeneralENV;

use 5.008005;
our $VERSION = '1.00';
use strict;

use base qw(MyClass::JKZApp);
use MyClass::WebUtil;
use Data::Dumper;


#******************************************************
# @access    public
# @desc        コンストラクタ
# @param    
# @return    
#******************************************************
sub new {
    my ($class, $cfg) = @_;

    return $class->SUPER::new ($cfg);
}


#******************************************************
# @access    public
# @desc        親クラスのgetActionをオーバーライド。ここはサブクラスごとに設定
# @param    
#******************************************************
sub getAction {
    my $self = shift;

    return ("" eq $self->action() ? 'siteSettingTopMenu' : $self->action());
}


#******************************************************
# @access   publich
# @desc     accessor
# @param    
# @param    
# @return   
#******************************************************
sub publishdir {
    my $self = shift;
    return ($self->{publishdir});
}


#******************************************************
# @desc        実行するメソッドのチェックと決定
# @param    
# @param    
# @return    methodname || undef
#******************************************************
sub methodnameByAttr {
    my $self = shift;
    my $priv_methodname = sprintf("_%s", $self->query->param('of'));
    
    return ($self->can($priv_methodname) ? $priv_methodname : undef);
}


#******************************************************
# @access    public
# @desc        親クラスのメソッド
# @param    
#******************************************************
sub dispatch {
    my $self = shift;

    my $publishdir = $self->PUBLISH_DIR() . '/admin/GeneralConfigration';
    if (! -d $publishdir) {
        MyClass::WebUtil::createDir($publishdir);
    }
    $self->{publishdir} = $publishdir;

    $self->query->autoEscape(0);
    $self->SUPER::dispatch();
}


#******************************************************
# @access    public
# @desc        この管理画面ﾄｯﾌﾟメニュー
#******************************************************
sub siteSettingTopMenu {
    my $self = shift;

    return;
}



#******************************************************
# @access    
# @desc        設定情報閲覧
# @param    
# @param    
# @return    
#******************************************************
sub viewConfigration {
    my $self = shift;

    my $obj = {};
    my $method = $self->methodnameByAttr();
    $obj = defined $method ? $self->$method() : "";

    my $IfStructure = sprintf("If%s%s", $self->_myMethodName(), $method);
    ## プライベートメソッド名のアンダースコアと次にくるアルファベット1文字を大文字変換
    $IfStructure =~ s!_([a-z])!\u$1!;
    $obj->{$IfStructure} = 1;

    return $obj;
}


#******************************************************
# @access    
# @desc        設定を行う
# @param    
# @param    
# @return    
#******************************************************
sub configureComponent {
    my $self   = shift;

    my $q      = $self->query();
    my $id     = $q->param('id') || undef;
    my $obj    = {};
    my $method = $self->methodnameByAttr();

    my $IfStructure = sprintf("If%s%s", $self->_myMethodName(), $method);
    ## プライベートメソッド名のアンダースコアと次にくるアルファベット1文字を大文字変換
    $IfStructure =~ s!_([a-z])!\u$1!;
    $obj->{$IfStructure} = 1;

    defined($q->param('md5key')) ? $obj->{IfConfirmConfiguration} = 1 : $obj->{IfEditConfiguration} = 1;

    $obj->{md5key} = MyClass::WebUtil::createHash($self->__session_id(), 20);

    if ($obj->{IfConfirmConfiguration}) {
         map { $obj->{$_} = MyClass::WebUtil::escapeTags( $q->param($_)) } keys %{$q->Vars};

        my $publish = sprintf("%s/%s", $self->publishdir(), $q->param('md5key'));
        MyClass::WebUtil::publishObj({file=>$publish, obj=>$obj});

        foreach my $key ( keys %{ $obj } ) {
            $obj->{$key} =~ s!\r\n!<br />!g;
        }
    }
    elsif ($obj->{IfEditConfiguration}) {
        my $tmpobj = defined $method ? $self->$method( { id =>$id } ) : "";
        map { $obj->{$_} = $tmpobj->{$_} } keys %{ $tmpobj };
    }

    return $obj;
}


#******************************************************
# @desc     設定情報更新
# @param    
# @param    
# @return   
#******************************************************
sub modifyConfiguration {
    my $self   = shift;
    my $method = $self->methodnameByAttr();
    my $md5key = $self->query->param('md5key');

    defined $method ? $self->$method({ md5key => $md5key, modify => 1 }) : "";
    $self->action('viewConfigration');
    $self->query->param(-name=>'of', -value=>$self->query->param('of'));

    return $self->viewConfigration();
}


sub _envconf {
    my $self = shift;
    my $obj;

    my %CONFIGRATIONKEY = $self->cfg->vars();

    require Tie::IxHash;
    tie %{$obj}, 'Tie::IxHash';

    map {
#        push @{ $obj->{envconfvalues} }, 
#        {
#            envconf_key   => $_,
#            envconf_value => $CONFIGRATIONKEY{$_},
#        }
        push @{ $obj->{envconf_key} }, $_;
        #push @{ $obj->{envconf_value} }, (MyClass::WebUtil::convertByNKF('-s', $CONFIGRATIONKEY{$_}));
        push @{ $obj->{envconf_value} }, $CONFIGRATIONKEY{$_};
    } keys %CONFIGRATIONKEY;
    $obj->{LoopEnvconfList} = scalar @{ $obj->{envconf_key} };



    $obj->{IfviewConfigurationEnvconf} = 1;

    return $obj;
}


#******************************************************
# @access    private
# @desc        サーバーのバージョン情報等CGI Apache Perl ModPerl MySQL
# @param    
# @param    
# @return    
#******************************************************
sub _server {
    #my $self = shift;

    my $obj = {};
    map { $obj->{$_} = $ENV{$_} } keys %ENV;
    $obj->{PERL_VERSION}  = $];
    $obj->{MYSQL_VERSION} = `/usr/local/mysql/bin/mysql -V`;
    $obj->{MYSQL_VERSION} = `/usr/bin/mysql -V` if !$obj->{MYSQL_VERSION};

    return $obj;
}


1;

__END__
