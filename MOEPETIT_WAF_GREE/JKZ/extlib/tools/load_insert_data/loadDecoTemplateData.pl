#!/usr/bin/perl -w
#******************************************************
# @desc		�J�e�S���S �f�R���e���v���[�g�̓ǂݍ��݂�DB�Ɋi�[
#           �e���v���[�g�ꗗ�t�@�C�����K�v
#
#   �f�R���e���v���[�g�o�^�菇
#   ���̃X�N���v�g�����s�����܂ł̎菇
#
#
# step 1. �摜�f�[�^����t�@�C�������擾���āA�ꗗ����
#   [ryo@penguin tmp]$ find ./4 -type f -name '*.gif' > category4.txt
#
# step 2. vi �ŕҏW ���s�J���}�ŏI��炷
# :1,$s/NOW())/&,/
#
# step 3. ������INSERT ����ǉ�����sql�t�@�C���Ƃ��ĕۑ�
# INSERT INTO tProductM
# (`product_id`, `status_flag`, `charge_flag`, `point_flag`, `product_name`, `categorym_id`, `subcategorym_id`, `registration_date`)
# VALUES
#
# step 5. mysql�ɗ�������
#   [ryo@penguin tmp]$ mysql -h localhost -p -u dbmaster MYSDK < category4.sql
#
#
# step 6. �摜�f�[�^DB�i�[�X�N���v�g���쐬�i�ꗗ��bk�t�@�C������j
#   [ryo@penguin tmp]$ perl -i.bk -pe 's/(^\.\/\d{1,2}\/\d{1,2}\/)(.*?)(\.gif)$/loadDecoTmplt\.pl $1$2$3 $2/' category4.sh
#
# �t�@�C���̐擪�ɃV�F�o���O��ǉ�
#  #!/bin/sh
# ���s�����t�^
#    [ryo@penguin tmp]$ chmod +x category3.sh
# �p�X��ʂ��Ď��s
#    [ryo@penguin tmp]$ export PATH=$PATH:/home/vhostsuser/KKFLA/tmp_work
#
#    [ryo@penguin tmp]$ category4.sh
#
#
# �t�@�C�����𐮂���
#  #�t�@�C���ɂ���Ă�_01.gif�Ƃ��ɂȂ��Ă�̂�cp_nnnnnnn.gif�ɂ���
#  find ./ -type f -name '*.gif' | perl -pe 'chomp; $old = $_; s/^(\.\/\d{1,2})(\/cp_[0-9]{7})_\d(\.gif)$/$1$2$3/; rename $old, $_;' 
#
#
#  step 7. �S�e���v���[�g�f�[�^���ꎞ�f�B���N�g���ɃA�b�v���[�h
# �@�S�f�[�^����e���v���[�g�f�[�^�������擾����B�i�s�v�ȉ摜�f�[�^�j
#
#  step 8. �f�B���N�g����ǂݍ��݃e���v���[�g�ꗗ�t�@�C������
#  # �ǂ����̃e���v�����X�g
#    [ryo@penguin tmp]$ find ./ -type f -name 'cp_*.dmt' > list_dmt.txt
#    [ryo@penguin tmp]$ perl -i -pe 's/^\.\/.*?\/.*?\/(cp_[0-9]{7}\.dmt)$/$1/' list_dmt.txt
#    [ryo@penguin tmp]$ find ./ -type f -name 'cp_*.hmt' > list_hmt.txt
#    [ryo@penguin tmp]$ perl -i -pe 's/^\.\/.*?\/.*?\/(cp_[0-9]{7}\.hmt)$/$1/' list_hmt.txt
#    [ryo@penguin tmp]$ find ./ -type f -name 'cp_*.khm' > list_khm.txt
#    [ryo@penguin tmp]$ perl -i -pe 's/^\.\/.*?\/.*?\/(cp_[0-9]{7}\.khm)$/$1/' list_khm.txt
#
#  ## ���ۂ̃f�[�^����ƃf�B���N�g���ɃR�s�[
#    [ryo@penguin tmp]$ find ./ -type f -name 'cp_*.dmt' -exec cp -r {} DecoTmplt \;
#    [ryo@penguin tmp]$ find ./ -type f -name 'cp_*.hmt' -exec cp {} DecoTmplt \;
#    [ryo@penguin tmp]$ find ./ -type f -name 'cp_*.khm' -exec cp -r {} DecoTmplt \;
#
#
# step 9. �e���v���[�g�f�[�^��ǂݍ��݁A�f�[�^�A�T�C�Y�E�}�C���^�C�v�ɂ��āA�C���T�[�g
#    �쐬�������X�g�����Ƀf�[�^�̃��[�v�ŏ���
#
#
# loadDecoTmpltData.pl�����s�����
#
#
# @package	loadDecoTemplateData.pl
# @access	public
# @author	Iwahase Ryo
# @create	2010/06/02
# @version	1.00
#******************************************************

