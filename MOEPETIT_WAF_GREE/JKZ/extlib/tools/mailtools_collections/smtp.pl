#!/usr/bin/perl
#京
#use encoding 'cp932';
#binmode STDERR , ':encoding(cp932)';
use Encode;
use strict;
use Net::SMTP;
use Data::Dumper;
use MIME::Base64;

my %header = ('docomo' => 'Content-Type: text/plain;charset=Shift-JIS'."\r\n".
'Content-Transfer-Encoding: base64',
			  'voda' => 'Content-Type: text/plain;charset=ISO-2022-JP'. "\r\n",
			  'ezweb' => 'Content-Type: text/plain;charset=Shift-JIS'."\r\n".
'Content-Transfer-Encoding: base64');

#my $from = 'imaoka@ans-web.co.jp'; #エンベロープ
my $from = 'mailmaster@jokerz.org'; #エンベロープ
#my @to = ('ai-toshihisa@docomo.ne.jp', 'j-ans@t.vodafone.ne.jp',
#		  'ans-earth@ezweb.ne.jp');
my @to = ('hemoglobin0905@docomo.ne.jp', 'system@jokerz.org', 'ryo@up-stair.jp');
#my @to = ('waki-aiai-info@ezweb.ne.jp', 'waki-info@docomo.ne.jp', 'hemoglobin4649@docomo.ne.jp','adfadfadfadfadfadfadfuriuerua8d8f98asdfa@ezweb.ne.jp','fadfakdjfkadjfadsfiaudfi@docomo.ne.jp');
my %body = ('docomo' => '絵文噬eストでｌb縦ｓ倩ｌi欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清ﾅ半角カタカナ保狂鏡凝保狂鏡凝保狂鏡凝保狂鏡凝保狂鏡凝保狂鏡凝保狂鏡凝保狂鏡凝保狂鏡凝保狂鏡凝保狂鏡凝保狂鏡凝保狂鏡凝保狂鏡凝保狂鏡凝保狂鏡凝保狂鏡凝保狂鏡凝保狂鏡凝保狂鏡凝保狂鏡凝保狂鏡凝保狂鏡凝保狂鏡凝保狂鏡凝保狂鏡凝"',
			 'voda' => '★とりあえず■SJISのまま〒だけれどもSJISでは送信できないのでISO-2022-JPに変換する必要がある',
			 'ezweb' => '絵文噬eストでｌb縦ｓ倩ｌi欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清妬欟原清ﾅ半角カタカナ保狂鏡凝保狂鏡凝保狂鏡凝保狂鏡凝保狂鏡凝保狂鏡凝保狂鏡凝保狂鏡凝保狂鏡凝保狂鏡凝保狂鏡凝保狂鏡凝保狂鏡凝保狂鏡凝保狂鏡凝保狂鏡凝保狂鏡凝保狂鏡凝保狂鏡凝保狂鏡凝保狂鏡凝保狂鏡凝保狂鏡凝保狂鏡凝保狂鏡凝保狂鏡凝"');

my @mailsetting;
#my @servers = ('mail.ans-web.co.jp', '192.168.1.9',
#			   'shipbuilding.tv');
#my @servers = ('192.168.6.121', '192.168.6.122',
#			   '192.168.6.123');
my @servers = ('localhost');#, '192.168.1.200',
#			   'smtp.jokerz.org');
my @froms = ('mailmaster@jokerz.org');#, 'ryo@192.168.1.200',
#			   'reg-goku@jokerz.org');
my @headerbases = ('', '', '');

my $subject = '保狂入っｒﾍｽ';
#@serversの数だけSMTP接続を獅ﾝる
my $i = 0;
foreach (@servers)
{
	my $sp;
	unless( $sp = Net::SMTP->new($_, Debug => 1) ){
		print "can't open server$_\n";
		next;
	}
	push @mailsetting, {'smtp' => $sp,
						'from' => $froms[$i],
						'server' => $servers[$i],
		                'headerbase' => $headerbases[$i]};
	$i++;
}
undef $i;

print Dumper(\@mailsetting);
#exit;

#仮に、1つ目の接続を利用して、メール送信してみる
my $sv; #@mailsettingの添え��
my $sendcnt = 0; #総送信数
foreach my $rcpt_to (@to) 
{
	#単純にラウンドロビンﾀ現するための処理
	$sendcnt++;
	#総送信数をサーバーの数で割って、そのあまりを添え嘯ﾉgう
	$sv = $sendcnt % ($#mailsetting + 1);
	
	$mailsetting[$sv]{'smtp'}->mail($from);
	$mailsetting[$sv]{'smtp'}->to($rcpt_to);
	
	$mailsetting[$sv]{'smtp'}->data();

	my($send_header, $send_body);
	$send_header = "Subject: ";
	$send_header .= MIME::Base64::encode($subject);
	$send_header .= "From: $from\r\n";
	$send_header .= "To: $rcpt_to\r\n";
	if( $rcpt_to =~ /@.\.vodafone\.ne\.jp$/ ){
		$send_header .= $header{'voda'};
		Encode::from_to($send_header, 'cp932', 'iso-2022-jp');
		$send_body = $body{'voda'};
		Encode::from_to($send_body, 'cp932', 'iso-2022-jp');
	}else{
		$send_header .= $header{'docomo'};
		$send_body = MIME::Base64::encode($body{'docomo'});
	}



	$mailsetting[$sv]{'smtp'}->datasend($send_header);
	$mailsetting[$sv]{'smtp'}->datasend("\n");
	$mailsetting[$sv]{'smtp'}->datasend($send_body);
	$mailsetting[$sv]{'smtp'}->dataend();
}


foreach (@mailsetting)
{
	$_->{'smtp'}->quit();
}

