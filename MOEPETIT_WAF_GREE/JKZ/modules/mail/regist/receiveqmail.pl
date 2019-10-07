#!/usr/bin/perl

#******************************************************
# @desc		�󃁁[���o�^���� �V�K�o�^�p�i�ύX�p�v���O�������Ɠ����j
# @package	receiveqmail
# @author	Iwahase Ryo
# @create	2009/09/16
# @update   2010/03/07  ���[���{���̃f�[�^�����ǉ� �i���[����������̉�����NG�Ή��j
#                       ��������66-74 119 182�s�ڂɕύX����
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
my $outputdir= '/home/vhosts/DENISMCD/JKZ/modules/mail/regist/';

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

   	# Modified �����ǉ� 2010/03/07 BEGIN
#=pod
   	# MimeType�̎擾�Ə��� 
    my ($type, $subtype) = split ('/', $entity->head->mime_type);
    my $body = $entity->bodyhandle;
    ### text
    if ($type =~ /^(text|message)$/) {
            $mail_body .= $body->as_string;
    }
#=cut
    # Modified �����ǉ� 2010/03/07 END

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
    $dbh->do("set names sjis");
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
	## guid���ٱ�ނ������Ƀq�b�g������G���[�i���ɓo�^)
	## ����o�^�͂��Ă��邪�A���[���A�h���X�����o�^�̏ꍇ�́u�P�v ���[���A�h���X���o�^�ς݂́u�|�P�v����ȊO�͑S�Ė��o�^
	$sql = sprintf("SELECT IF(mobilemailaddress IS NULL, 1, -1)  FROM %s WHERE guid=? AND status_flag=?;", $TABLE{member});

	my $rv = $dbh->selectrow_array($sql, undef, $guid, 2);

	## �ԐM���[���̊m�� 1==regist 2==support 3==modify 4==error 5==withdraw 6==order
	# �󃁁[������o�^�ł͂Ȃ��T�C�g�̏ꍇ�Ōォ�烁�[���o�^�̏ꍇ�́�
	#$return_mail_id = 1 == $rv ? 1 : 0 > $rv ? 4 : 5;
	# OMP�͋󃁁[������o�^�Ȃ̂ŁA����f�[�^���̂������ꍇ�͐V�K�o�^�̂��߁�
	$return_mail_id = 1 == $rv ? 3 : 0 > $rv ? 4 : 1;

	$messages[1] = undef;
	$messages[2] = "";
	$messages[3] = "";
	$messages[4] = "���ɓo�^����Ă��܂��B���[���A�h���X�ύX�̏ꍇ�́c";
	$messages[5] = "���o�^����ł��B����l�ȊO�̓����}�K�o�^�ł��܂���B";
	$msg = $messages[$return_mail_id];

	goto RETURN_MAIL_EXIT unless 1 == $return_mail_id;

	#********************************
	# step 2)	���A�h���o�^ /���o�^�ς݊m�F 
	#			tMemberM�Ƀ��[���A�h���X�����݂��Ȃ���΁A���̓o�^�ƂȂ邪
	#			���o�^��Ԃ̏ꍇ�͍ŏI�������K�v
	#********************************

	$sql = sprintf("SELECT session_id FROM %s WHERE guid=? AND new_mobilemailaddress=? AND status_flag !=2;", $TABLE{maillog});
	$session_id = $dbh->selectrow_array($sql, undef, $guid, $mail_from);

	#********************************
	# step 3)	�V�K���̏ꍇ�͉��o�^������
	#			session_id�����݂��Ȃ����Ƃ�����
	#********************************
	unless ($session_id) {
		require POSIX;
		POSIX->import(qw(strftime));
		$ENV{'TZ'} = "Japan";
		my $TODAY = strftime("%Y%m%d", localtime);
	## Modified 20100112
		#my $now = strftime("%Y-%m-%d %I:%M:%S", localtime);
		my $now = strftime("%Y%m%d%I%M%S", localtime); # timeformat 20100112150822 (2010/01/12 15:08 20)
		my $tmpfile = $outputdir . $TODAY . '.log';

		$session_id = MyClass::WebUtil::encodeMD5($guid, $now);

		#my $debuginfo = sprintf("[ $now ] --mailfrom : %s --mail_subject : %s --guid : %s --session_id : %s ", $mail_from, $mail_subject, $guid, $session_id);
		# Modified �{���Ή�2010/03/07
		my $debuginfo = sprintf("[ $now ] --mailfrom : %s --mail_body : %s --guid : %s --session_id : %s ", $mail_from, $mail_body, $guid, $session_id);

	    open (FF,">>$tmpfile");
		print FF $debuginfo . "\n";
		close (FF);

		$sql = sprintf("INSERT INTO %s (guid, session_id, status_flag, type_flag, new_mobilemailaddress, registration_date) VALUES(?, ?, ?, ?, ?, NOW());", $TABLE{maillog});
		my $attr_ref = MyClass::UsrWebDB::TransactInit($dbh);
		eval {
			## ���o�^�Ȃ̂�status_flag�ɂP��}��
			$dbh->do($sql, undef, $guid, $session_id, 1, 1, $mail_from);
			$dbh->commit();
		};
		if ($@) {
			$return_mail_id = 4;
			$msg = '���o�^���s�ł��B';
			goto RETURN_MAIL_EXIT;
		}

		MyClass::UsrWebDB::TransactFin($dbh, $attr_ref, $@);
	}
    ## t�͏������e t=1 �V�K�o�^ t=3 �͕ύX(tMailSetting��id�̐��l)
 ## Modified �T�C�g�h���C����ύX�������ߓo�^URL�̕ύX -- 2010/08/02 --
	#$msg = sprintf("���L��URL�ɃA�N�Z�X���ēo�^�����������Ă��������B
	#				http://m.1mp.jp/rg.mpl?t=1&s=%s",
	#			$session_id);
	$msg = sprintf("���L��URL�ɃA�N�Z�X���ēo�^�����������Ă��������B
					http://www.avidimer.com/rg.mpl?t=1&s=%s",
				$session_id);

	#******************************************************
	# step 4)	��������͋��ʂ̃��[���ԐM����
	#			����id�̒l�ɂ���ĕԐM���[���̓��e���ς��
	#******************************************************
RETURN_MAIL_EXIT:

    $sql = sprintf("SELECT from_address, subject, header, body, footer FROM DENISMCD.tMailSettingM WHERE id=?;", $TABLE{mailsetting});
 	my ($From,$Sub,$Header,$Body,$Footer) = $dbh->selectrow_array($sql, undef, $return_mail_id);
 	#my ($From,$Sub,$Header,$Body,$Footer) = $dbh->selectrow_array("SELECT from_address, subject, header, body, footer FROM 1MP.tMailSettingM WHERE id=?;", undef, $return_mail_id);

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
