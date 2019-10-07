##########################
#画像アップローダー
#
#
##########################

use strict;
use Site::KoiConfig ($HASHTB);
use CGI::Carp qw(fatalsToBrowser);
use File::Basename;
my $q = new CGI;
#my $Directory ="/home/kensho/www/bnrimg";

use vars qw($Directory $Url_Path);
#$Directory ="http://goku.wim.jp/bnrimg";
$Directory ="192.168.6.10/bnr_images";
$Url_Path ="/bnr_images";

my @File_Names = $q->param('image');
#my @Bnr_Ids = $q->param('bnr_id');
my $Bnr_Ids = $q->param('bnr_id');

my @File_Array = ();

$CGI::POST_MAX = 1024 * 100;	#一回のアップロード最大容量は100KBまで。ファイルは5つ

my $F_Array = Get_Names(\@File_Names,$Bnr_Ids,@File_Array);
Store_Descriptions($F_Array);
Print_Results();


sub Get_Names {
	my ($File_Names,$Bnr_Ids,@File_Array) = @_;
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
			#現状は１つづつだから良い
			#$rec->{bnr_id} = $Bnr_Ids->[$counter];
			$rec->{bnr_id} = $Bnr_Ids;
			warn "$rec->{bnr_id} $Bnr_Ids\n";
			push @File_Array, $rec;
			Store_File($full_name, $file_name);
		}
		$counter++;
	}
	return (\@File_Array);
}

sub Store_Descriptions {
	my $file = shift;
	my $temp;
	my $DBH = UsrWebDB::connect ("kcommon");
	my $sth_update = $DBH->prepare( qq{UPDATE $HASHTB->{BNR} SET image=? WHERE bnr_id=?} );
	foreach $temp (@{$file}) {
		warn " $temp->{file_name}, $temp->{bnr_id}";
		$sth_update->execute( $temp->{file_name}, $temp->{bnr_id} );
	}
	$DBH->disconnect ();
}

sub Get_File_Name {
	if ($ENV{HTTP_USER_AGENT} =~ /win/i) {
		fileparse_set_fstype("MSDOS");
	}
	elsif ($ENV{HTTP_USER_AGENT} =~ /mac/i) {
		fileparse_set_fstype("MacOS");
	}
	my $full_name = shift;
	$full_name = basename($full_name);
	$full_name =~ s!\s!\_!g;		##--->スペースを取り除いてアンダーバーに入れ替え
	return($full_name);
}

sub Store_File {
	my ($file_handle,$file_name) = @_;

	my $data;
	my $mime = $q->uploadInfo($file_handle)->{'Content-Type'};
	
	open(STORAGE, ">$Directory/$file_name") or die "Error: $!\n";
	if ($mime !~ /text/) {
		binmode ($file_handle);
		binmode (STORAGE);
	}
	while( read($file_handle, $data, 1024) ) { print STORAGE $data; }
	close STORAGE;
}

sub Print_Results {

	print $q->redirect(-url=>"./rtbnr.mpl",-target=>"main");
	ModPerl::Util::exit ();

#	my $temp;
#	print $q->header(-charset=>'shift_jis');
#	print $q->start_html("HS画像アップロード");
#	print qq(<h2>現在アップロード済みのファイル：</h2>);
#	foreach $temp (@File_Array) {
#		my $link = "$Url_Path/$temp->{file_name}";
		
#		print <<EOF;
#		<PRE>
#			<B>File名：</B>		$temp->{file_name}
#			<B>File説明：</B>	$temp->{description}
#			<B>Fileリンク：</B>	<A HREF="$link">$link</A><P>
#		</PRE>
#EOF
#	}
#	print qq(\n<A HREF="viewfiles.mpl">画像確認</A>);
#	print $q->end_html ();
}
