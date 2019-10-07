##########################################################
# @desc		
# @package	JKZ::ConvertStr
# @access	public
# @author	Iwahase Ryo
# @create	2006/11/10
# @version	1.00
##########################################################

package MyClass::ConvertStr;

use 5.008005;
#use strict;
our $VERSION ='1.00';

use NKF;

use Exporter;
@ISA = (Exporter);

@EXPORT_OK = qw(ConvSJIS ReplaceHTML ReplaceHTMLTextArea 
				ReplaceHiddenData ReplaceFieldValue 
				ConvEzwebIcon ConvDocomoIcon 
				ReplaceAdMailContents ReplaceMailSubject );

#メール本文における置き換え文字列処理
sub ReplaceAdMailContents {
	my ($admailno, $body,$crr) = @_;
	my @adids = ();
	my $list = $body;
	while ($list =~ /$KEY_ADID/i){
		push @adids, $1;
		$list = $';
	}
	
	foreach (@adids){
		my $str = $KEY_ADID_CHECK.$_.$KEY_BASE_END;
		my $adurl = $ADMAIL_BASE_URL."?i=0000000000&p=1111&n=$admailno&a=$_";
		$body =~ s/$str/$adurl/gi;
	}
	if ($CARRIER{'docomo'} == $crr) {
		$body = ConvDocomoIcon($body);
	}
	if ($CARRIER{'ezweb'} == $crr) {
		$body = ConvEzwebIcon($body);
	}
	return $body;
}1;

#メールタイトルの変換処理
sub ReplaceMailSubject {
	my ($subject,$crr) = @_;
	#EZ, DoCoMoはSJISのまま絵文字変換だけする
	if ($CARRIER{'docomo'} == $crr) {
		$subject = ConvDocomoIcon($subject);
	} elsif ($CARRIER{'ezweb'} == $crr) {
		$subject = ConvEzwebIcon($subject);
	} else {
		#それ以外はISO-2022-JPに変換
		#したいところだけど、このままの状態でDBに
		#入れないと文字化けするからやっちゃだめ
		return $subject;
	}
}1;

#メールヘッダーを作る
sub GetMailHeader {
	my $header;
	my ($subject, $from, $to, $crr, $extra) = @_;
	
	if ($CARRIER{'docomo'} == $crr) {
		#絵文字をバイナリに変換
		$subject = ConvDocomoIcon($subject);
		$header = "Subject: $subject\n";
		$header .= "From: $from\n";
		$header .= "To: $to\n";
		$header .= "Content-Type: text/plain;charset=Shift-JIS\n";
		$header .= "Content-Transfer-Encoding: base64\n";
		$header .= $extra."\n" if(defined $extra);
	} elsif ($CARRIER{'ezweb'} == $crr) {
		$subject = ConvEzwebIcon($subject);
		$header = "Subject: $subject\n";
		$header .= "From: $from\n";
		$header .= "To: $to\n";
		$header .= "Content-Type: text/plain;charset=Shift-JIS\n";
		$header .= "Content-Transfer-Encoding: base64\n";
		$header .= $extra."\n" if(defined $extra);
	} else {
		#それ以外はISO-2022-JPに変換
		$subject = nkf('-j' , $subject);
		$header = "Subject: $subject\n";
		$header .= "From: $from\n";
		$header .= "To: $to\n";
		$header .= "Content-Type: text/plain;charset=ISO-2022-JP\n";
		$header .= $extra."\n" if (defined $extra);
	}
	return $header;
}1;

#広告テ送信用メール本体を作る
sub GetMailBody {
	my ($body,$crr) = @_;
	if ($CARRIER{'docomo'} == $crr || $CARRIER{'ezweb'} == $crr ) {
		#BASE64
		$body = MIME::Base64::encode($body);
	} else {
		#それ以外はそのまま
		$body = nkf('-j', $body);
	}
	return $body;
}1;

#広告テスト送信用メール本体を作る
sub GetTestMailBody {
	my ($admailno,$body,$crr) = @_;
	$body = ReplaceAdMailContents($admailno,$body,$crr);
	if ($CARRIER{'docomo'} == $crr || $CARRIER{'ezweb'} == $crr ) {
		#BASE64
		$body = MIME::Base64::encode($body);
	} else {
		#それ以外はそのまま
		$body = nkf('-j', $body);
	}
	return $body;
}1;

