##### #/usr/bin/perl

sub ReplaceHTML{
my $str;
	($str) = @_;
	
	$_ = $str;
	
	
	#使用頻度の高い文字を変換
#	s/"/&quot;/g;
	s/&/&amp;/g;
	s/</&lt;/g;
	s/>/&gt;/g;
	s/ /&nbsp;/g;
	
	#改行コードを<body>へ変換
	s/\n/<body>/g;

	$str = $_;
	return $str;
}1;

sub ReplaceHTMLTextArea{
my $str;
	($str) = @_;
	
	$_ = $str;
	
	
	#使用頻度の高い文字を変換
#	s/"/&quot;/g;
	s/&/&amp;/g;
	s/</&lt;/g;
	s/>/&gt;/g;
#	s/ /&nbsp;/g;
	
	$str = $_;
	return $str;
}1;

sub ReplaceHiddenData{
my $str;
my $mode;

	($str,$mode) = @_;
	
	$_ = $str;
	
	if($mode==1){
		#エスケープ文字にする
		s/&/&amp;/g;
		s/"/&quot;/g;
	}
	else{
		#エスケープ文字を元に戻す
		s/&quot;/"/g;
		s/&amp;/&/g;
	}

	$str = $_;
	return $str;
}1;
