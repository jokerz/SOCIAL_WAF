#******************************************************
# @desc      携帯位置登録情報からドコモのエリアコードを利用して地域情報を出す
# @desc      経度・緯度からメッシュを計算して、ドコモのエリアコードを割り出す。
# @desc      
# @desc      figureout_from_areacode
# @desc      figureout_from_GeoIP
# @desc      
# @desc      
# @desc      
# @package   JKZ::Ichi::iArea
# @access    public
# @author    Iwahase Ryo
# @create    2010/06/24
# @update    2010/
# @version    1.00
#******************************************************
package JKZ::Ichi::iArea;

use 5.008005;
our $VERSION = '1.00';

use strict;
use warnings;


use Location::GeoTool;
use JKZ::Ichi::iArea::Area;
require JKZ::Ichi::iArea::Region;

sub figureout_from_areacode {
    my $class = shift;
    my ($area,$sub_area) = @_;

    if ($area =~ /^(\d{3})(\d{2})$/) {
        $area = $1;
        $sub_area = $2;
    }
    elsif (!(($area =~ /^\d{3}$/) && ($sub_area =~ /^\d{2}$/))) {
        return undef;
    }

    return bless JKZ::Ichi::iArea::Area->seek("$area$sub_area"),$class;
}


sub figureout_from_GeoIP {
    my $class = shift;
    my $mesh  = $class->calcurate_mesh(@_);

    return bless JKZ::Ichi::iArea::Area->seek($mesh),$class;
}



#******************************************************
# @desc     メッシュ計算
# @param    
# @param    
# @return   
#******************************************************
sub calcurate_mesh {
    my $class = shift;
    my ($lat,$lon,$usetokyo,$format) = @_;

    if (UNIVERSAL::isa($lat, 'Location::GeoTool')) {
        ($lat,$lon) = $lat->datum_tokyo->format_second->array;
    }
    else {
        my $datum = $usetokyo || 'wgs84';
        $datum = 'tokyo' if ($datum eq '1');
        $format ||= 'spacetag';
       ($lat,$lon) = Location::GeoTool->create_coord($lat,$lon,$datum,$format)->datum_tokyo->format_second->array;
    }

    ($lat,$lon) = map { int ($_ * 1000) } ($lat,$lon);

    my @mesh = ();
    my $ab = int($lat / 2400000);
    my $cd = int($lon / 3600000) - 100;
    my $x1 = ($cd +100) * 3600000;
    my $y1 = $ab * 2400000;
    my $e = int(($lat - $y1) / 300000);
    my $f = int(($lon - $x1) / 450000);
    $mesh[0] = $ab.$cd.$e.$f;
    my $x2 = $x1 + $f * 450000;
    my $y2 = $y1 + $e * 300000;
    my $l3 = int(($lon - $x2) / 225000);
    my $m3 = int(($lat - $y2) / 150000);
    my $g = $l3 + $m3 * 2;
    $mesh[1] = $mesh[0].$g;  
    my $x3 = $x2 + $l3 * 225000;
    my $y3 = $y2 + $m3 * 150000;
    my $l4 = int(($lon - $x3) / 112500);
    my $m4 = int(($lat - $y3) / 75000);
    my $h = $l4 + $m4 * 2;
    $mesh[2] = $mesh[1].$h;  
    my $x4 = $x3 + $l4 * 112500;
    my $y4 = $y3 + $m4 * 75000;
    my $l5 = int(($lon - $x4) / 56250);
    my $m5 = int(($lat - $y4) / 37500);
    my $i = $l5 + $m5 * 2;
    $mesh[3] = $mesh[2].$i;  
    my $x5 = $x4 + $l5 * 56250;
    my $y5 = $y4 + $m5 * 37500;
    my $l6 = int(($lon - $x5) / 28125);
    my $m6 = int(($lat - $y5) / 18750);
    my $j = $l6 + $m6 * 2;
    $mesh[4] = $mesh[3].$j;
    my $x6 = $x5 + $l6 * 28125;
    my $y6 = $y5 + $m6 * 18750;
    my $l7 = int(($lon - $x6) / 14062.5);
    my $m7 = int(($lat - $y6) / 9375);
    my $k = $l7 + $m7 * 2;
    $mesh[5] = $mesh[4].$k;

   return $mesh[5];

}


sub areaid {
    my $self = shift;
    return $self->{areaid};
}


sub sub_areaid {
    my $self = shift;
    return $self->{sub_areaid};
}

#sub area {}
sub name {
    my $self = shift;
    return $self->{name};
}


sub areacode {$_[0]->id}

sub id { $_[0]->areaid().$_[0]->sub_areaid() }

sub prefecture {
    my $self = shift;
    unless ($self->{prefecture}) {
        ($self->{region},$self->{prefecture}) = JKZ::Ichi::iArea::Region->seek($self->{areaid},$self->{sub_areaid});
    }

    return $self->{prefecture};
}


sub region {
    my $self = shift;
    unless ($self->{region}) {
        ($self->{region},$self->{prefecture}) = JKZ::Ichi::iArea::Region->seek($self->{areaid},$self->{sub_areaid});
    }

  return $self->{region};
}



1;
__END__

