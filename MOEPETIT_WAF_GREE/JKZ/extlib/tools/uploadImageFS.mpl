#!/usr/bin/perl -w -I /home/vhosts/JKZ
#********************************************
# @desc		画像アップローダー Directory格納タイプ
# @package	uploadBannerImage
# @access	public
# @author	磐長谷　亮
# @create	2006/11/10
# @version	1.00
#********************************************

use strict;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use File::Basename;
my $q = CGI->new();

use vars qw($Directory $Url_Path);



my $id1 = $q->param('id1');
my $id2 = $q->param('id2');
my $status_flag = $q->param('status_flag');

my ($carrier, $sex, $personality, $bloodtype, $occupation, $prefecture);

map { $carrier += 2 ** $_ } split(/;/, q->param('carrier'));
map { $sex += 2 ** $_ } split(/;/, q->param('sex'));
map { $personality += 2 ** $_ } split(/;/, q->param('personality'));
map { $bloodtype += 2 ** $_ } split(/;/, q->param('bloodtype'));
map { $occupation += 2 ** $_ } split(/;/, q->param('occupation'));
map { $prefecture += 2 ** $_ } split(/;/, q->param('prefecture'));

my $banner_url = q->param('banner_url');
my $banner_text = q->param('banner_text');


# @return	obj $obj->{Index} $obj->{Value}
# Loop . $name . List

my $carrierlist = $self->_getValuesFromConf("CARRIER");
my $sexlist = $self->_getValuesFromConf("SEX");
my $personalitylist = $self->_getValuesFromConf("PERSONALITY");
my $bloodtypelist = $self->_getValuesFromConf("BLOODTYPE");
my $occupationlist = $self->_getValuesFromConf("OCCUPATION");
my $prefecturelist = $self->_getValuesFromConf("PREFECTURE");

map { $tags->{$_} = $carrierlist->{$_} } %{$carrierlist};
map { $tags->{$_} = $sexlist->{$_} } %{$sexlist};
map { $tags->{$_} = $personalitylist->{$_} } %{$personalitylist};
map { $tags->{$_} = $bloodtypelist->{$_} } %{$bloodtypelist};
map { $tags->{$_} = $occupationlist->{$_} } %{$occupationlist};
map { $tags->{$_} = $prefecturelist->{$_} } %{$prefecturelist};




my $dirname = 'banner' . $id1;
$Directory ='/home/httpd/htdocs/img/' . $dirname . '/';


$Url_Path ="/~ryo/tools/images";

my @File_Names = $q->param('image');
my @File_Array = ();

$CGI::POST_MAX = 1024 * 100;	#一回のアップロード最大容量は100KBまで。ファイルは5つ

my $F_Array = Get_Names (\@File_Names, \@File_Array);

Print_Results ();


sub Get_Names {
	my ($File_Names, @File_Array) = @_;
	my $counter = 0;
	my $full_name;
	my $file_name;
	
	warn $q->Dump ();
	
	foreach $full_name (@{$File_Names}) {
		my $rec = {};
		if ($full_name ne "") {
			$file_name = Get_File_Name($full_name);
			$rec->{file_name} = $file_name;
			$rec->{full_name} = $full_name;
			push @File_Array, $rec;
			Store_File($full_name, $file_name);
		}
		$counter++;
	}
	return (\@File_Array);
}


sub Get_File_Name {
	if ($ENV{HTTP_USER_AGENT} =~ /win/i) {
		fileparse_set_fstype("MSDOS");
	}
	elsif ($ENV{HTTP_USER_AGENT} =~ /mac/i) {
		fileparse_set_fstype ("MacOS");
	}
	my $full_name = shift;
	$full_name = basename ($full_name);
	$full_name =~ s!\s!\_!g;		##--->スペースを取り除いてアンダーバーに入れ替え
	return ($full_name);
}

sub Store_File {
	my ($file_handle,$file_name) = @_;

	my $data;
	my $mime = $q->uploadInfo($file_handle)->{'Content-Type'};
	
	open (STORAGE, ">$Directory/$file_name") or die "Error: $Directory/$file_name $!\n";
	if ($mime !~ /text/) {
		binmode ($file_handle);
		binmode (STORAGE);
	}
	while( read($file_handle, $data, 1024) ) { print STORAGE $data; }
	close STORAGE;
}

sub Print_Results {
	my $temp;
	print $q->header(-charset=>'shift_jis');
	print $q->start_html("画像アップロード");
	print qq(<h2>現在アップロード済みのファイル：</h2>);
	foreach $temp (@File_Array) {
		my $link = "$Url_Path/$temp->{file_name}";
		
		print <<EOF;
		<PRE>
			<B>File名：</B>		$temp->{file_name}
			<B>File説明：</B>	$temp->{description}
			<B>Fileリンク：</B>	<A HREF="$link">$link</A><P>
		</PRE>
EOF
	}
	print qq(\n<A HREF="viewfiles.mpl">画像確認</A>);
	print $q->end_html ();
}






#******************************************************
# @desc		画像サイズを変換してファイルシステムに保存する
# @package	convertImages_local.pl
# @access	public
# @author	Iwahase Ryo
# @create	2006/11/27
# @version	1.00
#******************************************************
use strict;
eval ("use less;"); die "[err] less がインストールされてません。 \n" if $@;
eval ("use Image::Magick;"); die "[err] Image::Magick がインストールされてません。 \n" if $@;


die "Usage: $0 image_file [ image_name ]\n" unless @ARGV >= 1 && @ARGV <= 2;
my $image_file = shift (@ARGV);
my $image_name = shift (@ARGV);
($image_name = $image_file) =~ s|.*/|| if !defined $image_name;

my %mime_map = (
	"gif" => "image/gif",
	"jpg" => "image/jpeg",
	"jpeg" => "image/jpeg",
	"jpe" => "image/pjpeg",
	"png" => "image/png"
);
my $mime_type = $mime_map{lc ($1)} if $image_file =~ /\.([^.]+)$/;
die "Cannot determine image MIME type\n" if !defined $mime_type;


my $mime_ext;
if ($image_file =~ /\.([^.]+)$/) { $mime_ext = $1; }

my $img = Image::Magick->new;
my ($err, $image_data);

$err = $img->Read ($image_file);
die "Can't read image file: $err\n" if $err;
$image_data = $img->ImageToBlob ();

$err = $img->Scale (geometry => "400x400");
die "Can't scale image file: $err\n" if $err;
my $img_new = $image_name . '400.' . $mime_ext;
$img->Write ($img_new);

#$err = $img->Scale (geometry => "200x200");
$err = $img->Scale (geometry => "130x162");
die "Can't scale image file: $err\n" if $err;
$img_new = $image_name . '200.' . $mime_ext;
$img_new = $img->Fx(expression=>'(g+b)/2.0',channel=>'red');
$img->Normalize(channel=>"All");
$img->Write (filename=>$img_new);

$err = $img->Scale (geometry => "64x64");
die "Can't scale image file: $err\n" if $err;
$img_new = $image_name . '64.' . $mime_ext;
$img->Write ($img_new);

$err = $img->Scale (geometry => "40x40");
die "Can't scale image file: $err\n" if $err;
$img_new = $image_name . '40.' . $mime_ext;
$img->Write ($img_new);


exit (0);