#!/usr/bin/perl -w

#===============================================
# ���᡼���������
#===============================================
use strict;
#unshift(@INC,"/usr/local/src/kensyo-i/common/");
#require "err_mail.pl";

#===============================================
# �ѿ�
#===============================================
my ($buf, $mail_addr);
my ($result);

#===============================================
# �ᥤ�����
#===============================================

# �������ԥ᡼�륢�ɥ쥹���Ф�
$mail_addr = "";
my $mail_info = "";
my $search;
my $chkflag=0;

while(<>) {
	$buf = $_;

	# �᡼�륢�ɥ쥹���
	if( $buf =~ /^Final-Recipient: .+\;(.+)\n$/ ){
		$mail_addr = $1;
###		last;
	}
	# �᡼��������
	elsif( $buf =~ /^X-Kensyo_com: (.+)\n$/ ){
			$mail_info = $1;
	}
	elsif( $chkflag==1){
		#ezweb�ξ��
		if( $buf =~ /To: (.+)\n$/ ){
			$mail_addr = $1;
###			last;
		}
	}
	elsif( $buf =~ /^Each of the following recipients was rejected by a remote mail server/ ){
		$chkflag=1;
	}
}

if($mail_addr eq ""){
	exit;
}

$mail_addr =~ s/\s//g;
$mail_addr =~ s/\"//g; #"

  my $tmpfile = '/home/ryo/local/tmp_pool/test.log';
    open (FF,">>$tmpfile");
	#print FF $mail_from . $mail_date . $mail_subject . "\n";
	print FF $mail_addr . $mail_info . "\n";
	close (FF);

#$result = Err_Mail::ErrMail($mail_addr, $mail_info, 6);
exit;
