#!/usr/bin/perl

#****************************************************
# @desc		�A�t�B���G�C�g�p�\�P�b�g�ʐM
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

# HTTP�v���g�R���̃o�[�W����
$http = '1.1';

# �v���L�V�T�[�o�̐ݒ�
#$proxy_host = 'XXX.XXX.XXX.XXX';
#$proxy_port = 8080;


# �f�t�H���g�z�X�g�̐ݒ�
$host = 'localhost';
$port = getservbyname('http', 'tcp');
$path = '/';

# URL��͏���

#**********************************
#
# �A�t�B���{
# id	����ID(���[�U�[�����������Ă���)
# a		�L��ID(�Œ�l)
# u		�N���C�A���g���(���R64�o�C�g�܂�)
# m		���i��
# p		���i�P��
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
  # �v���L�V�T�[�o�o�R
  $con_host = $proxy_host;
  $con_port = $proxy_port;
  $url		= $arg;

} else {
  $con_host = $host;
  $con_port = $port;
  $url		= $path;
}


# �\�P�b�g�̐���
$ip = inet_aton($con_host) || die "host($con_host) not found.\n";

warn "\n>>>>>>>>>>\n $ip \n $con_host \n";

$sockaddr = pack_sockaddr_in($con_port, $ip);

warn "\n>>>>>>>>>>\n $con_port \n $ip \n";


socket(SOCKET, PF_INET, SOCK_STREAM, 0) || die "socket error.\n";

# �\�P�b�g�̐ڑ�
connect(SOCKET, $sockaddr) || die "connect $con_host $con_port error.\n";
autoflush SOCKET (1);

# HTTP�v���𑗐M
if ($http eq '1.1') {
  print SOCKET "GET $url HTTP/1.1\n";
  print SOCKET "Host: $host\n";
  print SOCKET "Connection: close\n\n";

} else {
  print SOCKET "GET $url HTTP/1.0\n\n";
}

# HTTP��������M
while (chomp($buf=<SOCKET>)) {
  print "$buf\n";
}

# �I������
close(SOCKET);