use strict;
use Carp qw(confess);
use lib qw(/home/vhostsuser/KKFLA/JKZ);
use JKZ::UsrWebDB;
use WebUtil;


	## �g���q
	my $extdmt = '.dmt';
	my $exthmt = '.hmt';
	my $extkhm = '.khm';

	## Mime-type
	my $mime_type_docomo	= 'application/x-decomail-template';
	my $mime_type_softbank	= 'application/x-htmlmail-template';
	my $mime_type_au		= 'application/x-kddi-htmlmail';

	## �t�@�C���n���h��
	my ($fhd, $fhs, $fha);
	## �t�@�C���T�C�Y
	my ($file_size_docomo, $file_size_softbank, $file_size_au);
	## ���f�[�^
	my ($dmt, $hmt, $khm);

	my @SuccessCount;
	my @ErrorCount;

	my $sql = "INSERT INTO tProductDecoTmplt (
`productm_code`,
`dmt`,
`hmt`,
`khm`,
`mime_type_docomo`,
`mime_type_softbank`,
`mime_type_au`,
`file_size_docomo`,
`file_size_softbank`,
`file_size_au`
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
";


	my $listfile = 'list.txt';

	open(RF,"< $listfile") or die "can not open $!\n";
	my @LISTARRAY = <RF>;
	close(RF);

	my $dbh = JKZ::UsrWebDB::connect();
	$dbh->do('set names utf8');
	$dbh->do('use MYSDK');

	my $attr_ref = JKZ::UsrWebDB::TransactInit($dbh);
	
	foreach my $filename (@LISTARRAY) {

		chomp $filename;

		$fhd = $filename . $extdmt;
		$fhs = $filename . $exthmt;
		$fha = $filename . $extkhm;


	 	# �t�@�C���T�C�Y�擾
		$file_size_docomo	= (stat($fhd))[7];
		$file_size_softbank = (stat($fhs))[7];
		$file_size_au		= (stat($fha))[7];



$dmt = WebUtil::openFileIntoScalar($fhd);
$hmt = WebUtil::openFileIntoScalar($fhs);
$khm = WebUtil::openFileIntoScalar($fha);


=pod

		(read($fhd, $dmt, -s $fhd) == -s $fhd)
			or confess ("Can't read data file: $!");

		(read($fhs, $hmt, -s $fhs) == -s $fhs)
			or confess ("Can't read data file: $!");

		(read($fha, $khm, -s $fha) == -s $fha)
			or confess ("Can't read data file: $!");
=cut

		eval {
			$dbh->do ($sql, undef, $filename, $dmt, $hmt, $khm, $mime_type_docomo, $mime_type_softbank, $mime_type_au, $file_size_docomo, $file_size_softbank, $file_size_au);
			$dbh->commit();

		};
		if ($@) {
print $@, "\n";
			$dbh->rollback();

			push(@ErrorCount, $filename);

			print "\n============\n INSERT FAILURE : $filename \n============";
		}
		else {
			push(@SuccessCount, $filename);
			print "============\n INSERT SUCCESS : $filename \n============";
		}
	}

	JKZ::UsrWebDB::TransactFin($dbh, $attr_ref);

	print "\n INSERT RESULT: \n success: $#SuccessCount \n failure: $#ErrorCount \n";


exit (0);
