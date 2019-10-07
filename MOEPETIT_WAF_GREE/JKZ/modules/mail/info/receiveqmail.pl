#!/usr/bin/perl

#******************************************************
# @desc		�󃁁[���o�^���� �ύX�o�^�p�i�V�K�o�^�p�v���O�������Ɠ���)
# @package	receiveqmail
# @author	Iwahase Ryo
# @create	2009/09/17
# @update   2010/08/02 �T�C�g�̃h���C����ύX��������
# @version	
#******************************************************


use strict;
use vars qw($include_path);

BEGIN {
	## �N���X�̃C���N���[�h�p�X���擾���邽�߂̏���
	require Cwd;
	my $pwd = Cwd::getcwd();
	($include_path = $pwd) =~ s!/modules/.+!!;

	unshift @INC, $include_path;
}

use MIME::Parser;
use MIME::WordDecoder;
use Jcode;

use MyClass::WebUtil;
use MyClass::UsrWebDB;
use MyClass::TransferMail;

## �������O�o�̓f�B���N�g���c�ΏۃA�J�E���g�ɂ��ύX���邱��
my $outputdir= '/home/vhosts/DENISMCD/JKZ/modules/mail/info/';

#******************************************************
#	���[���̓��e
#******************************************************
my $mail_from;
my $mail_date;
my $mail_subject;
my $mail_body;


sub dump_entity {
    my ($entity) = @_;

  # HEAD
    $mail_from .= $entity->head->get('from');
    chomp($mail_from);
    $mail_date .= $entity->head->get('date');
    $mail_subject .= unmime($entity->head->get('subject'));
	chomp($mail_subject);

  # BODY
    my @parts = $entity->parts;
    if (@parts) {
    	my $i;
        foreach $i (0 .. $#parts) {
            dump_entity($parts[$i]);
        }
    }
 
    	# Modified �����ǉ� 2010/03/23 BEGIN
#=pod
   	# MimeType�̎擾�Ə��� 
    my ($type, $subtype) = split ('/', $entity->head->mime_type);
    my $body = $entity->bodyhandle;
    ### text
    if ($type =~ /^(text|message)$/) {
            $mail_body .= $body->as_string;
    }
#=cut
    # Modified �����ǉ� 2010/03/23 END
 
 
    1;
}
#------------------------------
#
# main
#

