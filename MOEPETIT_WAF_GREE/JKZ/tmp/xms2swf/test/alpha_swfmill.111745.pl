#!/usr/bin/perl -I/home/vhosts/MOEPETIT/JKZ

# $Id: alpha_swfmill.111745.pl ,v 1.0 2011/05/22 RyoIwahase Exp $

$|=1;
use strict;
use warnings;
use MyClass::WebUtil;

# 消費系のアイテム base(アイテムID) 1001 2001 3001 4001 5001
#my $b   = $q->param('b');
# キャラ画像ID キャラID + カテゴリID 001 + 01..06  => 00101 00102
#my $c   = $q->param('c');

# stopwatch_id(item_id) 6001から 11001から (6001はノーマルストップウォッチ)
#my $csw = $q->param('csw'); 
# font  stopwatch_id f_6001
#my $f   = $q->param('f');

# 本番用
#my $cast_xmlfile = 'EqualCast.xml';
#my $URL2GREE = 'http%3A%2F%2Fwww.moepetit.jp%2F';
#my $URL2MOEPETIT = 'http://www.moepetit.jp';
#my $PARAMETERX =  '-3581';

# 置き換え文字 FLASHにコンバートする直前に置き換え
my $REPSTR = {
    b_1001 => {
        objectID1  => "8",
        objectID2  => "9",
        objectID3  => "10",
        objectID4  => "11",
        objectID5  => "12",
        objectID6  => "13",
        objectID7  => "14",
        objectID8  => "15",
        objectID9  => "16",
        objectID10 => "17",
        objectID11 => "18",
        objectID12 => "7",
        objectID21 => "54",
        objectID22 => "55",
        objectID23 => "56",
        objectID24 => "57",
        objectID25 => "58",
        objectID26 => "59",
    },
    b_2001 => {
        objectID1  => "7",
        objectID2  => "8",
        objectID3  => "9",
        objectID4  => "10",
        objectID5  => "11",
        objectID6  => "12",
        objectID7  => "13",
        objectID8  => "14",
        objectID9  => "15",
        objectID10 => "16",
        objectID11 => "17",
        objectID12 => "6",
        objectID21 => "53",
        objectID22 => "54",
        objectID23 => "55",
        objectID24 => "56",
        objectID25 => "57",
        objectID26 => "58",
    },
    b_3001 => {
        objectID1  => "7",
        objectID2  => "8",
        objectID3  => "9",
        objectID4  => "10",
        objectID5  => "11",
        objectID6  => "12",
        objectID7  => "13",
        objectID8  => "14",
        objectID9  => "15",
        objectID10 => "16",
        objectID11 => "17",
        objectID12 => "6",
        objectID21 => "56",
        objectID22 => "57",
        objectID23 => "58",
        objectID24 => "59",
        objectID25 => "60",
        objectID26 => "61",
    },
    b_4001 => {
        objectID1  => "7",
        objectID2  => "8",
        objectID3  => "9",
        objectID4  => "10",
        objectID5  => "11",
        objectID6  => "12",
        objectID7  => "13",
        objectID8  => "14",
        objectID9  => "15",
        objectID10 => "16",
        objectID11 => "17",
        objectID12 => "6",
        objectID21 => "51",
        objectID22 => "52",
        objectID23 => "53",
        objectID24 => "54",
        objectID25 => "55",
        objectID26 => "56",
    },
    b_5001 => {
        objectID1  => "19",
        objectID2  => "20",
        objectID3  => "21",
        objectID4  => "22",
        objectID5  => "23",
        objectID6  => "24",
        objectID7  => "25",
        objectID8  => "26",
        objectID9  => "27",
        objectID10 => "28",
        objectID11 => "29",
        objectID12 => "17",
        objectID21 => "53",
        objectID22 => "54",
        objectID23 => "55",
        objectID24 => "56",
        objectID25 => "57",
        objectID26 => "58",
    },
};


#********************************
=pod
ls b_* > b.txt
これb_のxmlファイルリストを作成してファイル内の拡張子は削除する 接頭子も削除
perl  -i -pe 's/b_//g' b.txt
perl  -i -pe 's/\.xml//g' b.txt

ls c_* > c.txt
拡張子を削除  接頭子削除
perl  -i -pe 's/\.xml//g' c.txt
perl  -i -pe 's/c_//g' c.txt


ls csw_* > csw.txt
cp csw.txt csw_f.txt
このファイル内の接頭子を削除する 拡張子も削除
perl  -i -pe 's/csw_//g' csw_f.txt
perl  -i -pe 's/\.xml//g' csw_f.txt
拡張子を削除

c.txtとcsw_f.txtは改行コードをカンマに変更する。
最後に値にもカンマを加える（無駄な生成が発生するがそうしないと最後の値での生成に失敗する。)
perl  -i -pe 's/\n/,/g' c.txt
perl  -i -pe 's/\n/,/g' csw_f.txt

=cut
#********************************
use Data::Dumper;

my $b_file   = 'b.txt';
my $c_file   = 'c.txt';
my $csw_file = 'csw.txt';
my $f_file   = 'f.txt';
# ｽﾄｯﾌﾟｳｫｯﾁとフォントは同じファイル名のため接頭しで判定する
my $csw_f_file   = 'csw_f.txt';


#テスト用
#my $URL2GREE     = 'http%3A%2F%2Fst.moepetit.jp%2F';
my $URL2GREE     = 'http://mgadget-sb.gree.jp/4180/?url=http%3A%2F%2Fst.moepetit.jp%2F';

