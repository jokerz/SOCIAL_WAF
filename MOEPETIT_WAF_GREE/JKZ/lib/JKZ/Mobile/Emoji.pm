#******************************************************
# @desc      携帯絵文字変換
# @desc      キャリア別に絵文字を16進数に変換
# @desc      16進数をキャリアの絵文字に変換
# @desc      相違するキャリアの絵文字相互変換
# @desc      
# @desc      
# @desc      
# @package   JKZ::Mobile::Emoji
# @access    public
# @author    Iwahase Ryo
# @create    2010/07/08
# @update    2010/
# @version   1.00
#******************************************************
package JKZ::Mobile::Emoji;

use 5.008005;
our $VERSION = '1.00';

use strict;
use warnings;


use vars qw($MobileAgentREGEX $EMOJI_HEX);

my $DoCoMoREGEX           = '^DoCoMo/\d\.\d[ /]';
my $JPhoneREGEX           = '^(?i:J-PHONE/\d\.\d)';
my $VodafoneREGEX         = '^Vodafone/\d\.\d';
my $VodafoneMotREGEX      = '^MOT-';
my $SoftBankREGEX         = '^SoftBank/\d\.\d';
my $SoftBankCrawlerREGEX  = '^Nokia[^/]+/\d\.\d';
my $KDDIREGEX            = '^(?:KDDI-[A-Z]+\d+[A-Z]? )?UP\.Browser\/';
my $AirHREGEX             = '^Mozilla/3\.0\((?:WILLCOM|DDIPOCKET)\;';
#$MobileAgentREGEX         = qr/(?:($DoCoMoREGEX)|($JPhoneREGEX|$VodafoneREGEX|$VodafoneMotREGEX|$SoftBankREGEX|$SoftBankCrawlerREGEX)|($KDDIREGEX)|($AirHREGEX))/;
# EMOJI_HEXの配列の順番を間違えたためここでAU＝２ SoftBanｋを3にした
$MobileAgentREGEX         = qr/(?:($DoCoMoREGEX)|($KDDIREGEX)|($JPhoneREGEX|$VodafoneREGEX|$VodafoneMotREGEX|$SoftBankREGEX|$SoftBankCrawlerREGEX)|($AirHREGEX))/;

=pod
sub new {
    my $class = shift;
}
=cut



sub carrier_code {

    my $agent = $ENV{'HTTP_USER_AGENT'};
    if ( $agent =~ /$MobileAgentREGEX/ ) {
         return ( $1 ? 1 : $2 ? 2 : $3 ? 3 : 0 );
    }
}

=pod
sub carrier_name {

    my @carriers = qw( docomo softbank kddi );

}
=cut

#******************************************************
# @access   
# @desc     
# @param    
# @param    
# @return   
#******************************************************
sub emoji2hex {
    #my $self = shift;
    my $text = shift;
    return if "" eq $text;

    my $carrier_code = &carrier_code();
    my @carriers     = qw( docomo kddi softbank );
    my $carrier      = $carriers[ $carrier_code - 1 ];

    my $docomo_emoji_regex   = qr/([\xF8\xF9][\x40-\x7E\x80-\xFC]|[\xF9][\x40-\x49\x50-\x52\x55-\x57\x5B-\x5E\x72-\xFB])/;
    my $softbank_emoji_regex = qr/([\x1B][\x24][G|E|F|O|P|Q][\x21-\x7E]+[\x0F])/;
    my $kddi_emoji_regex     = qr/([\xF3\xF6\xF7][\x40-\xFC]|[\xF4][\x40-\x8D])/;

    $text =~ s/($docomo_emoji_regex|$softbank_emoji_regex|$kddi_emoji_regex)/'[' . $carrier . ':' . unpack("H*", $1) . ']'/ego;
    return $text;

}


#******************************************************
# @access   
# @desc     
# @param    
# @param    
# @return   
#******************************************************
sub hex2emoji {
    my $text = shift;
    return if $text eq "";

    my $carrier_code = &carrier_code();
    $carrier_code = $carrier_code - 1;
   ## テキストの16進数を絵文字に戻す。
    $text =~ s/\[(docomo\:|kddi\:|softbank\:)(f.{3})\]/pack("H4", $EMOJI_HEX->{$1 . $2}->[$carrier_code])/eg;

    return $text; 
  ## 次にキャリアが違う場合は
}



