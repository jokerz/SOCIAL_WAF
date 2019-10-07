#!/usr/bin/perl
#��
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

#my $from = 'imaoka@ans-web.co.jp'; #����٥���
my $from = 'mailmaster@jokerz.org'; #����٥���
#my @to = ('ai-toshihisa@docomo.ne.jp', 'j-ans@t.vodafone.ne.jp',
#		  'ans-earth@ezweb.ne.jp');
my @to = ('hemoglobin0905@docomo.ne.jp', 'system@jokerz.org', 'ryo@up-stair.jp');
#my @to = ('waki-aiai-info@ezweb.ne.jp', 'waki-info@docomo.ne.jp', 'hemoglobin4649@docomo.ne.jp','adfadfadfadfadfadfadfuriuerua8d8f98asdfa@ezweb.ne.jp','fadfakdjfkadjfadsfiaudfi@docomo.ne.jp');
my %body = ('docomo' => '��ʸ��e���Ȥǣ�b�ģ����iݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������Ⱦ�ѥ��������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ�����"',
			 'voda' => '���Ȥꤢ������SJIS�Τޤޢ�������ɤ�SJIS�Ǥ������Ǥ��ʤ��Τ�ISO-2022-JP���Ѵ�����ɬ�פ�����',
			 'ezweb' => '��ʸ��e���Ȥǣ�b�ģ����iݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������Ⱦ�ѥ��������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ������ݶ�����"');

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

my $subject = '�ݶ����ã�͎�';
#@servers�ο�����SMTP��³���ݤ�
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

#���ˡ�1���ܤ���³�����Ѥ��ơ��᡼���������Ƥߤ�
my $sv; #@mailsetting��ź����
my $sendcnt = 0; #��������
foreach my $rcpt_to (@to) 
{
	#ñ��˥饦��ɥ�ӥ�������뤿��ν���
	$sendcnt++;
	#���������򥵡��С��ο��ǳ�äơ����Τ��ޤ��ź�����g��
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

