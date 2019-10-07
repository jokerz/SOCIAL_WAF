#!/usr/bin/perl

###
#�f�R���[���̔z�M
#HTML�{�摜�Y�t
#Content-Type��multipart/mixed�ő��M���܂��B�Y�t�t�@�C���́AGIF�EJPG�ESWF�t�@�C�������p�ł��܂��B

use strict;
use MIME::Lite;
use Jcode;
use Path::Class;

my $text = '���a�������߂łƂ�';
my $html = <<'';
<html>
<body>
<font color="#FF0000">���a�������߂łƂ�</font>
</body>
</html>

my $body = MIME::Lite->new(
    Type => 'multipart/alternative',
);

$body->attach(
    Type => 'text/plain',
    Data => $text,
    Encoding => '8bit',
);

$body->attach(
    Type => 'text/html',
    Data => Jcode->new($html)->sjis,
    Encoding => '8bit',
);

# �Y�t����摜�t�@�C���ibase64�ŃG���R�[�h�j
my $image = MIME::Lite->new(
    Type => 'image/gif; name="cake.gif"',
    Data => scalar file('.', 'cake.gif')->slurp,
    Encoding => 'base64',
);

my $msg = MIME::Lite->new(
    Type     => 'multipart/mixed',
    Subject  => 'Happy Birthday!!',
#    From     => '���M���A�h���X',
#    To       => '���M��A�h���X',
    From     => 'mobasen-test@jokerz.org',
    To       => 'assiette.yokohama.02@ezweb.ne.jp',
    Encoding => '8bit',
);

$msg->attach($body);
$msg->attach($image);
$msg->send;
