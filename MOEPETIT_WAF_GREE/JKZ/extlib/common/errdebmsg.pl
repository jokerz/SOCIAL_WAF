#/usr/bin/perl

require "/home/vhosts/JKZ/extlib/common/server_state.pl";

use strict;

########################################################
#		エラー・デバッグメッセージ出力関数
#
#  2004.08.16 Technowarp
#
#     入力パラメータ
#				メッセージレベル
#				エラーメッセージ（デバックメッセージ）
#     出力パラメータ
#               なし
#
######################################################
sub ErrDebMSG{

my $PATH;				# 出力ファイルパス
my $filename;			# 出力ファイル名
my $err_level;			# エラーレベル　0-5
my $MSG;				# エラーメッセージ
my ($year,$mon,$mday,$hour,$min,$sec);	# ファイル名作成用エリア
my $today;
my $open_ret;

	# パラメータ取得
	($err_level, $MSG) = @_;

	# サーバ種別チェック
	if($SETUP::Server == $SETUP::Main_Server){
		$PATH = $SETUP::Main_EDMPATH;
	}else{
		$PATH = $SETUP::TEST_EDMPATH;
	}

	#現在の日時取得
	($sec,$min,$hour,$mday,$mon,$year) = localtime(time);
	$year+=1900;
	$mon+=1;

	$today = sprintf("%04d",$year) . sprintf("%02d",$mon) . sprintf("%02d",$mday);

	# ファイル名作成
	$filename = $PATH . "/MSG" . $today . ".txt";

	# エラーレベルチェック
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
