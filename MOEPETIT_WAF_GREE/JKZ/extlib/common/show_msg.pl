########################################################
#		�y�[�W�\���֐�
#
#     ���̓p�����[�^
#               1:�y�[�W�^�C�g��
#               2:�\��������
#               3:URL��
#               4:URL/�\��������̔z��
#
#     �o�̓p�����[�^
#               ���� �Ȃ�
#
######################################################
use strict;

sub ShowMsg{
my $cnt=0;

    print "Content-type: text/html; charset=Shift_JIS\n\n";
    print "<HTML><HEAD>\n";
    print "<TITLE>" . $_[0] . "</TITLE>\n";
    print "</HEAD><body>\n";
    print $_[1] . "<body>\n";
	print "<P>\n";
	
	if( $_[2] > 0){
	    for( $cnt = 3; $cnt < (($_[2] * 2)+3); $cnt += 2){
	    	print "<A HREF=\"" . $_[$cnt] . "\">" . $_[$cnt+1] . "</A><body>\n";
	    }
	}

    print "</BODY></HTML>\n";
    return 1;
}
1;