#ezweb変換用文字テーブル
my @icon = (33088,
			63065,	#1	F659
			63066,	#2	F65A
			63067,	#3	F65B
			63304,	#4	F748
			63305,	#5	F749
			63306,	#6	F74A
			63307,	#7	F74B
			63308,	#8	F74C
			63309,	#9	F74D
			63310,	#10	F74E
			63311,	#11	F74F
			63130,	#12	F69A
			63210,	#13	F6EA
			63382,	#14	F796
			63070,	#15	F65E
			63070,	#16	F65E
			63312,	#17	F750
			63313,	#18	F751
			63314,	#19	F752
			63315,	#20	F753
			63316,	#21	F754
			63317,	#22	F755
			63318,	#23	F756
			63319,	#24	F757
			63383,	#25	F797
			63320,	#26	F758
			63321,	#27	F759
			63322,	#28	F75A
			63323,	#29	F75B
			63324,	#30	F75C
			63325,	#31	F75D
			63326,	#32	F75E
			63327,	#33	F75F
			63328,	#34	F760
			63329,	#35	F761
			63330,	#36	F762
			63331,	#37	F763
			63332,	#38	F764
			63333,	#39	F765
			63334,	#40	F766
			63335,	#41	F767
			63336,	#42	F768
			63337,	#43	F769
			63072,	#44	F660
			63123,	#45	F693
			63409,	#46	F7B1
			63073,	#47	F661
			63211,	#48	F6EB
			63356,	#49	F77C
			63187,	#50	F6D3
			63410,	#51	F7B2
			63131,	#52	F69B
			63212,	#53	F6EC
			63338,	#54	F76A
			63339,	#55	F76B
			63357,	#56	F77D
			63384,	#57	F798
			63060,	#58	F654
			63358,	#59	F77E
			63074,	#60	F662
			63340,	#61	F76C
			63341,	#62	F76D
			63342,	#63	F76E
			63343,	#64	F76F
			63132,	#65	F69C
			63344,	#66	F770
			63360,	#67	F780
			63188,	#68	F6D4
			63075,	#69	F663
			63345,	#70	F771
			63346,	#71	F772
			63213,	#72	F6ED
			63347,	#73	F773
			63160,	#74	F6B8
			63040,	#75	F640
			63044,	#76	F644
			63054,	#77	F64E
			63161,	#78	F6B9
			63404,	#79	F7AC
			63189,	#80	F6D5
			63348,	#81	F774
			63349,	#82	F775
			63092,	#83	F674
			63405,	#84	F7AD
			63411,	#85	F7B3
			63190,	#86	F6D6
			63385,	#87	F799
			63350,	#88	F776
			63351,	#89	F777
			63376,	#90	F790
			63093,	#91	F675
			63361,	#92	F781
			63412,	#93	F7B4
			63214,	#94	F6EE
			63076,	#95	F664
			63124,	#96	F694
			63362,	#97	F782
			63068,	#98	F65C
			63042,	#99	F642
			63363,	#100	F783
			63364,	#101	F784
			63365,	#102	F785
			63366,	#103	F786
			63215,	#104	F6EF
			63367,	#105	F787
			63094,	#106	F676
			63077,	#107	F665
			63226,	#108	F6FA
			63386,	#109	F79A
			63216,	#110	F6F0
			63387,	#111	F79B
			63108,	#112	F684
			63165,	#113	F6BD
			63388,	#114	F79C
			63389,	#115	F79D
			63191,	#116	F6D7
			63352,	#117	F778
			63353,	#118	F779
			63217,	#119	F6F1
			63218,	#120	F6F2
			63368,	#121	F788
			63095,	#122	F677
			63390,	#123	F79E
			63219,	#124	F6F3
			63114,	#125	F68A
			63391,	#126	F79F
			63377,	#127	F791
			63378,	#128	F792
			63220,	#129	F6F4
			63392,	#130	F7A0
			63369,	#131	F789
			63354,	#132	F77A
			63143,	#133	F6A7
			63162,	#134	F6BA
			63393,	#135	F7A1
			63355,	#136	F77B
			63370,	#137	F78A
			63221,	#138	F6F5
			63394,	#139	F7A2
			63192,	#140	F6D8
			63193,	#141	F6D9
			63371,	#142	F78B
			63096,	#143	F678
			63144,	#144	F6A8
			63222,	#145	F6F6
			63109,	#146	F685
			63372,	#147	F78C
			63115,	#148	F68B
			63097,	#149	F679
			63395,	#150	F7A3
			63406,	#151	F7AE
			63396,	#152	F7A4
			63407,	#153	F7AF
			63408,	#154	F7B0
			63223,	#155	F6F7
			63110,	#156	F686
			63373,	#157	F78D
			63098,	#158	F67A
			63379,	#159	F793
			63133,	#160	F69D
			63397,	#161	F7A5
			63404,	#162	F7AC
			63450,	#163	F7DA
			63399,	#164	F7A7
			63224,	#165	F6F8
			63225,	#166	F6F9
			63078,	#167	F666
			63116,	#168	F68C
			63117,	#169	F68D
			63137,	#170	F6A1
			63400,	#171	F7A8
			63150,	#172	F6AE
			33088,	#173	8140
			33088,	#174	8140
			33088,	#175	8140
			63061,	#176	F655
			63062,	#177	F656
			63063,	#178	F657
			63064,	#179	F658
			63227,	#180	F6FB
			63228,	#181	F6FC
			63296,	#182	F740
			63297,	#183	F741
			63298,	#184	F742
			63299,	#185	F743
			63300,	#186	F744
			63301,	#187	F745
			63302,	#188	F746
			63303,	#189	F747
			63041,	#190	F641
			63069,	#191	F65D
			63079,	#192	F667
			63080,	#193	F668
			63081,	#194	F669
			63082,	#195	F66A
			63083,	#196	F66B
			63084,	#197	F66C
			63085,	#198	F66D
			63086,	#199	F66E
			63087,	#200	F66F
			63088,	#201	F670
			63089,	#202	F671
			63090,	#203	F672
			63091,	#204	F673
			63099,	#205	F67B
			63100,	#206	F67C
			63101,	#207	F67D
			63102,	#208	F67E
			63104,	#209	F680
			63105,	#210	F681
			63106,	#211	F682
			63107,	#212	F683
			63374,	#213	F78E
			63375,	#214	F78F
			63111,	#215	F687
			63112,	#216	F688
			63113,	#217	F689
			63043,	#218	F643
			63119,	#219	F68F
			63120,	#220	F690
			63121,	#221	F691
			63122,	#222	F692
			63045,	#223	F645
			63125,	#224	F695
			63126,	#225	F696
			63127,	#226	F697
			63128,	#227	F698
			63129,	#228	F699
			63046,	#229	F646
			63047,	#230	F647
			63134,	#231	F69E
			63135,	#232	F69F
			63136,	#233	F6A0
			63138,	#234	F6A2
			63139,	#235	F6A3
			63140,	#236	F6A4
			63141,	#237	F6A5
			63142,	#238	F6A6
			63145,	#239	F6A9
			63146,	#240	F6AA
			63147,	#241	F6AB
			63148,	#242	F6AC
			63149,	#243	F6AD
			63150,	#244	F6AE
			63151,	#245	F6AF
			63048,	#246	F648
			63152,	#247	F6B0
			63153,	#248	F6B1
			63154,	#249	F6B2
			63155,	#250	F6B3
			63156,	#251	F6B4
			63157,	#252	F6B5
			63158,	#253	F6B6
			63159,	#254	F6B7
			54971,	#255	D6BB
			63164,	#256	F6BC
			63049,	#257	F649
			63050,	#258	F64A
			63051,	#259	F64B
			63052,	#260	F64C
			63053,	#261	F64D
			63166,	#262	F6BE
			63167,	#263	F6BF
			63168,	#264	F6C0
			63055,	#265	F64F
			63056,	#266	F650
			63057,	#267	F651
			63058,	#268	F652
			63059,	#269	F653
			63169,	#270	F6C1
			63170,	#271	F6C2
			63171,	#272	F6C3
			63172,	#273	F6C4
			63173,	#274	F6C5
			63174,	#275	F6C6
			63175,	#276	F6C7
			63176,	#277	F6C8
			63177,	#278	F6C9
			63178,	#279	F6CA
			63179,	#280	F6CB
			63180,	#281	F6CC
			63181,	#282	F6CD
			63182,	#283	F6CE
			63183,	#284	F6CF
			63184,	#285	F6D0
			63185,	#286	F6D1
			63186,	#287	F6D2
			63195,	#288	F6DB
			63196,	#289	F6DC
			63197,	#290	F6DD
			63198,	#291	F6DE
			63199,	#292	F6DF
			63200,	#293	F6E0
			63201,	#294	F6E1
			63202,	#295	F6E2
			63203,	#296	F6E3
			63204,	#297	F6E4
			63380,	#298	F794
			63381,	#299	F795
			63205,	#300	F6E5
			63206,	#301	F6E6
			63207,	#302	F6E7
			63208,	#303	F6E8
			63209,	#304	F6E9
			63413,	#305	F7B5
			63414,	#306	F7B6
			63415,	#307	F7B7
			63416,	#308	F7B8
			63417,	#309	F7B9
			63418,	#310	F7BA
			63419,	#311	F7BB
			63420,	#312	F7BC
			63421,	#313	F7BD
			63422,	#314	F7BE
			63423,	#315	F7BF
			63424,	#316	F7C0
			63425,	#317	F7C1
			63426,	#318	F7C2
			63427,	#319	F7C3
			63428,	#320	F7C4
			63429,	#321	F7C5
			63430,	#322	F7C6
			63431,	#323	F7C7
			63432,	#324	F7C8
			63433,	#325	F7C9
			63434,	#326	F7CA
			63435,	#327	F7CB
			63436,	#328	F7CC
			63437,	#329	F7CD
			63438,	#330	F7CE
			63439,	#331	F7CF
			63440,	#332	F7D0
			63441,	#333	F7D1
			63461	#334	F7E5
);
my @exticon = (	63442,	#500	F7D2
				63443,	#501	F7D3
				63444,	#502	F7D4
				63445,	#503	F7D5
				63446,	#504	F7D6
				63447,	#505	F7D7
				63448,	#506	F7D8
				63449,	#507	F7D9
				63450,	#508	F7DA
				63451,	#509	F7DB
				63452,	#510	F7DC
				63453,	#511	F7DD
				63454,	#512	F7DE
				63455,	#513	F7DF
				63456,	#514	F7E0
				63457,	#515	F7E1
				63458,	#516	F7E2
				63459,	#517	F7E3
				63460	#518	F7E4
);

