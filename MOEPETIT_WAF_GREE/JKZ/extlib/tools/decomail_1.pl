#!/usr/bin/perl

###
#デコメールの配信
#HTMLのみのMIMEフォーマットは下記のようになります。
#図1：HTMLのみの場合
#Content-Typeをmultipart/alternativeとして、TEXTパートとHTMLパートを送信します。デコメール非対応端末には、TEXTパートのみ送信されることになりますので、必ずTEXTパートをつけるようにしましょう。

use strict;
use MIME::Lite;
use Jcode;

my $text = 'お誕生日おめでとう';
my $html = <<'';
<html>
<body>
<font color="#FF0000">お誕生日おめでとう</font>
</body>
</html>

my $msg = MIME::Lite->new(
    Type     => 'multipart/alternative',
    Subject  => 'Happy Birthday!!',
    From     => '送信元アドレス',
    To       => '送信先アドレス',
    Encoding => '8bit',
);

# HTMLパート（対応端末に送信される部分）
$msg->attach(
    Type => 'text/html',
    Data => Jcode->new($html)->sjis,
    Encoding => '8bit',
);

# TEXTパート（非対応端末に送信される部分）
$msg->attach(
    Type => 'text/plain',
    Data => $text,
    Encoding => '8bit',
);

$msg->send;