$EMOJI_HEX = {
'docomo:f89f' => ['f89f','f660','f98b'],
'docomo:f8a0' => ['f8a0','f665','f98a'],
'docomo:f8a1' => ['f8a1','f664','f98c'],
'docomo:f8a2' => ['f8a2','f65d','f989'],
'docomo:f8a3' => ['f8a3','f65f','f77d'],
'docomo:f8a4' => ['f8a4','f641','fb84'],
'docomo:f8a6' => ['f8a6','f3bc','fb7c'],
'docomo:f957' => ['f957','f3c5','fb8c'],
'docomo:f89f' => ['f89f','f3c8','f98e'],
#'docomo:f89f' => ['f89f','f3c8','fb8a'],
#'docomo:f89f' => ['f89f','f34d','fb8b'],
'docomo:f666' => ['f666','f98b','f98a'],
'docomo:f957' => ['f957','f698','fb8c'],
'docomo:f9e4' => ['f9e4','f481','fb7e'],
'docomo:f957' => ['f957','f463','fb8c'],
'docomo:f941' => ['f941','f7c6','f98d'],
'docomo:f942' => ['f942','f7c7','f98d'],
'docomo:f943' => ['f943','f65e','f98d'],
'docomo:f942' => ['f942','f661','f98d'],
'docomo:f95e' => ['f95e','f7b1','f964'],
#'docomo:f95e' => ['f95e','f7b1','f965'],
#'docomo:f95e' => ['f95e','f7b1','f966'],
#'docomo:f95e' => ['f95e','f7b1','f967'],
#'docomo:f95e' => ['f95e','f7b1','f968'],
#'docomo:f95e' => ['f95e','f7b1','f969'],
#'docomo:f95e' => ['f95e','f7b1','f96a'],
#'docomo:f95e' => ['f95e','f7b1','f96b'],
#'docomo:f95e' => ['f95e','f7b1','f96c'],
#'docomo:f95e' => ['f95e','f7b1','f96d'],
#'docomo:f95e' => ['f95e','f7b1','f96e'],
#'docomo:f95e' => ['f95e','f7b1','f96f'],
'docomo:f95e' => ['f95e','f7b1','f96d'],
'docomo:f8a7' => ['f8a7','f667','f7df'],
'docomo:f8a8' => ['f8a8','f668','f7e0'],
'docomo:f8a9' => ['f8a9','f669','f7e1'],
'docomo:f8aa' => ['f8aa','f66a','f7e2'],
'docomo:f8ab' => ['f8ab','f66b','f7e3'],
'docomo:f8ac' => ['f8ac','f66c','f7e4'],
'docomo:f8ad' => ['f8ad','f66d','f7e5'],
'docomo:f8ae' => ['f8ae','f66e','f7e6'],
'docomo:f8af' => ['f8af','f66f','f7e7'],
'docomo:f8b0' => ['f8b0','f670','f7e8'],
'docomo:f8b1' => ['f8b1','f671','f7e9'],
'docomo:f8b2' => ['f8b2','f672','f7ea'],
'docomo:f9e6' => ['f9e6','f6ec','f750'],
'docomo:f9e8' => ['f9e8','f6bd','f9a4'],
'docomo:f9eb' => ['f9eb','f482','f750'],
'docomo:f9ec' => ['f9ec','f6a7','f758'],
'docomo:f9ed' => ['f9ed','f6a3','f970'],
'docomo:f9ec' => ['f9ec','f340','f759'],
'docomo:f9e6' => ['f9e6','f487','f750'],
'docomo:f9ea' => ['f9ea','f38d','f9e5'],
'docomo:f9ea' => ['f9ea','f45e','f9e5'],
'docomo:f8f2' => ['f8f2','f7c1','fb59'],
'docomo:f8f3' => ['f8f3','f7c2','fb5b'],
'docomo:f99e' => ['f99e','f3a5','fb5c'],
'docomo:f9cd' => ['f9cd','f44b','fb49'],
'docomo:f9b5' => ['f9b5','f6e2','f9bc'],
'docomo:f8d6' => ['f8d6','f374','f9bf'],
'docomo:f995' => ['f995','f6d5','f941'],
#'docomo:f995' => ['f995','f6d3','f942'],
#'docomo:f995' => ['f995','f6d5','f944'],
#'docomo:f995' => ['f995','f6d3','f945'],
'docomo:f9f9' => ['f9f9','f6b1','f774'],
'docomo:f9f6' => ['f9f6','f3de','fbc2'],
'docomo:f9f6' => ['f9f6','f6ac','f959'],
#'docomo:f9f4' => ['f9f4','f6b9','fbc3'],
#'docomo:f9f4' => ['f9f4','f47a','fbc3'],
#'docomo:f9f4' => ['f9f4','f6b9','fbc1'],
'docomo:f9f4' => ['f9f4','f34e','fbc3'],
'docomo:f9f5' => ['f9f5','f6b5','f996'],
'docomo:f945' => ['f945','f6b8','f993'],
'docomo:f9f6' => ['f9f6','f672','f959'],
'docomo:f946' => ['f946','f6b4','f990'],
'docomo:f9f9' => ['f9f9','f6b1','f95a'],
'docomo:f945' => ['f945','f6ba','f993'],
'docomo:f9fa' => ['f9fa','f6b7','f74b'],
'docomo:f945' => ['f945','f6ba','fbca'],
'docomo:f8f9' => ['f8f9','f6c7','fbd6'],
'docomo:f9fa' => ['f9fa','f44c','f74b'],
'docomo:f996' => ['f996','f64a','f99a'],
'docomo:f998' => ['f998','f46b','fb43'],
'docomo:f999' => ['f999','f39e','fb50'],
'docomo:f997' => ['f997','f394','f999'],
'docomo:f999' => ['f999','f7cb','fb46'],
'docomo:f9c8' => ['f9c8','f39f','fb4f'],
'docomo:f9ca' => ['f9ca','f39d','fb4e'],
'docomo:f9cb' => ['f9cb','f7f4','f746'],
'docomo:f9f8' => ['f9f8','f395','fb44'],
'docomo:f9cd' => ['f9cd','f6c0','f745'],
#'docomo:f9cd' => ['f9cd','f6c0','fb49'],
'docomo:f9f7' => ['f9f7','f3a1','f997'],
'docomo:f9cb' => ['f9cb','f3a3','fb58'],
#'docomo:f9cb' => ['f9cb','f3a2','fb57'],
'docomo:f9cf' => ['f9cf','f39c','fb4d'],
'docomo:f995' => ['f995','f649','f998'],
'docomo:f7ce' => ['f7ce','fb55','f9d1'],
'docomo:f9cf' => ['f9cf','f399','fb4a'],
'docomo:f9f8' => ['f9f8','f485','fb44'],
'docomo:f9cf' => ['f9cf','f468','fb52'],
'docomo:f995' => ['f995','f3a1','f997'],
#'docomo:f995' => ['f995','f6d4','fb54'],
#'docomo:f995' => ['f995','f3a1','f997'],
#'docomo:f995' => ['f995','f649','fb55'],
'docomo:f9d3' => ['f9d3','f46d','fb53'],
'docomo:f9d2' => ['f9d2','f64b','fb51'],
'docomo:f9fc' => ['f9fc','f39a','fb4b'],
'docomo:f9d0' => ['f9d0','f396','fb46'],
'docomo:f9c9' => ['f9c9','f461','fb56'],
'docomo:f9c6' => ['f9c6','f399','fb4a'],
'docomo:f998' => ['f998','f397','fb47'],
'docomo:f9c5' => ['f9c5','f394','fb43'],
'docomo:f9fc' => ['f9fc','f7f5','f747'],
'docomo:f9a6' => ['f9a6','f398','fb48'],
'docomo:f9d1' => ['f9d1','f393','fb42'],
'docomo:f9c8' => ['f9c8','f7f6','f748'],
'docomo:f9c8' => ['f9c8','f7f6','fb41'],
'docomo:f9d0' => ['f9d0','f64c','fb46'],
'docomo:f9ce' => ['f9ce','f7f3','fb45'],
'docomo:f995' => ['f995','f465','f998'],
'docomo:f9f8' => ['f9f8','f484','fb44'],
'docomo:f9cf' => ['f9cf','f467','fb52'],
'docomo:f9cb' => ['f9cb','f464','fb58'],
'docomo:f9cb' => ['f9cb','f469','f746'],
'docomo:f9d3' => ['f9d3','f46c','fb53'],
'docomo:f9c9' => ['f9c9','f462','fb56'],
'docomo:f9f8' => ['f9f8','f46e','fb44'],
'docomo:f998' => ['f998','f46a','fb43'],
'docomo:f9d4' => ['f9d4','f3ab','fb63'],
'docomo:f9b0' => ['f9b0','f3ac','fb64'],
'docomo:f998' => ['f998','f48c','fb43'],
'docomo:f996' => ['f996','f48d','fb56'],
'docomo:f8c4' => ['f8c4','f684','f976'],
'docomo:f8c4' => ['f8c4','f7e0','f976'],
'docomo:f8c5' => ['f8c5','f686','f978'],
'docomo:f8c6' => ['f8c6','f351','f794'],
'docomo:f8c7' => ['f8c7','f352','f796'],
'docomo:f8c8' => ['f8c8','f683','f78e'],
'docomo:f8c9' => ['f8c9','f67b','f795'],
'docomo:f8ca' => ['f8ca','f354','f799'],
'docomo:f994' => ['f994','f3c7','fba1'],
'docomo:f8cb' => ['f8cb','f67c','f797'],
'docomo:f9e3' => ['f9e3','f353','f798'],
'docomo:f8c2' => ['f8c2','f682','f7a2'],
'docomo:f9f0' => ['f9f0','f696','f9ab'],
'docomo:f9e5' => ['f9e5','f7ed','f97b'],
'docomo:f8fa' => ['f8fa','f7e7','f947'],
'docomo:f8fa' => ['f8fa','f3ec','f947'],
'docomo:f8d5' => ['f8d5','f6f3','f77e'],
'docomo:f8d5' => ['f8d5','f6f3','f9ba'],
'docomo:f8f9' => ['f8f9','f3eb','fbd6'],
'docomo:f9b3' => ['f9b3','f7e6','f946'],
'docomo:f9bf' => ['f9bf','f7f9','f74e'],
'docomo:f9b3' => ['f9b3','f6e6','f946'],
'docomo:f8e3' => ['f8e3','f674','f9c3'],
'docomo:f9ba' => ['f9ba','f6a0','f76f'],
'docomo:f9ba' => ['f9ba','f796','f76f'],
'docomo:f9ba' => ['f9ba','f7a2','f76f'],
'docomo:f9bf' => ['f9bf','f7f9','f971'],
'docomo:f8e5' => ['f8e5','f7bc','f9b4'],
'docomo:f8e6' => ['f8e6','f6a8','f752'],
'docomo:f8e7' => ['f8e7','f7bd','f9eb'],
'docomo:f948' => ['f948','f6a2','f973'],
'docomo:f8e8' => ['f8e8','f7b3','f949'],
#'docomo:f8e8' => ['f8e8','f6f7','f949'],
'docomo:f8e9' => ['f8e9','f7a5','f94a'],
'docomo:f972' => ['f972','f7df','f744'],
'docomo:f8ea' => ['f8ea','f365','f9a1'],
'docomo:f974' => ['f974','f6f9','f94b'],
'docomo:f977' => ['f977','f6fa','f743'],
'docomo:f973' => ['f973','f7ae','f743'],
'docomo:f973' => ['f973','f466','f743'],
'docomo:f8c6' => ['f8c6','f6f4','f741'],
'docomo:f8c6' => ['f8c6','f7e1','f741'],
'docomo:f8c6' => ['f8c6','f6f4','f742'],
'docomo:f8e6' => ['f8e6','f6f8','f752'],
'docomo:f977' => ['f977','f475','f743'],
'docomo:f9bb' => ['f9bb','f7e8','f94c'],
'docomo:f9be' => ['f9be','f679','f9a1'],
'docomo:f8e3' => ['f8e3','f341','f75e'],
'docomo:f8ed' => ['f8ed','f6e5','f766'],
'docomo:f8ed' => ['f8ed','f6e5','f767'],
'docomo:f8d6' => ['f8d6','f6ef','f9b3'],
'docomo:f8ea' => ['f8ea','f77d','f9a1'],
'docomo:f8ea' => ['f8ea','f786','f9a1'],
'docomo:f8e4' => ['f8e4','f788','f789'],
'docomo:f8e4' => ['f8e4','f677','f789'],
'docomo:f8e4' => ['f8e4','f675','f789'],
'docomo:f8e4' => ['f8e4','f785','f789'],
'docomo:f8e4' => ['f8e4','f782','f789'],
'docomo:f8e4' => ['f8e4','f783','f789'],
'docomo:f8e4' => ['f8e4','f784','f789'],
'docomo:f8e4' => ['f8e4','f78c','f789'],
'docomo:f8ea' => ['f8ea','f781','f9a1'],
'docomo:f8e4' => ['f8e4','f789','f789'],
'docomo:f8e4' => ['f8e4','f78b','f789'],
'docomo:f8ea' => ['f8ea','f7e2','f9a1'],
'docomo:f8b4' => ['f8b4','f693','f956'],
'docomo:f8b5' => ['f8b5','f7b6','f954'],
'docomo:f8b6' => ['f8b6','f690','f955'],
'docomo:f8b7' => ['f8b7','f68f','f958'],
'docomo:f8b8' => ['f8b8','f380','f953'],
'docomo:f8b9' => ['f8b9','f7b7','fb6a'],
'docomo:f8ba' => ['f8ba','f692','f772'],
'docomo:f9d8' => ['f9d8','f643','f755'],
'docomo:f9b7' => ['f9b7','f445','f957'],
'docomo:f8bc' => ['f8bc','f68e','f95e'],
'docomo:f8bd' => ['f8bd','f7ec','fb74'],
'docomo:f8bd' => ['f8bd','f7ec','fb74'],
'docomo:f8be' => ['f8be','f689','fb75'],
'docomo:f8be' => ['f8be','f689','f95f'],
'docomo:f8bf' => ['f8bf','f68a','f95b'],
'docomo:f8c0' => ['f8c0','f68a','fb6e'],
'docomo:f8c1' => ['f8c1','f688','f79a'],
'docomo:f8c2' => ['f8c2','f355','f7a2'],
'docomo:f8c3' => ['f8c3','f68c','f95d'],
'docomo:f947' => ['f947','f68d','f95c'],
'docomo:f947' => ['f947','f68d','f775'],
'docomo:f8bf' => ['f8bf','f68a','f79b'],
'docomo:f8cc' => ['f8cc','f78e','f97a'],
'docomo:f8cd' => ['f8cd','f67e','f790'],
'docomo:f8ce' => ['f8ce','f642','f78f'],
'docomo:f99c' => ['f99c','f695','f763'],
'docomo:f9f6' => ['f9f6','f446','f959'],
'docomo:f8d7' => ['f8d7','f6dc','f97c'],
'docomo:f8d8' => ['f8d8','f6f0','f97d'],
'docomo:f8d8' => ['f8d8','f6f0','fba7'],
'docomo:f8db' => ['f8db','f6e1','f9aa'],
'docomo:f8dc' => ['f8dc','f7b9','fba2'],
'docomo:f8dd' => ['f8dd','f3c9','fba3'],
'docomo:f8df' => ['f8df','f676','f765'],
'docomo:f950' => ['f950','f697','f9c4'],
'docomo:f99b' => ['f99b','f7ee','f97e'],
'docomo:f9a4' => ['f9a4','f6de','f9c6'],
'docomo:f9a4' => ['f9a4','f3a0','f9c6'],
'docomo:f8e2' => ['f8e2','f6ee','f948'],
'docomo:f8d8' => ['f8d8','f79b','f97d'],
'docomo:f8eb' => ['f8eb','f6db','f76a'],
'docomo:f99e' => ['f99e','f6c4','f943'],
'docomo:f47c' => ['f47c','f743','f9c8'],
'docomo:f9c0' => ['f9c0','f6ed','f974'],
'docomo:f9c0' => ['f9c0','f6ed','f975'],
'docomo:f99e' => ['f99e','f7fa','f751'],
'docomo:f992' => ['f992','f3ae','fb65'],
'docomo:f9d6' => ['f9d6','f774','f7ee'],
'docomo:f9db' => ['f9db','f775','f7ef'],
'docomo:f9d7' => ['f9d7','f76a','fbd7'],
'docomo:f985' => ['f985','f489','f7b0'],
'docomo:f987' => ['f987','f6fb','f7bc'],
'docomo:f988' => ['f988','f6fc','f7bd'],
'docomo:f989' => ['f989','f740','f7be'],
'docomo:f98a' => ['f98a','f741','f7bf'],
'docomo:f98b' => ['f98b','f742','f7c0'],
'docomo:f98c' => ['f98c','f743','f7c1'],
'docomo:f98d' => ['f98d','f744','f7c2'],
'docomo:f98e' => ['f98e','f745','f7c3'],
'docomo:f98f' => ['f98f','f746','f7c4'],
'docomo:f990' => ['f990','f7c9','f7c5'],
'docomo:f8d4' => ['f8d4','f6af','f760'],
'docomo:f9ee' => ['f9ee','f6ae','f9e2'],
'docomo:f9ef' => ['f9ef','f6a9','f987'],
'docomo:f9f1' => ['f9f1','f7d1','f9e0'],
'docomo:f9f2' => ['f9f2','f383','f9d9'],
'docomo:f9f1' => ['f9f1','f388','f9de'],
'docomo:f8d0' => ['f8d0','f685','f984'],
'docomo:f8d1' => ['f8d1','f7b4','f986'],
'docomo:f8d2' => ['f8d2','f69b','f985'],
'docomo:f8d3' => ['f8d3','f69c','f988'],
'docomo:f9c3' => ['f9c3','f382','f9d8'],
'docomo:f9f0' => ['f9f0','f36a','f9ab'],
'docomo:f9fb' => ['f9fb','f69a','f985'],
'docomo:f8d3' => ['f8d3','f36b','f9ac'],
'docomo:f8d2' => ['f8d2','f442','f985'],
'docomo:f8d9' => ['f8d9','f771','f7d6'],
'docomo:f8f7' => ['f8f7','f769','f7d8'],
'docomo:f8f8' => ['f8f8','f768','f7d7'],
'docomo:f949' => ['f949','f772','f7d9'],
'docomo:f99a' => ['f99a','f3ee','f7d6'],
'docomo:f9a5' => ['f9a5','f3ef','f7d8'],
'docomo:f944' => ['f944','f381','f9d2'],
'docomo:f9a7' => ['f9a7','f65a','f961'],
'docomo:f9a7' => ['f9a7','f65a','f9d7'],
'docomo:f991' => ['f991','f7b2','f962'],
'docomo:f992' => ['f992','f479','f9c7'],
'docomo:f993' => ['f993','f64f','f963'],
'docomo:f994' => ['f994','f650','f9c7'],
'docomo:f991' => ['f991','f379','f9c7'],
'docomo:f992' => ['f992','f479','f9c8'],
'docomo:f991' => ['f991','f6c3','f9c9'],
'docomo:f991' => ['f991','f37a','f9ca'],
'docomo:f991' => ['f991','f37b','f9cb'],
'docomo:f991' => ['f991','f37c','f9cc'],
'docomo:f991' => ['f991','f37d','f9cd'],
'docomo:f991' => ['f991','f458','fb77'],
'docomo:f992' => ['f992','f7cc','f9c7'],
'docomo:f99d' => ['f99d','f7b2','f7a4'],
'docomo:f8ee' => ['f8ee','f378','f7ac'],
'docomo:f8ef' => ['f8ef','f7be','f7ae'],
'docomo:f8f0' => ['f8f0','f7bf','f7ad'],
'docomo:f8f1' => ['f8f1','f7c0','f7af'],
'docomo:f8e0' => ['f8e0','f655','f9ae'],
'docomo:f8e1' => ['f8e1','f656','f7a8'],
'docomo:f8fc' => ['f8fc','f657','f7aa'],
'docomo:f9dc' => ['f9dc','f659','f7f2'],
'docomo:f9d4' => ['f9d4','f65c','f777'],
'docomo:f9c2' => ['f9c2','f687','f776'],
'docomo:f9d8' => ['f9d8','f476','f7a1'],
'docomo:f99c' => ['f99c','f34b','f780'],
'docomo:f8cf' => ['f8cf','f67d','f792'],
'docomo:f8cf' => ['f8cf','f67d','f781'],
'docomo:f8cf' => ['f8cf','f67d','f9a9'],
'docomo:f97c' => ['f97c','f35b','f7c9'],
'docomo:f982' => ['f982','f7e5','f7b2'],
'docomo:f9b0' => ['f9b0','f7ca','f7ed'],
'docomo:f9de' => ['f9de','f35d','f7cb'],
'docomo:f9e0' => ['f9e0','f35c','f7ca'],
'docomo:f9d9' => ['f9d9','f6ca','f9b5'],
'docomo:f9a0' => ['f9a0','f64e','f74f'],
'docomo:f9a1' => ['f9a1','f6be','f9d4'],
'docomo:f9a3' => ['f9a3','f652','f9b1'],
'docomo:f9a6' => ['f9a6','f64d','f77c'],
'docomo:f9ab' => ['f9ab','f7ce','f9d1'],
'docomo:f9ac' => ['f9ac','f6bf','f9d1'],
'docomo:f9ad' => ['f9ad','f6cd','f9d0'],
'docomo:f99f' => ['f99f','f37e','f9ce'],
'docomo:f99d' => ['f99d','f651','f7a5'],
'docomo:f99d' => ['f99d','f75a','f7a6'],
'docomo:f940' => ['f940','f756','f7b9'],
'docomo:f940' => ['f940','f757','f7b9'],
'docomo:f940' => ['f940','f766','f7b9'],
'docomo:f940' => ['f940','f767','f7ba'],
'docomo:f940' => ['f940','f767','f7ba'],
'docomo:f940' => ['f940','f767','f7bb'],
'docomo:f99f' => ['f99f','f644','f9ce'],
'docomo:f981' => ['f981','f6f1','f754'],
'docomo:f981' => ['f981','f7dc','f754'],
'docomo:f97d' => ['f97d','f6f5','f785'],
'docomo:f97d' => ['f97d','f6f5','f786'],
'docomo:f97d' => ['f97d','f7e3','f785'],
'docomo:f97d' => ['f97d','f7d3','f785'],
'docomo:f97d' => ['f97d','f6f2','f980'],
'docomo:f9b8' => ['f9b8','f6eb','f9c5'],
'docomo:f8f4' => ['f8f4','f488','f950'],
'docomo:f8f6' => ['f8f6','f7c4','f952'],
'docomo:f8f5' => ['f8f5','f7c3','f951'],
'docomo:f9a2' => ['f9a2','f6cc','f94d'],
'docomo:f9cc' => ['f9cc','f6d2','f94e'],
'docomo:f8f6' => ['f8f6','f3aa','fb5e'],
'docomo:f9b0' => ['f9b0','f3a8','fb60'],
'docomo:f9a5' => ['f9a5','f3a9','fb61'],
'docomo:f8f6' => ['f8f6','f3aa','fb62'],
'docomo:f953' => ['f953','f6f0','f97d'],
'kddi:f660' => ['f89f','f660','f98b'],
'kddi:f665' => ['f8a0','f665','f98a'],
'kddi:f664' => ['f8a1','f664','f98c'],
'kddi:f65d' => ['f8a2','f65d','f989'],
'kddi:f65f' => ['f8a3','f65f','f77d'],
'kddi:f641' => ['f8a4','f641','fb84'],
'kddi:f3bc' => ['f8a6','f3bc','fb7c'],
'kddi:f3c5' => ['f957','f3c5','fb8c'],
'kddi:f3c8' => ['f89f','f3c8','f98e'],
'kddi:f3c8' => ['f89f','f3c8','fb8a'],
'kddi:f34d' => ['f89f','f34d','fb8b'],
'kddi:f98b' => ['f666','f98b','f98a'],
'kddi:f698' => ['f957','f698','fb8c'],
'kddi:f481' => ['f9e4','f481','fb7e'],
'kddi:f463' => ['f957','f463','fb8c'],
'kddi:f7c6' => ['f941','f7c6','f98d'],
'kddi:f7c7' => ['f942','f7c7','f98d'],
'kddi:f65e' => ['f943','f65e','f98d'],
'kddi:f661' => ['f942','f661','f98d'],
'kddi:f7b1' => ['f95e','f7b1','f964'],
#'kddi:f7b1' => ['f95e','f7b1','f965'],
#'kddi:f7b1' => ['f95e','f7b1','f966'],
#'kddi:f7b1' => ['f95e','f7b1','f967'],
#'kddi:f7b1' => ['f95e','f7b1','f968'],
#'kddi:f7b1' => ['f95e','f7b1','f969'],
#'kddi:f7b1' => ['f95e','f7b1','f96a'],
#'kddi:f7b1' => ['f95e','f7b1','f96b'],
#'kddi:f7b1' => ['f95e','f7b1','f96c'],
#'kddi:f7b1' => ['f95e','f7b1','f96d'],
#'kddi:f7b1' => ['f95e','f7b1','f96e'],
#'kddi:f7b1' => ['f95e','f7b1','f96f'],
#'kddi:f7b1' => ['f95e','f7b1','f96d'],
'kddi:f667' => ['f8a7','f667','f7df'],
'kddi:f668' => ['f8a8','f668','f7e0'],
'kddi:f669' => ['f8a9','f669','f7e1'],
'kddi:f66a' => ['f8aa','f66a','f7e2'],
'kddi:f66b' => ['f8ab','f66b','f7e3'],
'kddi:f66c' => ['f8ac','f66c','f7e4'],
'kddi:f66d' => ['f8ad','f66d','f7e5'],
'kddi:f66e' => ['f8ae','f66e','f7e6'],
'kddi:f66f' => ['f8af','f66f','f7e7'],
'kddi:f670' => ['f8b0','f670','f7e8'],
'kddi:f671' => ['f8b1','f671','f7e9'],
'kddi:f672' => ['f8b2','f672','f7ea'],
'kddi:f6ec' => ['f9e6','f6ec','f750'],
'kddi:f6bd' => ['f9e8','f6bd','f9a4'],
'kddi:f482' => ['f9eb','f482','f750'],
'kddi:f6a7' => ['f9ec','f6a7','f758'],
'kddi:f6a3' => ['f9ed','f6a3','f970'],
'kddi:f340' => ['f9ec','f340','f759'],
'kddi:f487' => ['f9e6','f487','f750'],
'kddi:f38d' => ['f9ea','f38d','f9e5'],
'kddi:f45e' => ['f9ea','f45e','f9e5'],
'kddi:f7c1' => ['f8f2','f7c1','fb59'],
'kddi:f7c2' => ['f8f3','f7c2','fb5b'],
'kddi:f3a5' => ['f99e','f3a5','fb5c'],
'kddi:f44b' => ['f9cd','f44b','fb49'],
'kddi:f6e2' => ['f9b5','f6e2','f9bc'],
'kddi:f374' => ['f8d6','f374','f9bf'],
'kddi:f6d5' => ['f995','f6d5','f941'],
'kddi:f6d3' => ['f995','f6d3','f942'],
'kddi:f6d5' => ['f995','f6d5','f944'],
'kddi:f6d3' => ['f995','f6d3','f945'],
'kddi:f6b1' => ['f9f9','f6b1','f774'],
'kddi:f3de' => ['f9f6','f3de','fbc2'],
'kddi:f6ac' => ['f9f6','f6ac','f959'],
'kddi:f6b9' => ['f9f4','f6b9','fbc3'],
'kddi:f47a' => ['f9f4','f47a','fbc3'],
'kddi:f6b9' => ['f9f4','f6b9','fbc1'],
'kddi:f34e' => ['f9f4','f34e','fbc3'],
'kddi:f6b5' => ['f9f5','f6b5','f996'],
'kddi:f6b8' => ['f945','f6b8','f993'],
'kddi:f672' => ['f9f6','f672','f959'],
'kddi:f6b4' => ['f946','f6b4','f990'],
'kddi:f6b1' => ['f9f9','f6b1','f95a'],
'kddi:f6ba' => ['f945','f6ba','f993'],
'kddi:f6b7' => ['f9fa','f6b7','f74b'],
'kddi:f6ba' => ['f945','f6ba','fbca'],
'kddi:f6c7' => ['f8f9','f6c7','fbd6'],
'kddi:f44c' => ['f9fa','f44c','f74b'],
'kddi:f64a' => ['f996','f64a','f99a'],
'kddi:f46b' => ['f998','f46b','fb43'],
'kddi:f39e' => ['f999','f39e','fb50'],
'kddi:f394' => ['f997','f394','f999'],
'kddi:f7cb' => ['f999','f7cb','fb46'],
'kddi:f39f' => ['f9c8','f39f','fb4f'],
'kddi:f39d' => ['f9ca','f39d','fb4e'],
'kddi:f7f4' => ['f9cb','f7f4','f746'],
'kddi:f395' => ['f9f8','f395','fb44'],
'kddi:f6c0' => ['f9cd','f6c0','f745'],
'kddi:f6c0' => ['f9cd','f6c0','fb49'],
'kddi:f3a1' => ['f9f7','f3a1','f997'],
'kddi:f3a3' => ['f9cb','f3a3','fb58'],
'kddi:f3a2' => ['f9cb','f3a2','fb57'],
'kddi:f39c' => ['f9cf','f39c','fb4d'],
'kddi:f649' => ['f995','f649','f998'],
'kddi:fb55' => ['f7ce','fb55','f9d1'],
'kddi:f399' => ['f9cf','f399','fb4a'],
'kddi:f485' => ['f9f8','f485','fb44'],
'kddi:f468' => ['f9cf','f468','fb52'],
'kddi:f3a1' => ['f995','f3a1','f997'],
'kddi:f6d4' => ['f995','f6d4','fb54'],
'kddi:f3a1' => ['f995','f3a1','f997'],
'kddi:f649' => ['f995','f649','fb55'],
'kddi:f46d' => ['f9d3','f46d','fb53'],
'kddi:f64b' => ['f9d2','f64b','fb51'],
'kddi:f39a' => ['f9fc','f39a','fb4b'],
'kddi:f396' => ['f9d0','f396','fb46'],
'kddi:f461' => ['f9c9','f461','fb56'],
'kddi:f399' => ['f9c6','f399','fb4a'],
'kddi:f397' => ['f998','f397','fb47'],
'kddi:f394' => ['f9c5','f394','fb43'],
'kddi:f7f5' => ['f9fc','f7f5','f747'],
'kddi:f398' => ['f9a6','f398','fb48'],
'kddi:f393' => ['f9d1','f393','fb42'],
'kddi:f7f6' => ['f9c8','f7f6','f748'],
#'kddi:f7f6' => ['f9c8','f7f6','fb41'],
'kddi:f64c' => ['f9d0','f64c','fb46'],
'kddi:f7f3' => ['f9ce','f7f3','fb45'],
'kddi:f465' => ['f995','f465','f998'],
'kddi:f484' => ['f9f8','f484','fb44'],
'kddi:f467' => ['f9cf','f467','fb52'],
'kddi:f464' => ['f9cb','f464','fb58'],
'kddi:f469' => ['f9cb','f469','f746'],
'kddi:f46c' => ['f9d3','f46c','fb53'],
'kddi:f462' => ['f9c9','f462','fb56'],
'kddi:f46e' => ['f9f8','f46e','fb44'],
'kddi:f46a' => ['f998','f46a','fb43'],
'kddi:f3ab' => ['f9d4','f3ab','fb63'],
'kddi:f3ac' => ['f9b0','f3ac','fb64'],
'kddi:f48c' => ['f998','f48c','fb43'],
'kddi:f48d' => ['f996','f48d','fb56'],
'kddi:f684' => ['f8c4','f684','f976'],
'kddi:f7e0' => ['f8c4','f7e0','f976'],
'kddi:f686' => ['f8c5','f686','f978'],
'kddi:f351' => ['f8c6','f351','f794'],
'kddi:f352' => ['f8c7','f352','f796'],
'kddi:f683' => ['f8c8','f683','f78e'],
'kddi:f67b' => ['f8c9','f67b','f795'],
'kddi:f354' => ['f8ca','f354','f799'],
'kddi:f3c7' => ['f994','f3c7','fba1'],
'kddi:f67c' => ['f8cb','f67c','f797'],
'kddi:f353' => ['f9e3','f353','f798'],
'kddi:f682' => ['f8c2','f682','f7a2'],
'kddi:f696' => ['f9f0','f696','f9ab'],
'kddi:f7ed' => ['f9e5','f7ed','f97b'],
'kddi:f7e7' => ['f8fa','f7e7','f947'],
'kddi:f3ec' => ['f8fa','f3ec','f947'],
'kddi:f6f3' => ['f8d5','f6f3','f77e'],
'kddi:f6f3' => ['f8d5','f6f3','f9ba'],
'kddi:f3eb' => ['f8f9','f3eb','fbd6'],
'kddi:f7e6' => ['f9b3','f7e6','f946'],
'kddi:f7f9' => ['f9bf','f7f9','f74e'],
'kddi:f6e6' => ['f9b3','f6e6','f946'],
'kddi:f674' => ['f8e3','f674','f9c3'],
'kddi:f6a0' => ['f9ba','f6a0','f76f'],
'kddi:f796' => ['f9ba','f796','f76f'],
'kddi:f7a2' => ['f9ba','f7a2','f76f'],
'kddi:f7f9' => ['f9bf','f7f9','f971'],
'kddi:f7bc' => ['f8e5','f7bc','f9b4'],
'kddi:f6a8' => ['f8e6','f6a8','f752'],
'kddi:f7bd' => ['f8e7','f7bd','f9eb'],
'kddi:f6a2' => ['f948','f6a2','f973'],
'kddi:f7b3' => ['f8e8','f7b3','f949'],
'kddi:f6f7' => ['f8e8','f6f7','f949'],
'kddi:f7a5' => ['f8e9','f7a5','f94a'],
'kddi:f7df' => ['f972','f7df','f744'],
'kddi:f365' => ['f8ea','f365','f9a1'],
'kddi:f6f9' => ['f974','f6f9','f94b'],
'kddi:f6fa' => ['f977','f6fa','f743'],
'kddi:f7ae' => ['f973','f7ae','f743'],
'kddi:f466' => ['f973','f466','f743'],
'kddi:f6f4' => ['f8c6','f6f4','f741'],
'kddi:f7e1' => ['f8c6','f7e1','f741'],
'kddi:f6f4' => ['f8c6','f6f4','f742'],
'kddi:f6f8' => ['f8e6','f6f8','f752'],
'kddi:f475' => ['f977','f475','f743'],
'kddi:f7e8' => ['f9bb','f7e8','f94c'],
'kddi:f679' => ['f9be','f679','f9a1'],
'kddi:f341' => ['f8e3','f341','f75e'],
'kddi:f6e5' => ['f8ed','f6e5','f766'],
'kddi:f6e5' => ['f8ed','f6e5','f767'],
'kddi:f6ef' => ['f8d6','f6ef','f9b3'],
'kddi:f77d' => ['f8ea','f77d','f9a1'],
'kddi:f786' => ['f8ea','f786','f9a1'],
'kddi:f788' => ['f8e4','f788','f789'],
'kddi:f677' => ['f8e4','f677','f789'],
'kddi:f675' => ['f8e4','f675','f789'],
'kddi:f785' => ['f8e4','f785','f789'],
'kddi:f782' => ['f8e4','f782','f789'],
'kddi:f783' => ['f8e4','f783','f789'],
'kddi:f784' => ['f8e4','f784','f789'],
'kddi:f78c' => ['f8e4','f78c','f789'],
'kddi:f781' => ['f8ea','f781','f9a1'],
'kddi:f789' => ['f8e4','f789','f789'],
'kddi:f78b' => ['f8e4','f78b','f789'],
'kddi:f7e2' => ['f8ea','f7e2','f9a1'],
'kddi:f693' => ['f8b4','f693','f956'],
'kddi:f7b6' => ['f8b5','f7b6','f954'],
'kddi:f690' => ['f8b6','f690','f955'],
'kddi:f68f' => ['f8b7','f68f','f958'],
'kddi:f380' => ['f8b8','f380','f953'],
'kddi:f7b7' => ['f8b9','f7b7','fb6a'],
'kddi:f692' => ['f8ba','f692','f772'],
'kddi:f643' => ['f9d8','f643','f755'],
'kddi:f445' => ['f9b7','f445','f957'],
'kddi:f68e' => ['f8bc','f68e','f95e'],
'kddi:f7ec' => ['f8bd','f7ec','fb74'],
#'kddi:f7ec' => ['f8bd','f7ec','fb74'],
'kddi:f689' => ['f8be','f689','fb75'],
#'kddi:f689' => ['f8be','f689','f95f'],
'kddi:f68a' => ['f8bf','f68a','f95b'],
'kddi:f68a' => ['f8c0','f68a','fb6e'],
'kddi:f688' => ['f8c1','f688','f79a'],
'kddi:f355' => ['f8c2','f355','f7a2'],
'kddi:f68c' => ['f8c3','f68c','f95d'],
'kddi:f68d' => ['f947','f68d','f95c'],
#'kddi:f68d' => ['f947','f68d','f775'],
'kddi:f68a' => ['f8bf','f68a','f79b'],
'kddi:f78e' => ['f8cc','f78e','f97a'],
'kddi:f67e' => ['f8cd','f67e','f790'],
'kddi:f642' => ['f8ce','f642','f78f'],
'kddi:f695' => ['f99c','f695','f763'],
'kddi:f446' => ['f9f6','f446','f959'],
'kddi:f6dc' => ['f8d7','f6dc','f97c'],
'kddi:f6f0' => ['f8d8','f6f0','f97d'],
#'kddi:f6f0' => ['f8d8','f6f0','fba7'],
'kddi:f6e1' => ['f8db','f6e1','f9aa'],
'kddi:f7b9' => ['f8dc','f7b9','fba2'],
'kddi:f3c9' => ['f8dd','f3c9','fba3'],
'kddi:f676' => ['f8df','f676','f765'],
'kddi:f697' => ['f950','f697','f9c4'],
'kddi:f7ee' => ['f99b','f7ee','f97e'],
'kddi:f6de' => ['f9a4','f6de','f9c6'],
'kddi:f3a0' => ['f9a4','f3a0','f9c6'],
'kddi:f6ee' => ['f8e2','f6ee','f948'],
'kddi:f79b' => ['f8d8','f79b','f97d'],
'kddi:f6db' => ['f8eb','f6db','f76a'],
'kddi:f6c4' => ['f99e','f6c4','f943'],
'kddi:f743' => ['f47c','f743','f9c8'],
'kddi:f6ed' => ['f9c0','f6ed','f974'],
'kddi:f6ed' => ['f9c0','f6ed','f975'],
'kddi:f7fa' => ['f99e','f7fa','f751'],
'kddi:f3ae' => ['f992','f3ae','fb65'],
'kddi:f774' => ['f9d6','f774','f7ee'],
'kddi:f775' => ['f9db','f775','f7ef'],
'kddi:f76a' => ['f9d7','f76a','fbd7'],
'kddi:f489' => ['f985','f489','f7b0'],
'kddi:f6fb' => ['f987','f6fb','f7bc'],
'kddi:f6fc' => ['f988','f6fc','f7bd'],
'kddi:f740' => ['f989','f740','f7be'],
'kddi:f741' => ['f98a','f741','f7bf'],
'kddi:f742' => ['f98b','f742','f7c0'],
'kddi:f743' => ['f98c','f743','f7c1'],
'kddi:f744' => ['f98d','f744','f7c2'],
'kddi:f745' => ['f98e','f745','f7c3'],
'kddi:f746' => ['f98f','f746','f7c4'],
'kddi:f7c9' => ['f990','f7c9','f7c5'],
'kddi:f6af' => ['f8d4','f6af','f760'],
'kddi:f6ae' => ['f9ee','f6ae','f9e2'],
'kddi:f6a9' => ['f9ef','f6a9','f987'],
'kddi:f7d1' => ['f9f1','f7d1','f9e0'],
'kddi:f383' => ['f9f2','f383','f9d9'],
'kddi:f388' => ['f9f1','f388','f9de'],
'kddi:f685' => ['f8d0','f685','f984'],
'kddi:f7b4' => ['f8d1','f7b4','f986'],
'kddi:f69b' => ['f8d2','f69b','f985'],
'kddi:f69c' => ['f8d3','f69c','f988'],
'kddi:f382' => ['f9c3','f382','f9d8'],
'kddi:f36a' => ['f9f0','f36a','f9ab'],
'kddi:f69a' => ['f9fb','f69a','f985'],
'kddi:f36b' => ['f8d3','f36b','f9ac'],
'kddi:f442' => ['f8d2','f442','f985'],
'kddi:f771' => ['f8d9','f771','f7d6'],
'kddi:f769' => ['f8f7','f769','f7d8'],
'kddi:f768' => ['f8f8','f768','f7d7'],
'kddi:f772' => ['f949','f772','f7d9'],
'kddi:f3ee' => ['f99a','f3ee','f7d6'],
'kddi:f3ef' => ['f9a5','f3ef','f7d8'],
'kddi:f381' => ['f944','f381','f9d2'],
'kddi:f65a' => ['f9a7','f65a','f961'],
'kddi:f65a' => ['f9a7','f65a','f9d7'],
'kddi:f7b2' => ['f991','f7b2','f962'],
'kddi:f479' => ['f992','f479','f9c7'],
'kddi:f64f' => ['f993','f64f','f963'],
'kddi:f650' => ['f994','f650','f9c7'],
'kddi:f379' => ['f991','f379','f9c7'],
'kddi:f479' => ['f992','f479','f9c8'],
'kddi:f6c3' => ['f991','f6c3','f9c9'],
'kddi:f37a' => ['f991','f37a','f9ca'],
'kddi:f37b' => ['f991','f37b','f9cb'],
'kddi:f37c' => ['f991','f37c','f9cc'],
'kddi:f37d' => ['f991','f37d','f9cd'],
'kddi:f458' => ['f991','f458','fb77'],
'kddi:f7cc' => ['f992','f7cc','f9c7'],
'kddi:f7b2' => ['f99d','f7b2','f7a4'],
'kddi:f378' => ['f8ee','f378','f7ac'],
'kddi:f7be' => ['f8ef','f7be','f7ae'],
'kddi:f7bf' => ['f8f0','f7bf','f7ad'],
'kddi:f7c0' => ['f8f1','f7c0','f7af'],
'kddi:f655' => ['f8e0','f655','f9ae'],
'kddi:f656' => ['f8e1','f656','f7a8'],
'kddi:f657' => ['f8fc','f657','f7aa'],
'kddi:f659' => ['f9dc','f659','f7f2'],
'kddi:f65c' => ['f9d4','f65c','f777'],
'kddi:f687' => ['f9c2','f687','f776'],
'kddi:f476' => ['f9d8','f476','f7a1'],
'kddi:f34b' => ['f99c','f34b','f780'],
'kddi:f67d' => ['f8cf','f67d','f792'],
'kddi:f67d' => ['f8cf','f67d','f781'],
'kddi:f67d' => ['f8cf','f67d','f9a9'],
'kddi:f35b' => ['f97c','f35b','f7c9'],
'kddi:f7e5' => ['f982','f7e5','f7b2'],
'kddi:f7ca' => ['f9b0','f7ca','f7ed'],
'kddi:f35d' => ['f9de','f35d','f7cb'],
'kddi:f35c' => ['f9e0','f35c','f7ca'],
'kddi:f6ca' => ['f9d9','f6ca','f9b5'],
'kddi:f64e' => ['f9a0','f64e','f74f'],
'kddi:f6be' => ['f9a1','f6be','f9d4'],
'kddi:f652' => ['f9a3','f652','f9b1'],
'kddi:f64d' => ['f9a6','f64d','f77c'],
'kddi:f7ce' => ['f9ab','f7ce','f9d1'],
'kddi:f6bf' => ['f9ac','f6bf','f9d1'],
'kddi:f6cd' => ['f9ad','f6cd','f9d0'],
'kddi:f37e' => ['f99f','f37e','f9ce'],
'kddi:f651' => ['f99d','f651','f7a5'],
'kddi:f75a' => ['f99d','f75a','f7a6'],
'kddi:f756' => ['f940','f756','f7b9'],
'kddi:f757' => ['f940','f757','f7b9'],
'kddi:f766' => ['f940','f766','f7b9'],
'kddi:f767' => ['f940','f767','f7ba'],
'kddi:f767' => ['f940','f767','f7ba'],
'kddi:f767' => ['f940','f767','f7bb'],
'kddi:f644' => ['f99f','f644','f9ce'],
'kddi:f6f1' => ['f981','f6f1','f754'],
'kddi:f7dc' => ['f981','f7dc','f754'],
'kddi:f6f5' => ['f97d','f6f5','f785'],
'kddi:f6f5' => ['f97d','f6f5','f786'],
'kddi:f7e3' => ['f97d','f7e3','f785'],
'kddi:f7d3' => ['f97d','f7d3','f785'],
'kddi:f6f2' => ['f97d','f6f2','f980'],
'kddi:f6eb' => ['f9b8','f6eb','f9c5'],
'kddi:f488' => ['f8f4','f488','f950'],
'kddi:f7c4' => ['f8f6','f7c4','f952'],
'kddi:f7c3' => ['f8f5','f7c3','f951'],
'kddi:f6cc' => ['f9a2','f6cc','f94d'],
'kddi:f6d2' => ['f9cc','f6d2','f94e'],
'kddi:f3aa' => ['f8f6','f3aa','fb5e'],
'kddi:f3a8' => ['f9b0','f3a8','fb60'],
'kddi:f3a9' => ['f9a5','f3a9','fb61'],
'kddi:f3aa' => ['f8f6','f3aa','fb62'],
'kddi:f6f0' => ['f953','f6f0','f97d'],
'softbank:f98b' => ['f89f','f660','f98b'],
'softbank:f98a' => ['f8a0','f665','f98a'],
'softbank:f98c' => ['f8a1','f664','f98c'],
'softbank:f989' => ['f8a2','f65d','f989'],
'softbank:f77d' => ['f8a3','f65f','f77d'],
'softbank:fb84' => ['f8a4','f641','fb84'],
'softbank:fb7c' => ['f8a6','f3bc','fb7c'],
'softbank:fb8c' => ['f957','f3c5','fb8c'],
'softbank:f98e' => ['f89f','f3c8','f98e'],
'softbank:fb8a' => ['f89f','f3c8','fb8a'],
'softbank:fb8b' => ['f89f','f34d','fb8b'],
'softbank:f98a' => ['f666','f98b','f98a'],
'softbank:fb8c' => ['f957','f698','fb8c'],
'softbank:fb7e' => ['f9e4','f481','fb7e'],
'softbank:fb8c' => ['f957','f463','fb8c'],
'softbank:f98d' => ['f941','f7c6','f98d'],
'softbank:f98d' => ['f942','f7c7','f98d'],
'softbank:f98d' => ['f943','f65e','f98d'],
'softbank:f98d' => ['f942','f661','f98d'],
'softbank:f964' => ['f95e','f7b1','f964'],
'softbank:f965' => ['f95e','f7b1','f965'],
'softbank:f966' => ['f95e','f7b1','f966'],
'softbank:f967' => ['f95e','f7b1','f967'],
'softbank:f968' => ['f95e','f7b1','f968'],
'softbank:f969' => ['f95e','f7b1','f969'],
'softbank:f96a' => ['f95e','f7b1','f96a'],
'softbank:f96b' => ['f95e','f7b1','f96b'],
'softbank:f96c' => ['f95e','f7b1','f96c'],
'softbank:f96d' => ['f95e','f7b1','f96d'],
'softbank:f96e' => ['f95e','f7b1','f96e'],
'softbank:f96f' => ['f95e','f7b1','f96f'],
'softbank:f96d' => ['f95e','f7b1','f96d'],
'softbank:f7df' => ['f8a7','f667','f7df'],
'softbank:f7e0' => ['f8a8','f668','f7e0'],
'softbank:f7e1' => ['f8a9','f669','f7e1'],
'softbank:f7e2' => ['f8aa','f66a','f7e2'],
'softbank:f7e3' => ['f8ab','f66b','f7e3'],
'softbank:f7e4' => ['f8ac','f66c','f7e4'],
'softbank:f7e5' => ['f8ad','f66d','f7e5'],
'softbank:f7e6' => ['f8ae','f66e','f7e6'],
'softbank:f7e7' => ['f8af','f66f','f7e7'],
'softbank:f7e8' => ['f8b0','f670','f7e8'],
'softbank:f7e9' => ['f8b1','f671','f7e9'],
'softbank:f7ea' => ['f8b2','f672','f7ea'],
'softbank:f750' => ['f9e6','f6ec','f750'],
'softbank:f9a4' => ['f9e8','f6bd','f9a4'],
'softbank:f750' => ['f9eb','f482','f750'],
'softbank:f758' => ['f9ec','f6a7','f758'],
'softbank:f970' => ['f9ed','f6a3','f970'],
'softbank:f759' => ['f9ec','f340','f759'],
'softbank:f750' => ['f9e6','f487','f750'],
'softbank:f9e5' => ['f9ea','f38d','f9e5'],
'softbank:f9e5' => ['f9ea','f45e','f9e5'],
'softbank:fb59' => ['f8f2','f7c1','fb59'],
'softbank:fb5b' => ['f8f3','f7c2','fb5b'],
'softbank:fb5c' => ['f99e','f3a5','fb5c'],
'softbank:fb49' => ['f9cd','f44b','fb49'],
'softbank:f9bc' => ['f9b5','f6e2','f9bc'],
'softbank:f9bf' => ['f8d6','f374','f9bf'],
'softbank:f941' => ['f995','f6d5','f941'],
'softbank:f942' => ['f995','f6d3','f942'],
'softbank:f944' => ['f995','f6d5','f944'],
'softbank:f945' => ['f995','f6d3','f945'],
'softbank:f774' => ['f9f9','f6b1','f774'],
'softbank:fbc2' => ['f9f6','f3de','fbc2'],
'softbank:f959' => ['f9f6','f6ac','f959'],
'softbank:fbc3' => ['f9f4','f6b9','fbc3'],
'softbank:fbc3' => ['f9f4','f47a','fbc3'],
'softbank:fbc1' => ['f9f4','f6b9','fbc1'],
'softbank:fbc3' => ['f9f4','f34e','fbc3'],
'softbank:f996' => ['f9f5','f6b5','f996'],
'softbank:f993' => ['f945','f6b8','f993'],
'softbank:f959' => ['f9f6','f672','f959'],
'softbank:f990' => ['f946','f6b4','f990'],
'softbank:f95a' => ['f9f9','f6b1','f95a'],
'softbank:f993' => ['f945','f6ba','f993'],
'softbank:f74b' => ['f9fa','f6b7','f74b'],
'softbank:fbca' => ['f945','f6ba','fbca'],
'softbank:fbd6' => ['f8f9','f6c7','fbd6'],
'softbank:f74b' => ['f9fa','f44c','f74b'],
'softbank:f99a' => ['f996','f64a','f99a'],
'softbank:fb43' => ['f998','f46b','fb43'],
'softbank:fb50' => ['f999','f39e','fb50'],
'softbank:f999' => ['f997','f394','f999'],
'softbank:fb46' => ['f999','f7cb','fb46'],
'softbank:fb4f' => ['f9c8','f39f','fb4f'],
'softbank:fb4e' => ['f9ca','f39d','fb4e'],
'softbank:f746' => ['f9cb','f7f4','f746'],
'softbank:fb44' => ['f9f8','f395','fb44'],
'softbank:f745' => ['f9cd','f6c0','f745'],
'softbank:fb49' => ['f9cd','f6c0','fb49'],
'softbank:f997' => ['f9f7','f3a1','f997'],
'softbank:fb58' => ['f9cb','f3a3','fb58'],
'softbank:fb57' => ['f9cb','f3a2','fb57'],
'softbank:fb4d' => ['f9cf','f39c','fb4d'],
'softbank:f998' => ['f995','f649','f998'],
'softbank:f9d1' => ['f7ce','fb55','f9d1'],
'softbank:fb4a' => ['f9cf','f399','fb4a'],
'softbank:fb44' => ['f9f8','f485','fb44'],
'softbank:fb52' => ['f9cf','f468','fb52'],
'softbank:f997' => ['f995','f3a1','f997'],
'softbank:fb54' => ['f995','f6d4','fb54'],
'softbank:f997' => ['f995','f3a1','f997'],
'softbank:fb55' => ['f995','f649','fb55'],
'softbank:fb53' => ['f9d3','f46d','fb53'],
'softbank:fb51' => ['f9d2','f64b','fb51'],
'softbank:fb4b' => ['f9fc','f39a','fb4b'],
'softbank:fb46' => ['f9d0','f396','fb46'],
'softbank:fb56' => ['f9c9','f461','fb56'],
'softbank:fb4a' => ['f9c6','f399','fb4a'],
'softbank:fb47' => ['f998','f397','fb47'],
'softbank:fb43' => ['f9c5','f394','fb43'],
'softbank:f747' => ['f9fc','f7f5','f747'],
'softbank:fb48' => ['f9a6','f398','fb48'],
'softbank:fb42' => ['f9d1','f393','fb42'],
'softbank:f748' => ['f9c8','f7f6','f748'],
'softbank:fb41' => ['f9c8','f7f6','fb41'],
'softbank:fb46' => ['f9d0','f64c','fb46'],
'softbank:fb45' => ['f9ce','f7f3','fb45'],
'softbank:f998' => ['f995','f465','f998'],
'softbank:fb44' => ['f9f8','f484','fb44'],
'softbank:fb52' => ['f9cf','f467','fb52'],
'softbank:fb58' => ['f9cb','f464','fb58'],
'softbank:f746' => ['f9cb','f469','f746'],
'softbank:fb53' => ['f9d3','f46c','fb53'],
'softbank:fb56' => ['f9c9','f462','fb56'],
'softbank:fb44' => ['f9f8','f46e','fb44'],
'softbank:fb43' => ['f998','f46a','fb43'],
'softbank:fb63' => ['f9d4','f3ab','fb63'],
'softbank:fb64' => ['f9b0','f3ac','fb64'],
'softbank:fb43' => ['f998','f48c','fb43'],
'softbank:fb56' => ['f996','f48d','fb56'],
'softbank:f976' => ['f8c4','f684','f976'],
'softbank:f976' => ['f8c4','f7e0','f976'],
'softbank:f978' => ['f8c5','f686','f978'],
'softbank:f794' => ['f8c6','f351','f794'],
'softbank:f796' => ['f8c7','f352','f796'],
'softbank:f78e' => ['f8c8','f683','f78e'],
'softbank:f795' => ['f8c9','f67b','f795'],
'softbank:f799' => ['f8ca','f354','f799'],
'softbank:fba1' => ['f994','f3c7','fba1'],
'softbank:f797' => ['f8cb','f67c','f797'],
'softbank:f798' => ['f9e3','f353','f798'],
'softbank:f7a2' => ['f8c2','f682','f7a2'],
'softbank:f9ab' => ['f9f0','f696','f9ab'],
'softbank:f97b' => ['f9e5','f7ed','f97b'],
'softbank:f947' => ['f8fa','f7e7','f947'],
'softbank:f947' => ['f8fa','f3ec','f947'],
'softbank:f77e' => ['f8d5','f6f3','f77e'],
'softbank:f9ba' => ['f8d5','f6f3','f9ba'],
'softbank:fbd6' => ['f8f9','f3eb','fbd6'],
'softbank:f946' => ['f9b3','f7e6','f946'],
'softbank:f74e' => ['f9bf','f7f9','f74e'],
'softbank:f946' => ['f9b3','f6e6','f946'],
'softbank:f9c3' => ['f8e3','f674','f9c3'],
'softbank:f76f' => ['f9ba','f6a0','f76f'],
'softbank:f76f' => ['f9ba','f796','f76f'],
'softbank:f76f' => ['f9ba','f7a2','f76f'],
'softbank:f971' => ['f9bf','f7f9','f971'],
'softbank:f9b4' => ['f8e5','f7bc','f9b4'],
'softbank:f752' => ['f8e6','f6a8','f752'],
'softbank:f9eb' => ['f8e7','f7bd','f9eb'],
'softbank:f973' => ['f948','f6a2','f973'],
'softbank:f949' => ['f8e8','f7b3','f949'],
'softbank:f949' => ['f8e8','f6f7','f949'],
'softbank:f94a' => ['f8e9','f7a5','f94a'],
'softbank:f744' => ['f972','f7df','f744'],
'softbank:f9a1' => ['f8ea','f365','f9a1'],
'softbank:f94b' => ['f974','f6f9','f94b'],
'softbank:f743' => ['f977','f6fa','f743'],
'softbank:f743' => ['f973','f7ae','f743'],
'softbank:f743' => ['f973','f466','f743'],
'softbank:f741' => ['f8c6','f6f4','f741'],
'softbank:f741' => ['f8c6','f7e1','f741'],
'softbank:f742' => ['f8c6','f6f4','f742'],
'softbank:f752' => ['f8e6','f6f8','f752'],
'softbank:f743' => ['f977','f475','f743'],
'softbank:f94c' => ['f9bb','f7e8','f94c'],
'softbank:f9a1' => ['f9be','f679','f9a1'],
'softbank:f75e' => ['f8e3','f341','f75e'],
'softbank:f766' => ['f8ed','f6e5','f766'],
'softbank:f767' => ['f8ed','f6e5','f767'],
'softbank:f9b3' => ['f8d6','f6ef','f9b3'],
'softbank:f9a1' => ['f8ea','f77d','f9a1'],
'softbank:f9a1' => ['f8ea','f786','f9a1'],
'softbank:f789' => ['f8e4','f788','f789'],
'softbank:f789' => ['f8e4','f677','f789'],
'softbank:f789' => ['f8e4','f675','f789'],
'softbank:f789' => ['f8e4','f785','f789'],
'softbank:f789' => ['f8e4','f782','f789'],
'softbank:f789' => ['f8e4','f783','f789'],
'softbank:f789' => ['f8e4','f784','f789'],
'softbank:f789' => ['f8e4','f78c','f789'],
'softbank:f9a1' => ['f8ea','f781','f9a1'],
'softbank:f789' => ['f8e4','f789','f789'],
'softbank:f789' => ['f8e4','f78b','f789'],
'softbank:f9a1' => ['f8ea','f7e2','f9a1'],
'softbank:f956' => ['f8b4','f693','f956'],
'softbank:f954' => ['f8b5','f7b6','f954'],
'softbank:f955' => ['f8b6','f690','f955'],
'softbank:f958' => ['f8b7','f68f','f958'],
'softbank:f953' => ['f8b8','f380','f953'],
'softbank:fb6a' => ['f8b9','f7b7','fb6a'],
'softbank:f772' => ['f8ba','f692','f772'],
'softbank:f755' => ['f9d8','f643','f755'],
'softbank:f957' => ['f9b7','f445','f957'],
'softbank:f95e' => ['f8bc','f68e','f95e'],
'softbank:fb74' => ['f8bd','f7ec','fb74'],
'softbank:fb74' => ['f8bd','f7ec','fb74'],
'softbank:fb75' => ['f8be','f689','fb75'],
'softbank:f95f' => ['f8be','f689','f95f'],
'softbank:f95b' => ['f8bf','f68a','f95b'],
'softbank:fb6e' => ['f8c0','f68a','fb6e'],
'softbank:f79a' => ['f8c1','f688','f79a'],
'softbank:f7a2' => ['f8c2','f355','f7a2'],
'softbank:f95d' => ['f8c3','f68c','f95d'],
'softbank:f95c' => ['f947','f68d','f95c'],
'softbank:f775' => ['f947','f68d','f775'],
'softbank:f79b' => ['f8bf','f68a','f79b'],
'softbank:f97a' => ['f8cc','f78e','f97a'],
'softbank:f790' => ['f8cd','f67e','f790'],
'softbank:f78f' => ['f8ce','f642','f78f'],
'softbank:f763' => ['f99c','f695','f763'],
'softbank:f959' => ['f9f6','f446','f959'],
'softbank:f97c' => ['f8d7','f6dc','f97c'],
'softbank:f97d' => ['f8d8','f6f0','f97d'],
'softbank:fba7' => ['f8d8','f6f0','fba7'],
'softbank:f9aa' => ['f8db','f6e1','f9aa'],
'softbank:fba2' => ['f8dc','f7b9','fba2'],
'softbank:fba3' => ['f8dd','f3c9','fba3'],
'softbank:f765' => ['f8df','f676','f765'],
'softbank:f9c4' => ['f950','f697','f9c4'],
'softbank:f97e' => ['f99b','f7ee','f97e'],
'softbank:f9c6' => ['f9a4','f6de','f9c6'],
'softbank:f9c6' => ['f9a4','f3a0','f9c6'],
'softbank:f948' => ['f8e2','f6ee','f948'],
'softbank:f97d' => ['f8d8','f79b','f97d'],
'softbank:f76a' => ['f8eb','f6db','f76a'],
'softbank:f943' => ['f99e','f6c4','f943'],
'softbank:f9c8' => ['f47c','f743','f9c8'],
'softbank:f974' => ['f9c0','f6ed','f974'],
'softbank:f975' => ['f9c0','f6ed','f975'],
'softbank:f751' => ['f99e','f7fa','f751'],
'softbank:fb65' => ['f992','f3ae','fb65'],
'softbank:f7ee' => ['f9d6','f774','f7ee'],
'softbank:f7ef' => ['f9db','f775','f7ef'],
'softbank:fbd7' => ['f9d7','f76a','fbd7'],
'softbank:f7b0' => ['f985','f489','f7b0'],
'softbank:f7bc' => ['f987','f6fb','f7bc'],
'softbank:f7bd' => ['f988','f6fc','f7bd'],
'softbank:f7be' => ['f989','f740','f7be'],
'softbank:f7bf' => ['f98a','f741','f7bf'],
'softbank:f7c0' => ['f98b','f742','f7c0'],
'softbank:f7c1' => ['f98c','f743','f7c1'],
'softbank:f7c2' => ['f98d','f744','f7c2'],
'softbank:f7c3' => ['f98e','f745','f7c3'],
'softbank:f7c4' => ['f98f','f746','f7c4'],
'softbank:f7c5' => ['f990','f7c9','f7c5'],
'softbank:f760' => ['f8d4','f6af','f760'],
'softbank:f9e2' => ['f9ee','f6ae','f9e2'],
'softbank:f987' => ['f9ef','f6a9','f987'],
'softbank:f9e0' => ['f9f1','f7d1','f9e0'],
'softbank:f9d9' => ['f9f2','f383','f9d9'],
'softbank:f9de' => ['f9f1','f388','f9de'],
'softbank:f984' => ['f8d0','f685','f984'],
'softbank:f986' => ['f8d1','f7b4','f986'],
'softbank:f985' => ['f8d2','f69b','f985'],
'softbank:f988' => ['f8d3','f69c','f988'],
'softbank:f9d8' => ['f9c3','f382','f9d8'],
'softbank:f9ab' => ['f9f0','f36a','f9ab'],
'softbank:f985' => ['f9fb','f69a','f985'],
'softbank:f9ac' => ['f8d3','f36b','f9ac'],
'softbank:f985' => ['f8d2','f442','f985'],
'softbank:f7d6' => ['f8d9','f771','f7d6'],
'softbank:f7d8' => ['f8f7','f769','f7d8'],
'softbank:f7d7' => ['f8f8','f768','f7d7'],
'softbank:f7d9' => ['f949','f772','f7d9'],
'softbank:f7d6' => ['f99a','f3ee','f7d6'],
'softbank:f7d8' => ['f9a5','f3ef','f7d8'],
'softbank:f9d2' => ['f944','f381','f9d2'],
'softbank:f961' => ['f9a7','f65a','f961'],
'softbank:f9d7' => ['f9a7','f65a','f9d7'],
'softbank:f962' => ['f991','f7b2','f962'],
'softbank:f9c7' => ['f992','f479','f9c7'],
'softbank:f963' => ['f993','f64f','f963'],
'softbank:f9c7' => ['f994','f650','f9c7'],
'softbank:f9c7' => ['f991','f379','f9c7'],
'softbank:f9c8' => ['f992','f479','f9c8'],
'softbank:f9c9' => ['f991','f6c3','f9c9'],
'softbank:f9ca' => ['f991','f37a','f9ca'],
'softbank:f9cb' => ['f991','f37b','f9cb'],
'softbank:f9cc' => ['f991','f37c','f9cc'],
'softbank:f9cd' => ['f991','f37d','f9cd'],
'softbank:fb77' => ['f991','f458','fb77'],
'softbank:f9c7' => ['f992','f7cc','f9c7'],
'softbank:f7a4' => ['f99d','f7b2','f7a4'],
'softbank:f7ac' => ['f8ee','f378','f7ac'],
'softbank:f7ae' => ['f8ef','f7be','f7ae'],
'softbank:f7ad' => ['f8f0','f7bf','f7ad'],
'softbank:f7af' => ['f8f1','f7c0','f7af'],
'softbank:f9ae' => ['f8e0','f655','f9ae'],
'softbank:f7a8' => ['f8e1','f656','f7a8'],
'softbank:f7aa' => ['f8fc','f657','f7aa'],
'softbank:f7f2' => ['f9dc','f659','f7f2'],
'softbank:f777' => ['f9d4','f65c','f777'],
'softbank:f776' => ['f9c2','f687','f776'],
'softbank:f7a1' => ['f9d8','f476','f7a1'],
'softbank:f780' => ['f99c','f34b','f780'],
'softbank:f792' => ['f8cf','f67d','f792'],
'softbank:f781' => ['f8cf','f67d','f781'],
'softbank:f9a9' => ['f8cf','f67d','f9a9'],
'softbank:f7c9' => ['f97c','f35b','f7c9'],
'softbank:f7b2' => ['f982','f7e5','f7b2'],
'softbank:f7ed' => ['f9b0','f7ca','f7ed'],
'softbank:f7cb' => ['f9de','f35d','f7cb'],
'softbank:f7ca' => ['f9e0','f35c','f7ca'],
'softbank:f9b5' => ['f9d9','f6ca','f9b5'],
'softbank:f74f' => ['f9a0','f64e','f74f'],
'softbank:f9d4' => ['f9a1','f6be','f9d4'],
'softbank:f9b1' => ['f9a3','f652','f9b1'],
'softbank:f77c' => ['f9a6','f64d','f77c'],
'softbank:f9d1' => ['f9ab','f7ce','f9d1'],
'softbank:f9d1' => ['f9ac','f6bf','f9d1'],
'softbank:f9d0' => ['f9ad','f6cd','f9d0'],
'softbank:f9ce' => ['f99f','f37e','f9ce'],
'softbank:f7a5' => ['f99d','f651','f7a5'],
'softbank:f7a6' => ['f99d','f75a','f7a6'],
'softbank:f7b9' => ['f940','f756','f7b9'],
'softbank:f7b9' => ['f940','f757','f7b9'],
'softbank:f7b9' => ['f940','f766','f7b9'],
'softbank:f7ba' => ['f940','f767','f7ba'],
'softbank:f7ba' => ['f940','f767','f7ba'],
'softbank:f7bb' => ['f940','f767','f7bb'],
'softbank:f9ce' => ['f99f','f644','f9ce'],
'softbank:f754' => ['f981','f6f1','f754'],
'softbank:f754' => ['f981','f7dc','f754'],
'softbank:f785' => ['f97d','f6f5','f785'],
'softbank:f786' => ['f97d','f6f5','f786'],
'softbank:f785' => ['f97d','f7e3','f785'],
'softbank:f785' => ['f97d','f7d3','f785'],
'softbank:f980' => ['f97d','f6f2','f980'],
'softbank:f9c5' => ['f9b8','f6eb','f9c5'],
'softbank:f950' => ['f8f4','f488','f950'],
'softbank:f952' => ['f8f6','f7c4','f952'],
'softbank:f951' => ['f8f5','f7c3','f951'],
'softbank:f94d' => ['f9a2','f6cc','f94d'],
'softbank:f94e' => ['f9cc','f6d2','f94e'],
'softbank:fb5e' => ['f8f6','f3aa','fb5e'],
'softbank:fb60' => ['f9b0','f3a8','fb60'],
'softbank:fb61' => ['f9a5','f3a9','fb61'],
'softbank:fb62' => ['f8f6','f3aa','fb62'],
'softbank:f97d' => ['f953','f6f0','f97d'],
};