my $URL2MOEPETIT = 'http://st.moepetit.jp/';
my $PARAMETERX   =  '139';
#my $cast_xmlfile = '/home/vhosts/MOEPETIT/JKZ/tmp/xml2swf/test/LessThanCast.xml';

#my $PARAMETERX   =  '-3581';
my $cast_xmlfile = '/home/vhosts/MOEPETIT/JKZ/tmp/xml2swf/test/EqualCast.xml';


# 成功判定の置き換え
my $cast_file    = MyClass::WebUtil::openFileIntoScalar($cast_xmlfile);

open(R, "< $b_file") or die "fail opne $!\n";
my @base_file = <R>;
close (R);

open(R, "< $c_file") or die "fail opne $!\n";
my $ccharacter_file = <R>;
$ccharacter_file =~ s!\r|\n!!g;
close (R);
my @character_file = split(/,/, $ccharacter_file);

open(R, "< $csw_f_file") or die "fail opne $!\n";
my $ccsw_font_file = <R>;
$ccsw_font_file =~ s!\r|\n!!g;
close (R);
my @csw_font_file = split(/,/, $ccsw_font_file);

#open(R "< $csw_file") {
#my @sw_file = <R>;
#close (R);
#open(R "< $f_file") {
#my @font_file = <R>;
#close (R);

my $cnt = 0;
foreach my $base_xml (@base_file) {
    ## ベースデータを取得し、環境に合わせたデータに置き換える
	chomp $base_xml;



#print __LINE__, ">>> basefile:",$base_xml,"\n";


    my $base_xml_file = sprintf("b_%s.xml", $base_xml);
    local $/;
	    local *F;
    open (F, "<". $base_xml_file . "\0") or die __LINE__," fuck you  $base_xml_file $!\n";
    my $base_skelton = <F>;
    close (F);

    foreach my $base_character_xml (@character_file) {
		chomp $base_character_xml;



#print __LINE__, ">>>> base character:",$base_character_xml, "\n";

        my $base_character_xml_file = sprintf("c_%s.xml", $base_character_xml);

        my $Ac_file   = MyClass::WebUtil::openFileIntoScalar($base_character_xml_file);

#print __LINE__, ">>>> ", $Ac_file, "\n";

        foreach my $base_file_name (@csw_font_file) {
			chomp $base_file_name;

#chomp $base_file_name;
#warn __LINE__, ">>>>",$base_file_name, "\n";
#=pod
            my $base_stopwatch_xml = sprintf("csw_%s.xml", $base_file_name);
            my $base_font_xml      = sprintf("f_%s.xml", $base_file_name);
            my $Acsw_file = MyClass::WebUtil::openFileIntoScalar($base_stopwatch_xml);
            my $Af_file   = MyClass::WebUtil::openFileIntoScalar($base_font_xml);


#print __LINE__, ">>>> base      file:",$base_xml_file,"\n";
#print __LINE__, ">>>> base character:",$base_character_xml_file, "\n";
#print __LINE__, ">>>> base stopwacth:",$base_stopwatch_xml, "\n";
#print __LINE__, ">>>> base      font:",$base_font_xml, "\n\n";

            my $skelton = $base_skelton;

            $skelton =~ s{ %&(CHARACTERBITMAP)&% }{ $Ac_file }gex;

            $skelton =~ s{ %&(STOPWATCH)&% }{ $Acsw_file }gex;
            $skelton =~ s{ %&(FONTFAMILY)&% }{ $Af_file }gex;

            $skelton =~ s{ %&(LESSOREQUAL)&% }{ $cast_file }gex;
            # URLの置き換え
            $skelton =~ s{ %&(URL2GREE)&% }{ $URL2GREE }gex;
            # URLの置き換え
            $skelton =~ s{ %&(URL2MOEPETIT)&% }{ $URL2MOEPETIT }gex;
            # 座標の置き換え
            $skelton =~ s{ %&(PARAMETERX)&% }{ $PARAMETERX }gex;
            # 最後のオブジェクトIDの置き換え
            
            $skelton =~ s{ %&(.*?)&% } { exists($REPSTR->{'b_' . $base_xml}->{$1}) ? $REPSTR->{'b_' . $base_xml}->{$1} : "" }gex;

            my $joined_xmlfile    = sprintf("/home/vhosts/MOEPETIT/JKZ/tmp/xml2swf/test/flash/%s:%s:%s.xml", $base_xml, $base_character_xml, $base_file_name);
            my $converted_swffile = sprintf("/home/vhosts/MOEPETIT/www.moepetit.jp/htdocs/flashtest/%s:%s:%s.swf", $base_xml, $base_character_xml, $base_file_name);

            # 情報をファイルに出力し、対応ディレクトリに設置
            open (W,">$joined_xmlfile") or die "fuck fail creating file $joined_xmlfile  $!\n";
            print W $skelton;
            close (W);
            #my $ret = system("/usr/local/bin/swfmill -e cp932 xml2swf $joined_xmlfile $converted_swffile");
            my $ret = system("/usr/local/bin/swfmill xml2swf $joined_xmlfile $converted_swffile");
            0 != $ret ? print "\n", __LINE__, " failed file: ", $converted_swffile : printf ("%s ", $cnt);

## デバッグのため削除しない
            unlink $joined_xmlfile;

$cnt++;


        }
    }
}

print "\n","="x100, "\n", $cnt , "\n", "="x100;







exit;

