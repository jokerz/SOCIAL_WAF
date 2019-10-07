#/usr/bin/perl

require "/home/vhosts/JKZ/extlib/common/server_state.pl";

use strict;

########################################################
#		�G���[�E�f�o�b�O���b�Z�[�W�o�͊֐�
#
#  2004.08.16 Technowarp
#
#     ���̓p�����[�^
#				���b�Z�[�W���x��
#				�G���[���b�Z�[�W�i�f�o�b�N���b�Z�[�W�j
#     �o�̓p�����[�^
#               �Ȃ�
#
######################################################
sub ErrDebMSG{

my $PATH;				# �o�̓t�@�C���p�X
my $filename;			# �o�̓t�@�C����
my $err_level;			# �G���[���x���@0-5
my $MSG;				# �G���[���b�Z�[�W
my ($year,$mon,$mday,$hour,$min,$sec);	# �t�@�C�����쐬�p�G���A
my $today;
my $open_ret;

	# �p�����[�^�擾
	($err_level, $MSG) = @_;

	# �T�[�o��ʃ`�F�b�N
	if($SETUP::Server == $SETUP::Main_Server){
		$PATH = $SETUP::Main_EDMPATH;
	}else{
		$PATH = $SETUP::TEST_EDMPATH;
	}

	#���݂̓����擾
	($sec,$min,$hour,$mday,$mon,$year) = localtime(time);
	$year+=1900;
	$mon+=1;

	$today = sprintf("%04d",$year) . sprintf("%02d",$mon) . sprintf("%02d",$mday);

	# �t�@�C�����쐬
	$filename = $PATH . "/MSG" . $today . ".txt";

	# �G���[���x���`�F�b�N
	if($err_level >= $SETUP::Level){
		if( -e $filename ){
			$open_ret = open(FILE, ">>" . $filename);
			if(defined($open_ret)){
				print FILE $MSG . "\n";
				close(FILE);
			}
		}else{
			$open_ret = open(FILE, ">" . $filename);
			if(defined($open_ret)){
				print FILE $MSG . "\n";
				close(FILE);
				chmod ( 0666, $filename);
			}
		}
	}

	return 1;
}1;
