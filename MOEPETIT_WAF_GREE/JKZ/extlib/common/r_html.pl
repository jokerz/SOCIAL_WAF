##### #/usr/bin/perl

sub ReplaceHTML{
my $str;
	($str) = @_;
	
	$_ = $str;
	
	
	#�g�p�p�x�̍���������ϊ�
#	s/"/&quot;/g;
	s/&/&amp;/g;
	s/</&lt;/g;
	s/>/&gt;/g;
	s/ /&nbsp;/g;
	
	#���s�R�[�h��<body>�֕ϊ�
	s/\n/<body>/g;

	$str = $_;
	return $str;
}1;

sub ReplaceHTMLTextArea{
my $str;
	($str) = @_;
	
	$_ = $str;
	
	
	#�g�p�p�x�̍���������ϊ�
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
		#�G�X�P�[�v�����ɂ���
		s/&/&amp;/g;
		s/"/&quot;/g;
	}
	else{
		#�G�X�P�[�v���������ɖ߂�
		s/&quot;/"/g;
		s/&amp;/&/g;
	}

	$str = $_;
	return $str;
}1;
