#******************************************************
# @desc		�f�[�^�_�E�����[�h
# @package	download.mpl
# @access	public
# @author	Iwahase Ryo
# @create	2008/11/28
# @version	1.00
#******************************************************

use strict;
use lib qw(/home/vhosts/MYSDK/JKZ/extlib/common);
use JKZ::UsrWebDB;
use POSIX;
use Archive::Zip qw ( :ERROR_CODES :CONSTANTS );
use Data::Dumper;

my $q = CGI->new ();

my $data;
my $length;
my $string=" " x 10000;
my $p_err=0;

#****************************
# �t�@�C�������擾
#****************************
my($fileTemp) = POSIX::tmpnam();
open( FILE, ">" . $fileTemp);	


#�^�C�g���s�̐ݒ�@��
# owid, mobilemailaddress, carrier, sex, month_of_birth, date_of_birth, prefecture
$string = '���No.' . ",";
$string .= '���[���A�h���X' . ",";
$string .= '�L�����A' . ",";
$string .= '����' . ",";
$string .= '�a����' . ",";
$string .= '�a����' . ",";
$string .= '�Z�܂��n��' . "\n";

$p_err = print FILE $string;

if($p_err == 0 ) {
	&ShowMsg('������_�E�����[�h','�_�E�����[�h�G���[�ł�',0,"");
	close( FILE );
	unlink($fileTemp);
	exists( $ENV{MODPERL} ) ? ModPerl::Util::exit() : exit();
}

my $cookie = $q->cookie('MYSDKCMSCookie');

my ($condition, $holder) = split (/,/, $cookie);
my @placeholder = split(/ /, $holder);

my $sql = "SELECT mid, mobilemailaddress, carrier, sex, month_of_birth, date_of_birth, prefecture"
 		. " FROM MYSDK.tMemberM WHERE "
 		. $condition;

my $dbh = JKZ::UsrWebDB::connect();
my $aryref = $dbh->selectall_arrayref($sql, { Columns => {} }, @placeholder);

if ($#{$aryref} > 0) {
	foreach (@{$aryref}) {
		$string = $_->{mid} . ",";
		$string .= "\"" . $_->{mobilemailaddress} . "\",";
		$string .= $_->{carrier} . ",";
		$string .= $_->{sex} . ",";
		$string .= $_->{month_of_birth} . ",";
		$string .= $_->{date_of_birth} . ",";
		$string .= $_->{prefecture};
		$string .= "\n";

		$p_err = print FILE $string;
	}
}
else {
	close( FILE );
	unlink($fileTemp);
}

$dbh->disconnect();

close( FILE );

#****************************
# CSV�t�@�C��
#****************************
my $dlfile='/tmp/memberinfo.csv';

#****************************
# �V�K��zip�A�[�J�C�u�̍쐬
#****************************
my $zip = Archive::Zip->new();

#****************************
# zip �t�@�C���������o�ɒǉ�
#****************************
my $member = $zip->addFile( $fileTemp, $dlfile );

#****************************
# ���k���x���̐ݒ�
#****************************
$member->desiredCompressionLevel( COMPRESSION_LEVEL_BEST_COMPRESSION  );

#****************************
# zip��������
#    (0) ���͂Ȃɂ��Ȃ��D
#    (1) �ǂݍ��݃X�g���[�� (�܂��̓Z���g�����f�B���N�g��) ������ɏI�������D
#    (2) ���炩�̈�ʓI�Ȏ�ނ̃G���[���N�������D
#    (3) �ǂݍ���ł���Zip�t�@�C�����Ńt�H�[�}�b�g�̃G���[���N�������D
#    (4) IO �G���[���N�������D
#****************************
if( $zip->writeToFileNamed( $dlfile ) != 0 ) {
	&ShowMsg('�_�E�����[�h', '�t�@�C���̍쐬�Ɏ��s���܂���', 0, '');
	exists( $ENV{MODPERL} ) ? ModPerl::Util::exit() : exit();
}

#****************************
# �_�E�����[�h�t�@�C���̓ǂݍ���
#****************************
open( FILE, $dlfile );
binmode FILE;

read( FILE, $data, -s FILE );

#****************************
# ���[�U�Ƀv�b�V��
#****************************
$length = -s FILE;
print 'Content-Length: '.$length."\n";
print 'Content-disposition: attachment; filename="memberinfocsv.zip"'."\n";	#���[�U�Ɍ�����t�@�C�����@�֘A�Ȃ�
print 'Content-Type: application/zip'."\n\n";

### print 'Content-disposition: attachment; filename="meminfo.csv"'."\n";	#���[�U�Ɍ�����t�@�C�����@�֘A�Ȃ�
### print 'Content-Type: application/octet-stream'."\n\n";

$p_err = print $data;

if($p_err == 0 ) {
	&ShowMsg('������_�E�����[�h', '�_�E�����[�h�G���[�ł�', 0, "");
}

close( FILE );

##�t�@�C�����폜
unlink($fileTemp);
unlink($dlfile);

exists( $ENV{MODPERL} ) ? ModPerl::Util::exit() : exit();
