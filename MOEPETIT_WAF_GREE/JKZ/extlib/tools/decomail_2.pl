#!/usr/bin/perl

###
#デコメールの配信
#HTML＋画像添付
#Content-Typeはmultipart/mixedで送信します。添付ファイルは、GIF・JPG・SWFファイルが利用できます。

use strict;
use MIME::Lite;
use Jcode;
use Path::Class;

my $text = 'お誕生日おめでとう';
my $html = <<'';
<html>
<body>
<font color="#FF0000">お誕生日おめでとう</font>
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

# 添付する画像ファイル（base64でエンコード）
my $image = MIME::Lite->new(
    Type => 'image/gif; name="cake.gif"',
    Data => scalar file('.', 'cake.gif')->slurp,
    Encoding => 'base64',
);

my $msg = MIME::Lite->new(
    Type     => 'multipart/mixed',
    Subject  => 'Happy Birthday!!',
#    From     => '送信元アドレス',
#    To       => '送信先アドレス',
    From     => 'mobasen-test@jokerz.org',
    To       => 'assiette.yokohama.02@ezweb.ne.jp',
    Encoding => '8bit',
);

$msg->attach($body);
$msg->attach($image);
$msg->send;
