#**************************
#
# 画像表示スクリプト
# serveDegreeImageDB.mpl
# @access    public
# @author    Iwahase Ryo
# @create    2011/06/08
#**************************
use strict;
use vars qw($cfg);

BEGIN {
    my $config = $ENV{'MOEPETIT_CONFIG'};
    require MyClass::Config;
    $cfg = MyClass::Config->new($config);
}

use CGI;
use MyClass::UsrWebDB;

my $namespace   = $cfg->param('WAF_NAME_SPACE') . 'DegreeImageData';
my $q           = CGI->new();
my $s           = $q->param('s');
my $degree_id   = $q->param('di');

my @thumb       = (undef, 'image', 'resized_image');
my $col_name    = (defined ($s) ? $thumb[$s] : "resized_image");
my $key         = join (';', (int($degree_id), $col_name));
my $memcached   = MyClass::UsrWebDB::MemcacheInit();
my $obj         = $memcached->get("$namespace:$key");

if(!$obj) {
	my $dbh = MyClass::UsrWebDB::connect({
                 dbaccount => $cfg->param('DATABASE_USER'),
                 dbpasswd  => $cfg->param('DATABASE_PASSWORD'),
                 dbname    => $cfg->param('DATABASE_NAME'),
              });

    $dbh->do ('set names utf8');

    my $sql                      = sprintf("SELECT mime_type, %s FROM %s.tDegreeImageM WHERE degreem_id=?;", $col_name, $cfg->param('DATABASE_NAME'));
    my ($mime_type, $image_data) = $dbh->selectrow_array ($sql, undef, $degree_id);
    $dbh->disconnect();

    $obj = {
    mime_type => $mime_type,
    image_data=> $image_data,
    };
	$memcached->add("$namespace:$key", $obj, 3600);
}

print $q->header(-type=>$obj->{mime_type},-Content_Length=>length ($obj->{image_data}));
print $obj->{image_data};

ModPerl::Util::exit();

__END__