########################################################
#		ページ表示関数
#
#     入力パラメータ
#               1:ページタイトル
#               2:表示文字列
#               3:URL個数
#               4:URL/表示文字列の配列
#
#     出力パラメータ
#               結果 なし
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
