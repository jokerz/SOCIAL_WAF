#!/usr/bin/perl

###
#�f�R���[���̔z�M
#HTML�݂̂�MIME�t�H�[�}�b�g�͉��L�̂悤�ɂȂ�܂��B
#�}1�FHTML�݂̂̏ꍇ
#Content-Type��multipart/alternative�Ƃ��āATEXT�p�[�g��HTML�p�[�g�𑗐M���܂��B�f�R���[����Ή��[���ɂ́ATEXT�p�[�g�̂ݑ��M����邱�ƂɂȂ�܂��̂ŁA�K��TEXT�p�[�g������悤�ɂ��܂��傤�B

use strict;
use MIME::Lite;
use Jcode;

my $text = '���a�������߂łƂ�';
my $html = <<'';
<html>
<body>
<font color="#FF0000">���a�������߂łƂ�</font>
</body>
</html>

my $msg = MIME::Lite->new(
    Type     => 'multipart/alternative',
    Subject  => 'Happy Birthday!!',
    From     => '���M���A�h���X',
    To       => '���M��A�h���X',
    Encoding => '8bit',
);

# HTML�p�[�g�i�Ή��[���ɑ��M����镔���j
$msg->attach(
    Type => 'text/html',
    Data => Jcode->new($html)->sjis,
    Encoding => '8bit',
);

# TEXT�p�[�g�i��Ή��[���ɑ��M����镔���j
$msg->attach(
    Type => 'text/plain',
    Data => $text,
    Encoding => '8bit',
);

$msg->send;