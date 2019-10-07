#!/usr/bin/perl -I/home/vhosts/MOEPETIT/JKZ

#use MyClass::LsAttr;
use Carp qw(confess);
use SWF::Header;
use MyClass::UsrWebDB;

#my $lsattr = JKZ::LsAttr->new();
#my @files = $lsattr->getFileList ("/home/vhosts/MOEPETIT/JKZ/tmp/xml2swf/test/flash", 0);

#*****************************************
# ファイル名の変更が必要 xxxxx:xxxx:xxx.swfはNGのため
#                        xxxxx_xxxx_xxx.swfに変換
# find ./ -type f -name '*.swf' | perl -pe 'chomp; $old = $_; s/(.*?)\:(.*?)\:(.*?)\.(swf)$/$1_$2_$3\.$4/; rename $old, $_;'
# find ./ -type f -name '*.swf' | perl -pe 'chomp; $old = $_; s/(.*?)_(.*?)_(.*?)\.(swf)$/$1:$2:$3\.$4/; rename $old, $_;'
#*****************************************


my $dir       = "/home/vhosts/MOEPETIT/JKZ/tmp/xml2swf/test/flash";
my $mime_type = 'application/x-shockwave-flash';

my $sqlMoji  = "REPLACE INTO dMOEPETIT.tTestContentsSwfM VALUES(?, ?, ?, ?, ?, ?);";
my $dbh = MyClass::UsrWebDB::connect();

my $cnt;
opendir DH, $dir or die "$dir:$!";
while (my $file = readdir DH) {
	next if $file =~ /^\.{1,2}$/;	# '.'や'..'も取れるので、スキップする
	print $file, "\n";
	$cnt++;

    open INFILE, '< ', $file or die "file open error $!\n!";
    binmode INFILE;

    my $file_size = (stat(INFILE))[7];
    my ($swfdata, $height, $width);

    (read(INFILE, $swfdata, -s $file) == -s INFILE)
        or confess ("Can't read data file: $!");

    my $header_data = SWF::Header->read_data($swfdata);
    $height = $header_data->{height};
    $width  = $header_data->{width};

    my $swf_id = $file =~ s/\.swf//;

    $dbh->do($sqlMoji, undef, $swf_id, $swfdata, $mime_type, $file_size, $height, $width);

    close INFILE;
=pod
    my $InsertData = {
        swf_id     => $file,
        swf        => $swfdata,
        mime_type  => $mime_type,
        file_size  => $file_size,
        height     => $height,
        width      => $width,
    };
=cut

last if 10==$cnt;

}
closedir DH;



$dbh->disconnect();

=pod
    

=cut