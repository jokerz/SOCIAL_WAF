#!/usr/bin/perl

#****************************************************
# @desc		アフィリエイト用ソケット通信
# @package	affiliate_sock.pl
# @access	public
# @author	Iwahase Ryo
# @create	2009/07/03
# @update
# @version	1.00
#****************************************************


use strict;
use Socket;
use FileHandle;

my ($proxy_host, $proxy_port, $http);
my ($con_host, $con_port);
my ($host, $port, $url, $path, $ip, $sockaddr);
my ($arg, $buf);

($arg) = @ARGV;

# HTTPプロトコルのバージョン
$http = '1.1';

# プロキシサーバの設定
#$proxy_host = 'XXX.XXX.XXX.XXX';
#$proxy_port = 8080;


# デフォルトホストの設定
$host = 'localhost';
$port = getservbyname('http', 'tcp');
$path = '/';

# URL解析処理

#**********************************
#
# アフィレボ
# id	識別ID(ユーザーが引っ張ってくる)
# a		広告ID(固定値)
# u		クライアント情報(自由64バイトまで)
# m		商品数
# p		商品単価
#**********************************
#$arg = 'http://af-rv.jp/res.cgi?id=&a=&u=&m=&p='

#$arg =~ m!(http:)?(//)?([^:/]*)?(:([0-9]+)?)?(/.*)!;
$arg =~ m!(http:)?(//)?([^:/]*)?(:([0-9]+)?)?(/.*)?!;

if ($3) {$host = $3;}
if ($5) {$port = $5;}
if ($6) {$path = $6;}

## for dubug
$ENV{TZ} = 'Japan';
my ($secg,$ming,$hourg,$mdayg,$mong,$yearg,$wdayg,$ydayg,$isdstg) = localtime(time - 24*60*60);
my $exe_time = sprintf("[%04d %02d%02d %02d:%02d:%02d] [check socket]",$yearg +1900,$mong +1,$mdayg,$hourg,$ming,$secg);
warn $exe_time, "\nhost : ", $3,"\n","url  : ", $path, "\n";

#exit();

if ($proxy_host) {
  # プロキシサーバ経由
  $con_host = $proxy_host;
  $con_port = $proxy_port;
  $url		= $arg;

} else {
  $con_host = $host;
  $con_port = $port;
  $url		= $path;
}


# ソケットの生成
$ip = inet_aton($con_host) || die "host($con_host) not found.\n";

warn "\n>>>>>>>>>>\n $ip \n $con_host \n";

$sockaddr = pack_sockaddr_in($con_port, $ip);

warn "\n>>>>>>>>>>\n $con_port \n $ip \n";


socket(SOCKET, PF_INET, SOCK_STREAM, 0) || die "socket error.\n";

# ソケットの接続
connect(SOCKET, $sockaddr) || die "connect $con_host $con_port error.\n";
autoflush SOCKET (1);

# HTTP要求を送信
if ($http eq '1.1') {
  print SOCKET "GET $url HTTP/1.1\n";
  print SOCKET "Host: $host\n";
  print SOCKET "Connection: close\n\n";

} else {
  print SOCKET "GET $url HTTP/1.0\n\n";
}

# HTTP応答を受信
while (chomp($buf=<SOCKET>)) {
  print "$buf\n";
}

# 終了処理
close(SOCKET);
