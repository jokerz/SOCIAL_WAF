#!/usr/bin/perl -I/home/vhosts/MOEPETIT/JKZ

#******************************************************
# $Id: loadSwfFromLocal.pl,v 1.0 2011/mm/dd RyoIwahase Exp $
# @desc      xmlから生成したローカルにあるswfをデータベースにINSERT
# 
# @package   
# @access    
# @author    Iwahase Ryo
# @create    yyyy/mm/dd
# @update    
# @version   1.0
#******************************************************

use Carp qw(confess);
use SWF::Header;
use MyClass::UsrWebDB;


#*****************************************
# xxxxx これの処理は不要→ ファイル名の変更が必要 xxxxx:xxxx:xxx.swfはNGのため 
#                        xxxxx_xxxx_xxx.swfに変換
# find ./ -type f -name '*.swf' | perl -pe 'chomp; $old = $_; s/(.*?)\:(.*?)\:(.*?)\.(swf)$/$1_$2_$3\.$4/; rename $old, $_;'
# find ./ -type f -name '*.swf' | perl -pe 'chomp; $old = $_; s/(.*?)_(.*?)_(.*?)\.(swf)$/$1:$2:$3\.$4/; rename $old, $_;'
#*****************************************


#my $dir       = "/home/vhosts/MOEPETIT/JKZ/tmp/xml2swf/test/flash";
my $dir       = "/home/vhosts/MOEPETIT/www.moepetit.jp/htdocs/flashtest";
my $mime_type = 'application/x-shockwave-flash';
my $sqlMoji   = "REPLACE INTO dMOEPETIT.tTestContentsSwfM VALUES(?, ?, ?, ?, ?, ?);";
my $dbh       = MyClass::UsrWebDB::connect();

my $cnt;
opendir DH, $dir or die "$dir:$!";
while (my $file_name = readdir DH) {
    next if $file_name =~ /^\.{1,2}$/;    # '.'や'..'も取れるので、スキップする
    print $file_name, " TO "; ## DEBUG
    my $swf_id = $file_name;
    $cnt++;
    my $file = sprintf("%s/%s", $dir, $file_name);
    open INFILE, '< ', $file or die "file open error $!\n!";
    binmode INFILE;

    my $file_size = (stat(INFILE))[7];
    my ($swfdata, $height, $width);

    (read(INFILE, $swfdata, -s $file) == -s INFILE)
        or confess ("Can't read data file: $!");

    my $header_data = SWF::Header->read_data($swfdata);
    $height = $header_data->{height};
    $width  = $header_data->{width};

    #my $swf_id =~ s/\.swf//;

    $swf_id =~ s/(.*?)\.swf/$1/;
    print $swf_id," INSERTING TO DATABASE \n";

    $dbh->do($sqlMoji, undef, $swf_id, $swfdata, $mime_type, $file_size, $height, $width);

    close INFILE;
    $cnt++;
}
closedir DH;

$dbh->disconnect();

print $cnt;

