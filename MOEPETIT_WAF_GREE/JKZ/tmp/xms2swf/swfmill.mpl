#!/usr/bin/perl

# $Id: swfmill.mpl,v 1.0 2011/03/23 RyoIwahase Exp $

use strict;
use warnings;


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
#my $PARAMETERX =  '-1751';

#テスト用
my $URL2GREE   = 'http%3A%2F%2Fst.moepetit.jp%2F';
my $PARAMETERX =  '249';

# 置き換え文字 FLASHにコンバートする直前に置き換え
my $REPSTR = {
    b_1001 => {
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
        objectID21 => "48",
        objectID22 => "49",
        objectID23 => "50",
        objectID24 => "51",
        objectID25 => "52",
        objectID26 => "53",
        objectID27 => "54",
        objectID28 => "55",
        objectID29 => "56",
        objectID30 => "57",
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
        objectID21 => "50",
        objectID22 => "51",
        objectID23 => "52",
        objectID24 => "53",
        objectID25 => "54",
        objectID26 => "55",
        objectID27 => "56",
        objectID28 => "57",
        objectID29 => "58",
        objectID30 => "59",
    },
    b_3001 => {
        objectID1  => "16",
        objectID2  => "17",
        objectID3  => "18",
        objectID4  => "19",
        objectID5  => "20",
        objectID6  => "21",
        objectID7  => "22",
        objectID8  => "23",
        objectID9  => "24",
        objectID10 => "25",
        objectID11 => "26",
        objectID21 => "47",
        objectID22 => "48",
        objectID23 => "49",
        objectID24 => "50",
        objectID25 => "51",
        objectID26 => "52",
        objectID27 => "53",
        objectID28 => "54",
        objectID29 => "55",
        objectID30 => "56",
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
        objectID21 => "45",
        objectID22 => "46",
        objectID23 => "47",
        objectID24 => "48",
        objectID25 => "49",
        objectID26 => "50",
        objectID27 => "51",
        objectID28 => "52",
        objectID29 => "53",
        objectID30 => "54",
    },
    b_5001 => {
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
        objectID21 => "47",
        objectID22 => "48",
        objectID23 => "49",
        objectID24 => "50",
        objectID25 => "51",
        objectID26 => "52",
        objectID27 => "53",
        objectID28 => "54",
        objectID29 => "55",
        objectID30 => "56",
    },
};


#********************************
=pod
ls b_* > b.txt
これb_のxmlファイルリストを作成してファイル内の拡張子は削除する

ls c_* > c.txt
perl  -i -pe 's/\.xml//g' c.txt
拡張子を削除

ls csw_* > csw.txt
cp csw.txt csw_f.txt
このファイル内の接頭子だけを削除する。

perl  -i -pe 's/\.xml//g' csw_f.txt
拡張子を削除

=cut
#********************************


my $b_file   = 'b.txt';
my $c_file   = 'c.txt';
my $csw_file = 'csw.txt';
my $f_file   = 'f.txt';
# ｽﾄｯﾌﾟｳｫｯﾁとフォントは同じファイル名のため接頭しで判定する
my $csw_f_file   = 'csw_f.txt';

# 成功判定の置き換え
my $cast_file = MyClass::WebUtil::openFileIntoScalar($cast_xmlfile);

open(R "< $b_file") {
my @base_file = <R>;
close (R);

open(R "< $c_file") {
my @character_file = <R>;
close (R);

open(R "< $csw_f_file") {
my @csw_font_file = <R>;
close (R);

#open(R "< $csw_file") {
#my @sw_file = <R>;
#close (R);
#open(R "< $f_file") {
#my @font_file = <R>;
#close (R);


foreach my $base_xml (@base_file) {
    ## ベースデータを取得し、環境に合わせたデータに置き換える
    my $base_xml_file = sprintf("%s.xml", $base_xml);
    local $/;
    local *F;
    open (F, "<". $base_xml_file . "\0") or die __LINE__," fuck you $!\n";
    my $skelton = <F>;
    close (F);

    foreach my $base_character_xml (@character_file) {
        $base_character_xml = $base_character_xml . '.xml';
        my $c_file   = MyClass::WebUtil::openFileIntoScalar($base_character_xml);

        foreach my $base_file_name (@csw_font_file) {
            my $base_stopwatch_xml = sprintf("csw_%s.xml", $base_file_name);
            my $base_font_xml      = sprintf("f_%s.xml", $base_file_name);
            my $csw_file = MyClass::WebUtil::openFileIntoScalar($base_stopwatch_xml);
            my $f_file   = MyClass::WebUtil::openFileIntoScalar($base_font_xml);


            $skelton =~ s{ %&(CHARACTERBITMAP)&% }{ $c_file }gex;

            $skelton =~ s{ %&(STOPWATCH)&% }{ $csw_file }gex;
            $skelton =~ s{ %&(FONTFAMILY)&% }{ $f_file }gex;

            $skelton =~ s{ %&(LESSOREQUAL)&% }{ $cast_file }gex;
            # URLの置き換え
            $skelton =~ s{ %&(URL2GREE)&% }{ $URL2GREE }gex;
            # 座標の置き換え
            $skelton =~ s{ %&(PARAMETERX)&% }{ $PARAMETERX }gex;
            # 最後のオブジェクトIDの置き換え
            $skelton =~ s{ %&(.*?)&% } { exists($REPSTR->{$base_xml}->{$1}) ? $REPSTR->{$base_xml}->{$1} : "" }gex;

            my $joined_xmlfile    = sprintf("/home/vhosts/MOEPETIT/JKZ/tmp/xml2swf/flash/b_%s:c_%s:csw_%s.xml", $base_xml, $base_character_xml, $base_file_name);
            my $converted_swffile = sprintf("/home/vhosts/MOEPETIT/JKZ/tmp/xml2swf/flash/b_%s:c_%s:csw_%s.swf", $base_xml, $base_character_xml, $base_file_name);

            # 情報をファイルに出力し、対応ディレクトリに設置
            open (W,">$joined_xmlfile") or die "fuck fail creating file $joined_xmlfile  $!\n";
            print W $skelton;
            close (W);
            system("/usr/local/bin/swfmill -e cp932 xml2swf $joined_xmlfile $converted_swffile");

        }
    }
}


