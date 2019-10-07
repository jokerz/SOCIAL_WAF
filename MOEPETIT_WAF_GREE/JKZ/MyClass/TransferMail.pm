#********************************************
# @desc        
# @package    MyClass::TransferMail
# @access    public
#
=pod
$settings = {
    servers => [],
    froms     => [],
    rcp_tos => [],
    subject    => undef,
    header_ext    => undef,
    contents_header    => undef,
    contents_body    => undef,
    contents_footer    => undef,

    ## using smtp connections you can set multiple servers
    my $myMail = JKZ::winTransferMail->new (\%smtpsetting);
    $myMail->setMailContents (\%smtpcontents);
    $myMail->setMailAddress (\@to);
    $myMail->SMTPSend ();

    ## using sendmail command
    my $myMail = JKZ::TransferMail->new ();
    $myMail->setMailContents ($retmailref);
    $myMail->setMailAddress ($vars->{email});
    $myMail->SendMailSend ();
=cut
#
# @author    Iwahase Ryo
# @create    2006/11/10
# @version    1.00
# @update   2008/01/27
#            Modify the method initMailHeader ##232##
#            for missprograming mail subject
# @update    2009/09/16    use WebUtilの排除
# @update    2009/09/16    SMTPSendメソッド一部修正
# @update    2009/09/16    SendMailSendメソッド一部修正
#
#********************************************
package MyClass::TransferMail;

use strict;
use 5.008000;
our $VERSION = '1.00';

use Encode;
use NKF;
use Net::SMTP;
use Data::Dumper;
use MIME::Base64;
#use WebUtil;
use MyClass::ConvertStr;
use Data::Dumper;

#******************************************************
# @access    public
#            my $myMail = JKZ::TransfreMail->new ();
# @desc        コンストラクタ
# @param    
#            %smtpsetting = (
#                servers => ['smtp1.server.co.jp:587', 'smtp2.server.co.jp:587', 'smtp3.server.co.jp:587',],
#                froms    => ['mailmaster@yyyyyxxmm.jp',],
#            );
# @return    
# @author    
#******************************************************
sub new {
    my $class = shift;
    my $self = {};

    $self = {
        servers          => [],
        froms            => [],
        header_base      => [],
        rcp_tos          => [],
        mailsetting      => [],
        sendmail         => undef,
        subject          => undef,
        from             => undef,
        header_ext       => undef,
        contents_header  => undef,
        contents_body    => undef,
        contents_footer  => undef,
    };

    ### smtpでsmtpサーバーと送り主データがある時
    if (@_) {
        my $tmpval = shift;
        @{ $self->{servers} } = @{ $tmpval->{servers} };
        @{ $self->{froms} }   = @{ $tmpval->{froms} };
    }

    warn Dumper($self);

    return (bless ($self, $class));
}


#******************************************************
# @access    
# @desc        
# @param    
# @param    
# @return    
#******************************************************
sub setMailContents {
    my $self = shift;
    if (@_) {
        my $contents = shift;
        map { $self->{$_} = $contents->{$_} } keys %$contents;
    }

    warn Dumper($self);

    return $self;
}


#******************************************************
# @access    
# @desc        
# @param    
# @param    
# @return    
#******************************************************
sub setMailAddress {
    my $self = shift;
    if (@_) {
        my $rcp_tos = shift;
        1 < $rcp_tos ? @{ $self->{rcp_tos} } = @{$rcp_tos} : ${ $self->{rcp_tos} }[0] = $rcp_tos;
    }

    warn Dumper($self->{rcp_tos});

    return $self;
}


#********************************************
# @desc        smtpメール配信
# @param    
# @access    public
#********************************************
sub SMTPSend {
    my $self = shift;
    # smtpサーバーセット
    #$self->initSMTP ();

    my $i = 0;
    my @mailsetting;

    foreach (@{$self->{servers}}) {
        my $sp;
        unless ( $sp = Net::SMTP->new($_, Debug => 1)) {
            print "can't open server $_ \n";
            next;
        }
        push @mailsetting, {
                        'smtp'       => $sp,
                        'from'       => $self->{froms}->[$i],
                        'server'     => $self->{servers}->[$i],
                        'headerbase' => $self->{headerbases}->[$i]
                        };
        $i++;
    }

    undef $i;

    print Dumper(\@mailsetting);

    #仮に、1つ目の接続を利用して、メール送信してみる
    my $sv; #@mailsettingの添え字
    my $sendcnt = 0; #総送信数

    foreach my $rcpt_to (@{$self->{rcp_tos}}) {
        #単純にラウンドロビン実現するための処理
        $sendcnt++;
        #総送信数をサーバーの数で割って、そのあまりを添え字に使う
        $sv = $sendcnt % ($#mailsetting + 1);

        $mailsetting[$sv]{'smtp'}->mail($self->{from});
        $mailsetting[$sv]{'smtp'}->to($rcpt_to);
        $mailsetting[$sv]{'smtp'}->data();

    ## Modified WebUtilにてgetCarrierByEMailは排除されたため 2009/09/16 BEGIN
        #my $carrier = WebUtil::getCarrierByEMail($rcpt_to);
        my $carrier = sub {
                            ( $rcpt_to =~ /\@docomo\.ne\.jp$/ )                 ? "1" :
                            ( $rcpt_to =~ /\@.\.[vodafone|softbank]\.ne\.jp$/ ) ? "2" :
                            ( $rcpt_to =~ /\@ezweb\.ne\.jp$/ )                  ? "3" :
                                                                                  "9" ;
                    };
    ## Modified 2009/09/16 END

        #メールヘッダー、内容のエンコードをそれぞれ整える。
        #携帯電話へのメールはバイナリ絵文字整える
        my $send_header = $self->initMailHeader($rcpt_to, $carrier);
        my $send_body   = $self->initMailBody($carrier);

        $mailsetting[$sv]{'smtp'}->datasend($send_header);
        $mailsetting[$sv]{'smtp'}->datasend("\n\n");
        $mailsetting[$sv]{'smtp'}->datasend($send_body);
        $mailsetting[$sv]{'smtp'}->dataend();
    }

    foreach (@{$self->{mailsetting}}) {
        $_->{'smtp'}->quit();
    }

    #配信が終了したら各stmp接続を終了させる
    #$self->finishSMTP ();

    return (1);
}


#********************************************
# @desc        sendmail等を使用してのメール配信
# @param    
# @access    public
#********************************************
sub SendMailSend {
    my $self = shift;

    foreach my $rcpt_to (@{$self->{rcp_tos}}) {

    ## Modified WebUtilにてgetCarrierByEMailは排除されたため 2009/09/16 BEGIN
        #my $carrier = WebUtil::getCarrierByEMail($rcpt_to);
        my $carrier = sub {
                            ( $rcpt_to =~ /\@docomo\.ne\.jp$/ )                 ? "1" :
                            ( $rcpt_to =~ /\@.\.[vodafone|softbank]\.ne\.jp$/ ) ? "2" :
                            ( $rcpt_to =~ /\@ezweb\.ne\.jp$/ )                  ? "3" :
                                                                                  "9" ;
                    };
    ## Modified 2009/09/16 END

        #メールヘッダー、内容のエンコードをそれぞれ整える。
        #携帯電話へのメールはバイナリ絵文字整える
        my $send_header = $self->initMailHeader($rcpt_to, $carrier);
        my $send_body   = $self->initMailBody($carrier);

         open(OUT,"| $self->{sendmail} -t") or die ( return (0) ); #'ERROR' . "\n";

        print OUT $send_header;
        print OUT "\n";
        print OUT $send_body;
        print OUT "\n";
        close(OUT);

        sleep 1;
    }

    return (1);
}


#********************************************
# @desc        メールヘッダーを作る
# @param    
# @access    private
#********************************************
sub initMailHeader {
    my $self = shift;
    my ($to, $crr) = @_;
    my $header;
    #my($subject, $from, $to, $crr, $extra) = @_;
    
    #if ($CARRIER{'docomo'} == $crr) {
    if (1 == $crr) {
        #絵文字をバイナリに変換
        my $subject = MyClass::ConvertStr::ConvDocomoIcon($self->{subject});
        $header = "Subject: $subject\n";
        $header .= "From: $self->{from}\n";
        $header .= "To: $to\n";
        $header .= "Content-Type: text/plain;charset=Shift-JIS\n";
        $header .= "Content-Transfer-Encoding: base64\n";
        $header .= $self->{header_ext} ."\n" if (defined $self->{header_ext});
    }
    #elsif ($CARRIER{'ezweb'} == $crr) {
    elsif (3 == $crr) {
        my $subject = MyClass::ConvertStr::ConvEzwebIcon($self->{subject});
        $header = "Subject: $subject\n";
        $header .= "From: $self->{from}\n";
        $header .= "To: $to\n";
        $header .= "Content-Type: text/plain;charset=Shift-JIS\n";
        $header .= "Content-Transfer-Encoding: base64\n";
        $header .= $self->{header_ext} . "\n" if (defined $self->{header_ext});
    } else {
        #それ以外はISO-2022-JPに変換
        no strict('refs');

        #********************************************
        # nkfがない場合
        #********************************************
=pod
        require 'jcode.pl';
        my $subject = &jcode'convert (\$self->{subject}, 'jis');
        require Jcode;
        my $subject = Jcode->new($self->{subject})->mime_encode;
        $header = "Subject: $self->{subject}\n";
=cut
        my $subject = nkf('-j' , $self->{subject});
        $header = "Subject: $subject\n";
        $header .= "From: $self->{from}\n";
        $header .= "To: $to\n";
        $header .= "Content-Type: text/plain;charset=ISO-2022-JP\n";
        if (9 == $crr) {
            $header .= "MIME-Version: 1.0\n";
            $header .= "Content-Transfer-Encoding: 7bit\n";
        }
        $header .= $self->{header_ext} ."\n" if (defined $self->{header_ext});
    }

    return $header;
}1;


#********************************************
# @desc        メール文面を作成・絵文字処理等
# @param    
# @access    private
#********************************************
sub initMailBody {
    my $self = shift;
    my $crr = shift;
    my $body;

    if (1 == $crr || 3 == $crr) {
        #BASE64
        $body = MIME::Base64::encode($self->{contents_header});
        $body .= MIME::Base64::encode($self->{contents_body});
        $body .= MIME::Base64::encode($self->{contents_footer});
    } else {
        #それ以外はそのまま
        no strict ('refs');
        $body = nkf('-j', $self->{contents_header});
        $body .= nkf('-j', $self->{contents_body});
        $body .= nkf('-j', $self->{contents_footer});

        #********************************************
        # nkfがない場合
        #********************************************
=pod
        require 'jcode.pl';
        $body = &jcode'convert (\$self->{contents_header}, 'jis');
        $body .= &jcode'convert (\$self->{contents_body}, 'jis');
        $body .= &jcode'convert (\$self->{contents_footer}, 'jis');

        $body = Jcode::convert (\$self->{contents_header}, 'jis');
        $body .= Jcode::convert (\$self->{contents_body}, 'jis');        
        $body .= Jcode::convert (\$self->{contents_footer}, 'jis');
=cut
    }
    return $body;
}1;


#********************************************
# @desc        serversの数だけSMTP接続を試みる
# @param    
# @access    private
# @return    送信用のサーバーの設定
#********************************************
sub initSMTP {
    my $self = shift;
    my $i = 0;

    foreach (@{$self->{servers}}) {
        my $sp;
        unless ( $sp = Net::SMTP->new($_, Debug => 1) ) {
            print "can't open server $_ \n";
            next;
        }
        push @{ $self->{mailsetting} }, {
                        'smtp'       => $sp,
                        'from'       => $self->{froms}->[$i],
                        'server'     => $self->{servers}->[$i],
                        'headerbase' => $self->{headerbases}->[$i]
                        };
        $i++;
    }

    undef $i;

    print Dumper($self->{mailsetting});
}


#********************************************
# @desc        SMTP接続を終了させる
# @param    
# @access    private
#********************************************
sub finishSMTP {
    my $self = shift;

    foreach (@{$self->{mailsetting}}) {
        $_->{'smtp'}->quit();
    }
}

1;
