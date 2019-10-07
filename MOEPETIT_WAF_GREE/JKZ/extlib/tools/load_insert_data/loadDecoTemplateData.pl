#!/usr/bin/perl -w
#******************************************************
# @desc		カテゴリ４ デコメテンプレートの読み込みとDBに格納
#           テンプレート一覧ファイルが必要
#
#   デコメテンプレート登録手順
#   このスクリプトが実行されるまでの手順
#
#
# step 1. 画像データからファイル名を取得して、一覧生成
#   [ryo@penguin tmp]$ find ./4 -type f -name '*.gif' > category4.txt
#
# step 2. vi で編集 毎行カンマで終わらす
# :1,$s/NOW())/&,/
#
# step 3. 文頭にINSERT 文を追加してsqlファイルとして保存
# INSERT INTO tProductM
# (`product_id`, `status_flag`, `charge_flag`, `point_flag`, `product_name`, `categorym_id`, `subcategorym_id`, `registration_date`)
# VALUES
#
# step 5. mysqlに流し込む
#   [ryo@penguin tmp]$ mysql -h localhost -p -u dbmaster MYSDK < category4.sql
#
#
# step 6. 画像データDB格納スクリプトを作成（一覧のbkファイルから）
#   [ryo@penguin tmp]$ perl -i.bk -pe 's/(^\.\/\d{1,2}\/\d{1,2}\/)(.*?)(\.gif)$/loadDecoTmplt\.pl $1$2$3 $2/' category4.sh
#
# ファイルの先頭にシェバングを追加
#  #!/bin/sh
# 実行権限付与
#    [ryo@penguin tmp]$ chmod +x category3.sh
# パスを通して実行
#    [ryo@penguin tmp]$ export PATH=$PATH:/home/vhostsuser/KKFLA/tmp_work
#
#    [ryo@penguin tmp]$ category4.sh
#
#
# ファイル名を整える
#  #ファイルによっては_01.gifとかになってるのをcp_nnnnnnn.gifにする
#  find ./ -type f -name '*.gif' | perl -pe 'chomp; $old = $_; s/^(\.\/\d{1,2})(\/cp_[0-9]{7})_\d(\.gif)$/$1$2$3/; rename $old, $_;' 
#
#
#  step 7. 全テンプレートデータを一時ディレクトリにアップロード
# 　全データからテンプレートデータだけを取得する。（不要な画像データ）
#
#  step 8. ディレクトリを読み込みテンプレート一覧ファイル生成
#  # どこものテンプレリスト
#    [ryo@penguin tmp]$ find ./ -type f -name 'cp_*.dmt' > list_dmt.txt
#    [ryo@penguin tmp]$ perl -i -pe 's/^\.\/.*?\/.*?\/(cp_[0-9]{7}\.dmt)$/$1/' list_dmt.txt
#    [ryo@penguin tmp]$ find ./ -type f -name 'cp_*.hmt' > list_hmt.txt
#    [ryo@penguin tmp]$ perl -i -pe 's/^\.\/.*?\/.*?\/(cp_[0-9]{7}\.hmt)$/$1/' list_hmt.txt
#    [ryo@penguin tmp]$ find ./ -type f -name 'cp_*.khm' > list_khm.txt
#    [ryo@penguin tmp]$ perl -i -pe 's/^\.\/.*?\/.*?\/(cp_[0-9]{7}\.khm)$/$1/' list_khm.txt
#
#  ## 実際のデータを作業ディレクトリにコピー
#    [ryo@penguin tmp]$ find ./ -type f -name 'cp_*.dmt' -exec cp -r {} DecoTmplt \;
#    [ryo@penguin tmp]$ find ./ -type f -name 'cp_*.hmt' -exec cp {} DecoTmplt \;
#    [ryo@penguin tmp]$ find ./ -type f -name 'cp_*.khm' -exec cp -r {} DecoTmplt \;
#
#
# step 9. テンプレートデータを読み込み、データ、サイズ・マイムタイプにして、インサート
#    作成したリストを元にデータのループで処理
#
#
# loadDecoTmpltData.plが実行される
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


	## 拡張子
	my $extdmt = '.dmt';
	my $exthmt = '.hmt';
	my $extkhm = '.khm';

	## Mime-type
	my $mime_type_docomo	= 'application/x-decomail-template';
	my $mime_type_softbank	= 'application/x-htmlmail-template';
	my $mime_type_au		= 'application/x-kddi-htmlmail';

	## ファイルハンドル
	my ($fhd, $fhs, $fha);
	## ファイルサイズ
	my ($file_size_docomo, $file_size_softbank, $file_size_au);
	## 実データ
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


	 	# ファイルサイズ取得
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
