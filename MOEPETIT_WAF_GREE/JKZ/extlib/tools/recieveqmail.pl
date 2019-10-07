#!/usr/bin/perl

#******************************************************
# @desc		�󃁁[���o�^����
# @author	Iwahase Ryo
# @create	2008/03/24
#******************************************************

use strict;
use MIME::Parser;
use MIME::WordDecoder;
use POSIX;
use Jcode;
use lib qw(/home/vhosts/JKZ);
use JKZ::UsrWebDB;
use WebUtil;
use JKZ::Session;
use JKZ::TransferMail;

my $outputdir= '/home/vhosts/homepage.1mp.jp/local/tmp_pool/';

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
    chomp ($mail_from);
    $mail_date .= $entity->head->get('date');
    $mail_subject .= $entity->head->get('subject');

  # BODY
    my @parts = $entity->parts;
    if (@parts) {
    	my $i;
        foreach $i (0 .. $#parts) {
            dump_entity($parts[$i]);
        }
    }
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

    my $parser = new MIME::Parser;
    $parser->output_to_core(1);
    $parser->tmp_recycling(1);
    $parser->tmp_to_core(1);
    $parser->use_inner_files(1);

    my $entity = $parser->parse_data($buf) or die;

    dump_entity($entity);

    #####@�g�p�e�[�u����hash
    my %TABLE = (
    				'karamail'		=>	'HP_general.tKaraMailF',
    				'mailconf'		=>	'HP_management.tMailConf',
    				'regerr'		=>	'HP_management.tRegErr',
    			);
    #####@�g�pSQL
    my %SQL = (
    			'chkifreg'		=>	"SELECT * FROM $TABLE{karamail} WHERE mailaddress=?",
    			'getmailconf'	=>	"SELECT from_addr,subject,header,body,footer FROM $TABLE{mailconf} WHERE type=?",
    			'get_errmsg'	=>	"SELECT * FROM $TABLE{mailconf} LEFT JOIN $TABLE{regerr} ON type=reg_type WHERE err_type=?",
    		  );

#******************************************************
#
#	���ʏ����ݒ�
#******************************************************

    my @type = (undef, 'kari','regerr','regcon');
    #���̎��ʔԍ� 1�����o�^ 2=�G���[ 3=����
    my $arynum=1;
    #####@�Z�b�V�����ϐ�
    my $APSESS;
    #####@�{�o�^�t�H�[���pURL
    my $regist_url = "\n" . 'http://homepage.1mp.jp/';
    #####@����i�Ǘ���ʁj�pURL
    my $member_url = "\n" . 'http://hp01.1mp.jp/mod-perl/edit.mpl';
    #���[�����ʕϐ��錾
 	my ($From,$Sub,$Header,$Body,$Footer);


    my $dbh = JKZ::UsrWebDB::connect ();
    $dbh->do('SET NAMES SJIS');

	#******************************************************
    #####@�o�^�ς݊m�F
    #�o�^�ς݂ł���Γo�^�G���[���[���𑗐M
    #�o�^����Ă��Ȃ���Ζ{�o�^���[���𑗐M
    #******************************************************

    my $sth = $dbh->prepare ($SQL{chkifreg});
    ####�o�^���Ȃ���Ίi�[
    if ($sth->execute ($mail_from) < 1 ) {

		####Session�쐬
		my ($sess_ref, $sess_id);
		if (!defined ($sess_id)) {
			$sess_ref = JKZ::Session->open (undef, undef) or die " $!\n";
			$sess_id = $sess_ref->session_id ();
			
			$APSESS = $sess_id;
		}

    	$dbh->do ("INSERT INTO $TABLE{karamail} (sessid,mailaddress,reg_type,adv_code,kara_regdate) values (?,?,?,?,NOW())",undef,$sess_id,$mail_from,$arynum,$mail_subject);

		#####���t�@�����X����ɂ���
		undef ($sess_ref);

		## text����߂Đ��������ɕύX2008/03/24
		($From,$Sub,$Header,$Body,$Footer) = $dbh->selectrow_array ($SQL{getmailconf}, undef, $arynum);

		####�{�o�^�t�H�[��URL�̐��� pid=page��ID gid=�o�^��� acd=�͍L���R�[�h
		#$regist_url .= "?regid=$APSESS&pid=000002&gid=$arynum&acd=$mail_subject";
		$regist_url .= "000002/?regid=$APSESS&gid=$arynum&acd=$mail_subject";

		$ENV{'TZ'} = "Japan";
		my $TODAY = strftime("%Y%m%d", localtime);
		my $now = strftime("%Y-%m-%d %I:%M:%S", localtime);
  		my $tmpfile = $outputdir . $TODAY . '.log';
	    open (FF,">>$tmpfile");
		print FF $now . "$now $regist_url \n";
		close (FF);
    }
    
    ####�o�^������Γo�^�󋵂��m�F���Ă���ɑΉ��������[��������
    else {
		#1�ɂ���
		++$arynum;
    	my $ref = $sth->fetchrow_hashref ();
    	if ($mail_from eq $ref->{mailaddress}) {

	    	$APSESS = $ref->{sessid};

			######�Í���
			#my $id = $ref->{id};
			#my $regid = WebUtil::Encode ($APSESS, $id);
			
			my $stherr = $dbh->prepare ($SQL{get_errmsg});
			$stherr->execute ($ref->{reg_type});
			my $referr = $stherr->fetchrow_hashref ();

			$From = $referr->{from_addr};
			$Sub  = $referr->{subject};
			$referr->{header} =~ s{ %% (.*?) %% }{ exists ( $referr->{$1} ) ? $referr->{$1} : ""}gex;  $Header = $referr->{header};
			$referr->{body} =~ s{ %% (.*?) %% }{ exists ( $referr->{$1} ) ? $referr->{$1} : ""}gex;    $Body = $referr->{body};
			$referr->{footer} =~ s{ %% (.*?) %% }{ exists ( $referr->{$1} ) ? $referr->{$1} : ""}gex;  $Footer = $referr->{footer};

			$stherr->finish ();

			####�o�^�pURL�̐���
			#$regist_url .= "?regid=$APSESS&pid=000002&gid=$ref->{reg_type}&acd=$ref->{adv_code}";
			$regist_url .= "000002/?regid=$APSESS&gid=$ref->{reg_type}&acd=$ref->{adv_code}";

		}
    }
    $sth->finish ();
	$dbh->disconnect ();
	
#################################################
#
#	��������͋��ʂ̃��[���ԐM����
#
##################################
	$Body =~ s{(%%Url_Regform%%)}{$regist_url};
	$Body =~ s{(%%UrlMember%%)}{$member_url};

	my $mailcontents = {
		sendmail		=> '/usr/sbin/sendmail',
		subject			=> $Sub,
		from			=> $From,
		contents_body	=>
"
$Body
$Footer
",
	};


	my $myMail = JKZ::TransferMail->new ();
	$myMail->setMailContents ($mailcontents);
	$myMail->setMailAddress ($mail_from);
	$myMail->SendMailSend ();

    1;
}

exit(&main ? 0 : -1);

#------------------------------
1;