sub main {
    my $buf;
    {
        local $/;
        $buf= <>;
    }

	#******************************************************
	#	���[���̌����̕����R�[�h�̏���
	#******************************************************
	#'*'   => sub { jcode(shift)->utf8 }, #�{����ISO-2022-JP�̂�
	MIME::WordDecoder->default(
	    MIME::WordDecoder->new( [
	        '*'   => sub { jcode(shift)->sjis }, #�{����ISO-2022-JP�̂�
	        ]
	    )
	);

    my $parser = new MIME::Parser;
    $parser->output_to_core(1);
    $parser->tmp_recycling(1);
    $parser->tmp_to_core(1);
    $parser->use_inner_files(1);

    my $entity = $parser->parse_data($buf) or die;

    dump_entity($entity);

    #####@�g�p�e�[�u����hash
    my %TABLE = (
    				'mailsetting'	=> 'DENISMCD.tMailSettingM',
    				'member'		=> 'DENISMCD.tMemberM',
    				'maillog'		=> 'DENISMCD.tMailAddressLogF',
    			);

	#my ($guid) = MyClass::WebUtil::decryptBlowFish($mail_subject);
    # Modified �{���Ή� �����ǉ� 2010/03/07
    my ($guid) = MyClass::WebUtil::decryptBlowFish($mail_body);

	my $dbh    = MyClass::UsrWebDB::connect();

	#*********************************************
	# �S�̓I�Ɏg�p����ϐ�
	#******************************************************
	my $sql;
	my $msg;
	my $return_mail_id;
	my @messages;
	my $session_id;

	#********************************
	# step 1) �o�^�ς݊m�F ����`�F�b�N�Ɗ���ұ�ނ��o�^����Ă��邩tMemberM���猟��
	#********************************
	## guid���ٱ�ނ������Ƀq�b�g���Ȃ�������G���[�i�������V�K�o�^�p�ƈႤ�j
	#$sql = sprintf("SELECT IF(mobilemailaddress IS NOT NULL, 1, -1)  FROM %s WHERE guid=? AND status_flag=?;", $TABLE{member});

	#my $rv = $dbh->selectrow_array($sql, undef, $guid, 2);
	## �ԐM���[���̊m�� 1==regist 2==support 3==modify 4==error 5==withdraw 6==order
	##					�V�K    �ύX      �o�^�ς� ���������f�[�^����
	#$return_mail_id = 1 == $rv ? 3 : 0 > $rv ? 4 : 5;

	#$messages[1] = undef;
	#$messages[3] = undef;
	#$messages[4] = "�o�^����Ă��郁�[���A�h���X���������܂���B�V�K�Ƀ����}�K�o�^�����Ă��������B";
	#$messages[5] = "���o�^����ł��B�L�����J���̉���l�ȊO�̓����}�K�o�^�ł��܂���B";
	#$msg = $messages[$return_mail_id];


	## �������e�ɑΉ��������l��Ԃ�
	$sql = sprintf(
"SELECT IF
  (mobilemailaddress IS NOT NULL, IF(mobilemailaddress=?, 4, 3), 1)
 FROM %s
  WHERE
   guid=?
  AND
   status_flag=?;", $TABLE{member});

	$return_mail_id = $dbh->selectrow_array($sql, undef, $mail_from, $guid, 2);

	## �ԐM���[���̊m�� 1==info 3==modify 4==error 5==unknownuser
	##					�V�K    �ύX      �o�^�ς� ���������f�[�^����
	$messages[1] = "���[���A�h���X�̓o�^���������܂���B";
	$messages[3] = undef;
	$messages[4] = "���[���A�h���X�o�^�����͊������Ă���܂��B";
	$messages[5] = "���o�^����ł��B����l�ȊO�̓����}�K�o�^�ł��܂���B";
	$msg = $messages[$return_mail_id];

	goto RETURN_MAIL_EXIT unless 3 == $return_mail_id;

	#********************************
	# step 2)	�ύX���A�h���o�^ /�ύX���A�h���o�^�ς݊m�F 
	#			tMemberM�Ƀ��[���A�h���X�����݂���ꍇ�́A���[���A�h���X�ύX�ƂȂ�
	#			tMailAddressLogF��former_mobilemailaddress��tMemberM��mobilemailaddress����v���Ă��邩�̊m�F�����̏ꍇ�͕ύX���A�h���o�^���
	#			�ύX���A�h���o�^��Ԃ̏ꍇ�͍ŏI�������K�v
	#********************************

	$sql = sprintf("SELECT session_id FROM %s WHERE guid=? AND new_mobilemailaddress=?
 AND former_mobilemailaddress=(SELECT mobilemailaddress FROM %s WHERE guid=?);", $TABLE{maillog}, $TABLE{member});

	$session_id = $dbh->selectrow_array($sql, undef, $guid, $mail_from, $guid);

	#********************************
	# step 3)	�ύX���ڽ���o�^���������̏ꍇ�͉��o�^���������s
	#			session_id�����݂��Ȃ����Ƃ�����
	#********************************
	unless ($session_id) {
		require POSIX;
		POSIX->import(qw(strftime));
		$ENV{'TZ'} = "Japan";
		my $TODAY = strftime("%Y%m%d", localtime);
		my $now = strftime("%Y-%m-%d %I:%M:%S", localtime);
		my $now = strftime("%Y%m%d%I%M%S", localtime); # timeformat 20100112150822 (2010/01/12 15:08 20)
		my $tmpfile = $outputdir . $TODAY . '.log';

		$session_id = MyClass::WebUtil::encodeMD5($guid, $now);

		#my $debuginfo = sprintf("[ $now ] --mailfrom : %s --mail_subject : %s --guid : %s --session_id : %s ", $mail_from, $mail_subject, $guid, $session_id);
	    my $debuginfo = sprintf("[ $now ] --mailfrom : %s --mail_body : %s --guid : %s --session_id : %s ", $mail_from, $mail_body, $guid, $session_id);
	    open (FF,">>$tmpfile");
		print FF $debuginfo . "\n";
		close (FF);

		$sql = sprintf("INSERT INTO %s (guid, session_id, status_flag, new_mobilemailaddress, registration_date, former_mobilemailaddress)
 VALUES(
  ?, ?, ?, ?, NOW(),
  (SELECT mobilemailaddress FROM %s WHERE guid=?)
 );", $TABLE{maillog}, $TABLE{member});




		my $attr_ref = MyClass::UsrWebDB::TransactInit($dbh);
		eval {
			## ���o�^�Ȃ̂�status_flag�ɂP��}��
			$dbh->do($sql, undef, $guid, $session_id, 1, $mail_from, $guid);
			$dbh->commit();
		};
		if ($@) {
			$return_mail_id = 4;
			$msg = '���o�^���s�ł��B';
			goto RETURN_MAIL_EXIT;
		}

		MyClass::UsrWebDB::TransactFin($dbh, $attr_ref, $@);
	}

 ## Modified �T�C�g�h���C����ύX�������ߓo�^URL�̕ύX -- 2010/08/02 --
	#$msg = sprintf("���L��URL�ɃA�N�Z�X���ēo�^�����������Ă��������B
	#				http://m.1mp.jp/mod-perl/mm.mpl?s=%s",
	#			$session_id);
	$msg = sprintf("���L��URL�ɃA�N�Z�X���ēo�^�����������Ă��������B
					http://www.avidimer.com/mod-perl/mm.mpl?s=%s",
				$session_id);

	#******************************************************
	# step 4)	��������͋��ʂ̃��[���ԐM����
	#			����id�̒l�ɂ���ĕԐM���[���̓��e���ς��
	#******************************************************
RETURN_MAIL_EXIT:

 	my ($From,$Sub,$Header,$Body,$Footer) = $dbh->selectrow_array("SELECT from_address, subject, header, body, footer FROM DENISMCD.tMailSettingM WHERE id=?;", undef, $return_mail_id);

	$dbh->disconnect();

	$Body =~ s!(%%msg%%)!$msg!;

	my $mailcontents = {
		sendmail		=> '/usr/sbin/sendmail',
		subject			=> $Sub,
		from			=> $From,
		contents_body	=>
"
$Header
$Body
$Footer
",
	};

	#******************************************************
	# step 5) ���[�����M
	#******************************************************
	my $myMail = MyClass::TransferMail->new();
	$myMail->setMailContents($mailcontents);
	$myMail->setMailAddress($mail_from);
	$myMail->SendMailSend();

    1;
}

exit(&main ? 0 : -1);

#------------------------------
1;