1;

#16進数コード ドコモ ソフトバンク auの順
__END__
F89F,F660,F98B
F8A0,F665,F98A
F8A1,F664,F98C
F8A2,F65D,F989
F8A3,F65F,F77D
F8A4,F641,FB84
F8A6,F3BC,FB7C
F957,F3C5,FB8C
F89F,F3C8,F98E
F89F,F3C8,FB8A
F89F,F34D,FB8B
F666,F98B,F98A
F957,F698,FB8C
F9E4,F481,FB7E
F957,F463,FB8C
F941,F7C6,F98D
F942,F7C7,F98D
F943,F65E,F98D
F942,F661,F98D
F95E,F7B1,F964
F95E,F7B1,F965
F95E,F7B1,F966
F95E,F7B1,F967
F95E,F7B1,F968
F95E,F7B1,F969
F95E,F7B1,F96A
F95E,F7B1,F96B
F95E,F7B1,F96C
F95E,F7B1,F96D
F95E,F7B1,F96E
F95E,F7B1,F96F
F95E,F7B1,F96D
F8A7,F667,F7DF
F8A8,F668,F7E0
F8A9,F669,F7E1
F8AA,F66A,F7E2
F8AB,F66B,F7E3
F8AC,F66C,F7E4
F8AD,F66D,F7E5
F8AE,F66E,F7E6
F8AF,F66F,F7E7
F8B0,F670,F7E8
F8B1,F671,F7E9
F8B2,F672,F7EA
F9E6,F6EC,F750
F9E8,F6BD,F9A4
F9EB,F482,F750
F9EC,F6A7,F758
F9ED,F6A3,F970
F9EC,F340,F759
F9E6,F487,F750
F9EA,F38D,F9E5
F9EA,F45E,F9E5
F8F2,F7C1,FB59
F8F3,F7C2,FB5B
F99E,F3A5,FB5C
F9CD,F44B,FB49
F9B5,F6E2,F9BC
F8D6,F374,F9BF
F995,F6D5,F941
F995,F6D3,F942
F995,F6D5,F944
F995,F6D3,F945
F9F9,F6B1,F774
F9F6,F3DE,FBC2
F9F6,F6AC,F959
F9F4,F6B9,FBC3
F9F4,F47A,FBC3
F9F4,F6B9,FBC1
F9F4,F34E,FBC3
F9F5,F6B5,F996
F945,F6B8,F993
F9F6,F672,F959
F946,F6B4,F990
F9F9,F6B1,F95A
F945,F6BA,F993
F9FA,F6B7,F74B
F945,F6BA,FBCA
F8F9,F6C7,FBD6
F9FA,F44C,F74B
F996,F64A,F99A
F998,F46B,FB43
F999,F39E,FB50
F997,F394,F999
F999,F7CB,FB46
F9C8,F39F,FB4F
F9CA,F39D,FB4E
F9CB,F7F4,F746
F9F8,F395,FB44
F9CD,F6C0,F745
F9CD,F6C0,FB49
F9F7,F3A1,F997
F9CB,F3A3,FB58
F9CB,F3A2,FB57
F9CF,F39C,FB4D
F995,F649,F998
F7CE,FB55,F9D1
F9CF,F399,FB4A
F9F8,F485,FB44
F9CF,F468,FB52
F995,F3A1,F997
F995,F6D4,FB54
F995,F3A1,F997
F995,F649,FB55
F9D3,F46D,FB53
F9D2,F64B,FB51
F9FC,F39A,FB4B
F9D0,F396,FB46
F9C9,F461,FB56
F9C6,F399,FB4A
F998,F397,FB47
F9C5,F394,FB43
F9FC,F7F5,F747
F9A6,F398,FB48
F9D1,F393,FB42
F9C8,F7F6,F748
F9C8,F7F6,FB41
F9D0,F64C,FB46
F9CE,F7F3,FB45
F995,F465,F998
F9F8,F484,FB44
F9CF,F467,FB52
F9CB,F464,FB58
F9CB,F469,F746
F9D3,F46C,FB53
F9C9,F462,FB56
F9F8,F46E,FB44
F998,F46A,FB43
F9D4,F3AB,FB63
F9B0,F3AC,FB64
F998,F48C,FB43
F996,F48D,FB56
F8C4,F684,F976
F8C4,F7E0,F976
F8C5,F686,F978
F8C6,F351,F794
F8C7,F352,F796
F8C8,F683,F78E
F8C9,F67B,F795
F8CA,F354,F799
F994,F3C7,FBA1
F8CB,F67C,F797
F9E3,F353,F798
F8C2,F682,F7A2
F9F0,F696,F9AB
F9E5,F7ED,F97B
F8FA,F7E7,F947
F8FA,F3EC,F947
F8D5,F6F3,F77E
F8D5,F6F3,F9BA
F8F9,F3EB,FBD6
F9B3,F7E6,F946
F9BF,F7F9,F74E
F9B3,F6E6,F946
F8E3,F674,F9C3
F9BA,F6A0,F76F
F9BA,F796,F76F
F9BA,F7A2,F76F
F9BF,F7F9,F971
F8E5,F7BC,F9B4
F8E6,F6A8,F752
F8E7,F7BD,F9EB
F948,F6A2,F973
F8E8,F7B3,F949
F8E8,F6F7,F949
F8E9,F7A5,F94A
F972,F7DF,F744
F8EA,F365,F9A1
F974,F6F9,F94B
F977,F6FA,F743
F973,F7AE,F743
F973,F466,F743
F8C6,F6F4,F741
F8C6,F7E1,F741
F8C6,F6F4,F742
F8E6,F6F8,F752
F977,F475,F743
F9BB,F7E8,F94C
F9BE,F679,F9A1
F8E3,F341,F75E
F8ED,F6E5,F766
F8ED,F6E5,F767
F8D6,F6EF,F9B3
F8EA,F77D,F9A1
F8EA,F786,F9A1
F8E4,F788,F789
F8E4,F677,F789
F8E4,F675,F789
F8E4,F785,F789
F8E4,F782,F789
F8E4,F783,F789
F8E4,F784,F789
F8E4,F78C,F789
F8EA,F781,F9A1
F8E4,F789,F789
F8E4,F78B,F789
F8EA,F7E2,F9A1
F8B4,F693,F956
F8B5,F7B6,F954
F8B6,F690,F955
F8B7,F68F,F958
F8B8,F380,F953
F8B9,F7B7,FB6A
F8BA,F692,F772
F9D8,F643,F755
F9B7,F445,F957
F8BC,F68E,F95E
F8BD,F7EC,FB74
F8BD,F7EC,FB74
F8BE,F689,FB75
F8BE,F689,F95F
F8BF,F68A,F95B
F8C0,F68A,FB6E
F8C1,F688,F79A
F8C2,F355,F7A2
F8C3,F68C,F95D
F947,F68D,F95C
F947,F68D,F775
F8BF,F68A,F79B
F8CC,F78E,F97A
F8CD,F67E,F790
F8CE,F642,F78F
F99C,F695,F763
F9F6,F446,F959
F8D7,F6DC,F97C
F8D8,F6F0,F97D
F8D8,F6F0,FBA7
F8DB,F6E1,F9AA
F8DC,F7B9,FBA2
F8DD,F3C9,FBA3
F8DF,F676,F765
F950,F697,F9C4
F99B,F7EE,F97E
F9A4,F6DE,F9C6
F9A4,F3A0,F9C6
F8E2,F6EE,F948
F8D8,F79B,F97D
F8EB,F6DB,F76A
F99E,F6C4,F943
F47C,F743,F9C8
F9C0,F6ED,F974
F9C0,F6ED,F975
F99E,F7FA,F751
F992,F3AE,FB65
F9D6,F774,F7EE
F9DB,F775,F7EF
F9D7,F76A,FBD7
F985,F489,F7B0
F987,F6FB,F7BC
F988,F6FC,F7BD
F989,F740,F7BE
F98A,F741,F7BF
F98B,F742,F7C0
F98C,F743,F7C1
F98D,F744,F7C2
F98E,F745,F7C3
F98F,F746,F7C4
F990,F7C9,F7C5
F8D4,F6AF,F760
F9EE,F6AE,F9E2
F9EF,F6A9,F987
F9F1,F7D1,F9E0
F9F2,F383,F9D9
F9F1,F388,F9DE
F8D0,F685,F984
F8D1,F7B4,F986
F8D2,F69B,F985
F8D3,F69C,F988
F9C3,F382,F9D8
F9F0,F36A,F9AB
F9FB,F69A,F985
F8D3,F36B,F9AC
F8D2,F442,F985
F8D9,F771,F7D6
F8F7,F769,F7D8
F8F8,F768,F7D7
F949,F772,F7D9
F99A,F3EE,F7D6
F9A5,F3EF,F7D8
F944,F381,F9D2
F9A7,F65A,F961
F9A7,F65A,F9D7
F991,F7B2,F962
F992,F479,F9C7
F993,F64F,F963
F994,F650,F9C7
F991,F379,F9C7
F992,F479,F9C8
F991,F6C3,F9C9
F991,F37A,F9CA
F991,F37B,F9CB
F991,F37C,F9CC
F991,F37D,F9CD
F991,F458,FB77
F992,F7CC,F9C7
F99D,F7B2,F7A4
F8EE,F378,F7AC
F8EF,F7BE,F7AE
F8F0,F7BF,F7AD
F8F1,F7C0,F7AF
F8E0,F655,F9AE
F8E1,F656,F7A8
F8FC,F657,F7AA
F9DC,F659,F7F2
F9D4,F65C,F777
F9C2,F687,F776
F9D8,F476,F7A1
F99C,F34B,F780
F8CF,F67D,F792
F8CF,F67D,F781
F8CF,F67D,F9A9
F97C,F35B,F7C9
F982,F7E5,F7B2
F9B0,F7CA,F7ED
F9DE,F35D,F7CB
F9E0,F35C,F7CA
F9D9,F6CA,F9B5
F9A0,F64E,F74F
F9A1,F6BE,F9D4
F9A3,F652,F9B1
F9A6,F64D,F77C
F9AB,F7CE,F9D1
F9AC,F6BF,F9D1
F9AD,F6CD,F9D0
F99F,F37E,F9CE
F99D,F651,F7A5
F99D,F75A,F7A6
F940,F756,F7B9
F940,F757,F7B9
F940,F766,F7B9
F940,F767,F7BA
F940,F767,F7BA
F940,F767,F7BB
F99F,F644,F9CE
F981,F6F1,F754
F981,F7DC,F754
F97D,F6F5,F785
F97D,F6F5,F786
F97D,F7E3,F785
F97D,F7D3,F785
F97D,F6F2,F980
F9B8,F6EB,F9C5
F8F4,F488,F950
F8F6,F7C4,F952
F8F5,F7C3,F951
F9A2,F6CC,F94D
F9CC,F6D2,F94E
F8F6,F3AA,FB5E
F9B0,F3A8,FB60
F9A5,F3A9,FB61
F8F6,F3AA,FB62
F953,F6F0,F97D