########################################################
#		ezweb絵文字変換関数
#
#     入力パラメータ
#               1:変換元文字列
#     出力パラメータ
#               変換後文字列
#
######################################################
sub ConvEzwebIcon {
	my ($srcstr, $dststr, $key, $val, $code, $rep);
	#文字列を取得
	($srcstr) = @_;
	#指定されていない場合はそのまま返す
	if ($srcstr eq "") {
		return "";
	}
	
	$dststr=$srcstr;
	
	while ($dststr =~ /$KEY_EZWEB/i) {
		$key= $1+0;

		if ($key >=1 && $key <=334) {
			#通常のアイコン
			$val = $icon[$key];
			$code=pack('n', $val);
		}
		elsif ($key >= 500 && $key <= 518) {
			#拡張アイコン
			$val = $exticon[($key-500)];
			$code=pack('n', $val);
		}
		else {
			#全角スペースにする
			$code='　';
		}
		$rep = $KEY_EZWEB_CHECK . $key . $KEY_BASE_END;
		$dststr =~ s/$rep/$code/gi;
	}
	return $dststr;
}1;

########################################################
#		ドコモ絵文字変換関数
#
#     入力パラメータ
#               1:変換元文字列
#     出力パラメータ
#               変換後文字列
#
######################################################
sub ConvDocomoIcon {
	my ($srcstr, $dststr, $key, $val, $code, $rep);
	($srcstr) = @_;
	#指定されていない場合はそのまま返す
	if ($srcstr eq "") {
		return "";
	}
	
	$dststr=$srcstr;
	while ($dststr =~ /$KEY_DOCOMO/i) {
		$key= $1;
		$val=hex($key);
		$code=pack('n', $val);

		$rep = $KEY_DOCOMO_CHECK . $key . $KEY_BASE_END;
		$dststr =~ s/$rep/$code/gi;
	}		
	return $dststr;
}1;
######################################################
#
#     出力パラメータ
#               SJISの文字列
#
######################################################
sub ConvSJIS {
	my ($str) = @_;
	
	if (!defined($str)) {
		#文字列が指定されていない場合は、空文字を返す
		return "";
	}
	if (length($str)==0) {
		#文字列が空文字の場合は、そのまま返す
		return $str;
	}
	
	$str =~ tr/+/ /;
	$str =~ s/%([0-9A-Fa-f][0-9A-Fa-f])/pack("H2", $1)/eg;

#	&jcode'convert(*str,'sjis');
	nkf('-Sx' , *str);

	if ($str =~ /\r\n/) { $str =~ s/\r//g; }
	elsif ($str =~ /\r/) { $str =~ s/\r/\n/g; }

	return $str;
}

#改行を<br>にしたり、<を&ltにしたり
sub ReplaceHTML {
	my 	($str) = @_;
	$_ = $str;
	#使用頻度の高い文字を変換
	s/&/&amp;/g;
	s/</&lt;/g;
	s/>/&gt;/g;
	s/ /&nbsp;/g;

	#改行コードを<BR>へ変換
	s/\n/<BR>/g;
	$str = $_;
	return $str;
}1;

sub ReplaceHTMLTextArea {
	my ($str) = @_;
	$_ = $str;
	#使用頻度の高い文字を変換
	s/&/&amp;/g;
	s/</&lt;/g;
	s/>/&gt;/g;

	$str = $_;
	return $str;
}1;

sub ReplaceHiddenData {
	my ($str,$mode) = @_;
	$_ = $str;

	if ($mode==1) {
		#エスケープ文字にする
		s/&/&amp;/g;
		s/"/&quot;/g; #"
	}
	else {
		#エスケープ文字を元に戻す
		s/&quot;/"/g; #"
		s/&amp;/&/g;
	}

	$str = $_;
	return $str;
}1;

#シングルコーテーションを変換
#バックスラッシュ・￥マークを変換
sub ReplaceFieldValue {
	my ($str) = @_;

	$_ = $str;

	s/(['\\])/\\$1/g;

	#文末が￥マークの場合、半角スペースに変換
    s/(\\$)/ /g;

	$str = $_;
	return $str;
}1;