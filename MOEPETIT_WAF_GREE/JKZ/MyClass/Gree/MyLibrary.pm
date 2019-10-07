#******************************************************
# @desc      MyLibraryのクラス
# @desc      マイページの情報やフラッシュゲーム処理、ユーザーアクション全般
#
# @package   MyClass::Gree::MyLibrary
# @access    public
# @author    Iwahase Ryo
# @create    2011/05/02
# @update    
# @version    1.00
#******************************************************
package MyClass::Gree::MyLibrary;

use strict;
use warnings;
no warnings 'redefine';
use 5.008005;
our $VERSION = '1.00';

use base qw(MyClass::Gree::MyPage);

use MyClass::WebUtil;
#use MyClass::JKZSession;
use MyClass::JKZDB::MyItem;
use MyClass::JKZDB::GsaUserStatus;
use MyClass::JKZDB::MyLibrary;
use MyClass::JKZDB::MyLibraryImage;
use MyClass::JKZDB::MyContentsStatus;

use Data::Dumper;

#******************************************************
# @access    public
# @desc        コンストラクタ
# @param    
# @return    
#******************************************************
sub new {
    my ($class, $cfg) = @_;

    return $class->SUPER::new($cfg);
}


sub run {
    my $self = shift;

    $self->SUPER::run();
}


#******************************************************
# @desc     
# 図鑑キャッシュの構造
#
# _gsa_my_library:[gree_user_id] => {
#    my_library_id:[my_library_id]   => {
#        my_library_binding_image_id =>
#        my_library_name             =>
#        my_library_description      =>
#        my_item_id                  =>
#        my_library_image_total      =>
#    }
# }
# 図鑑画像リストキャッシュ 画像の配列順はimage_orderの順。image_orderに値がない場合適当
# _gsa_my_library_images:[my_library_id] => [my_getimage_id]
#
#
# @param    
# @param    
# @return   
#******************************************************
sub viewlist_my_library {
    my $self            = shift;
    my $gree_user_id    = $self->opensocial_owner_id;

    # 図鑑作成上限 現在値は3 2011/05/10
    my $library_limit   = $self->cfg->param('MY_LIBRARY_LIMIT');

    my $my_library_key  = '_gsa_my_library';
    my $my_library_namespace = sprintf("%s%s", $self->waf_name_space, $my_library_key);
    my $cacheobj = $self->memcached->get("$my_library_namespace:$gree_user_id");
    my $obj;

    if(!$cacheobj) {

        my $dbh = $self->getDBConnection();
        $self->setDBCharset("sjis");
        my $myLibrary   = MyClass::JKZDB::MyLibrary->new($dbh);
        my $hashref     = $myLibrary->getSpecificValuesSQL({
            columnslist => [
                            'my_library_id',
                            'status_flag',
                            'my_library_binding_image_id',
                            'my_library_name',
                            'my_library_description',
                            'my_item_id',
                            'my_library_image_total',
            ],
            whereSQL    => 'gree_user_id=?',
            placeholder => [$gree_user_id],
        });

        if (!$hashref || 0 > $#{ $hashref->{my_library_id} }) {
            $obj->{IfNotExistsMyLibrary} = 1;
            $obj->{IfMyLibraryBelowLimit} = 1;
            return $obj;
        }

        #******************************
        # memcached格納用の構造生成
        #******************************
        #    my $cacheobj_structure;
        map {
            my $hash_key = sprintf("my_library_id:%s", $hashref->{my_library_id}->[$_]);
            foreach my $key ( keys %{ $hashref } ) {
                #$cacheobj_structure->{$hash_key}->{$key} =  $hashref->{$key}->[$_];
                $cacheobj->{$hash_key}->{$key} =  $hashref->{$key}->[$_];
            }
        } 0..$#{ $hashref->{my_library_id} };

        ## キャッシュは1800秒
        $self->memcached->add("$my_library_namespace:$gree_user_id", $cacheobj, 1800);
    }
    my $SITEIMAGE_SCRIPT        = sprintf("%s%s", $self->MAIN_URL, $self->CONFIGURATION_VALUE('SITEIMAGE_SCRIPTDATABASE_NAME'));
    my $LIBRARY_IMAGE_SCRIPT    = sprintf("%s%s", $self->MAIN_URL, $self->CONFIGURATION_VALUE('LIBRARY_IMAGE_SCRIPTDATABASE_NAME'));
    my $cnt;
    foreach my $cache_key (keys %{ $cacheobj }) {
        map {
            $obj->{$_}->[$cnt]                              = $cacheobj->{$cache_key}->{$_};
            $obj->{LMY_LIBRARY_URL}->[$_]                   = $self->MY_LIBRARY_URL;
            $obj->{LLIBRARY_IMAGE_SCRIPTDATABASE_URL}->[$_] = $LIBRARY_IMAGE_SCRIPT;
            $obj->{LSITEIMAGE_SCRIPTDATABASE_URL}->[$_]     = $SITEIMAGE_SCRIPT;
            $obj->{status_flag} == 2 ? $obj->{IfExistsMyLibraryImage}->[$_] = 1 : $obj->{IfNotExistsMyLibraryImage}->[$_] = 1;
        } keys %{ $cacheobj->{$cache_key} };
        $cnt++;
    }

    # 図鑑上限以内の場合
    $library_limit == scalar @{ $obj->{my_library_id} } ? $obj->{IfMyLibraryOnLimit} = 1 : $obj->{IfMyLibraryBelowLimit} = 1;

    $obj->{IfExistsMyLibrary} = 1;

    return $obj;
}


#******************************************************
# @desc     図鑑作成
# @desc    ゲットしたキャラ画像のパラメータはmgiとする(my_getimage_id)みたいな
# @desc     処理順はパラメータoptで判定
# @param    
# @return   
#******************************************************
sub regist_my_library {
    my $self = shift;
    my $gree_user_id    = $self->opensocial_owner_id;
    my $q               = $self->query;
    my $obj;

    my $my_library_id   = $q->param('mli')  || undef;
    my $redo_flag       = $q->param('redo') || undef;
    my $opt             = $q->param('opt')  || undef;

    my $checkbox_allchecked = $q->param('ca') || 0;
    ## 全てチェックするが選択された場合の判定
    my @If_Loop_tag = ('GetResizedImageAllUnChecked', 'GetResizedImageAllChecked');
    my $IfTag       = sprintf("If%s", $If_Loop_tag[$checkbox_allchecked]);
    my $LoopTag     = sprintf("Loop%sList", $If_Loop_tag[$checkbox_allchecked]);

    # 画像サイズ生成プログラム
    my $ResizingScript = sprintf("%s%s", $self->MAIN_URL, $self->cfg->param('CONTENTS_RESIZED_IMAGE_SCRIPTDATABASE_NAME'));

=pod
    $obj->{IfStep1} = 1 if $redo_flag || !defined($my_library_id);
    $obj->{IfStep2} = 1 if !defined($redo_flag) && $my_library_id && 2 == $opt;
    $obj->{IfStep3} = 1 if 3 == $opt && $my_library_id;
    $obj->{IfStep4} = 1 if 4 == $opt && $my_library_id;
=cut
#***************************
# 順番処理
# Step1 図鑑名：内容：表紙画像選択
# Step2 図鑑名：内容：表紙画像登録確認
# Step3 図鑑名：内容：表紙画像 DATABASE INSERT
#       図鑑画像選択：図鑑アイテム選択
# Step4 図鑑画像：図鑑アイテム登録・使用確認
# Step5 図鑑画像：   DATABASE INSERT 
#       図鑑アイテム使用時は画像加工
#       図鑑アイテム DATABASE UPDATE
#
#***************************
    (4 == $opt && $my_library_id)                           ? $obj->{IfStep4} = 1 :
    (3 == $opt && $my_library_id)                           ? $obj->{IfStep3} = 1 :
    (!defined($redo_flag) && $my_library_id && 2 == $opt)   ? $obj->{IfStep2} = 1 :
    ($redo_flag || !defined($my_library_id))                ? $obj->{IfStep1} = 1 :
                                                              $obj->{IfStep1} = 1 ;
        #************************************
        # Step1 
        #************************************
    ## 最初のステップかやり直しの場合
    if ($obj->{IfStep1}) {

        $obj->{my_library_name}             = $q->escapeHTML($q->param('my_library_name'));
        $obj->{my_library_description}      = $q->escapeHTML($q->param('my_library_description'));
        $obj->{my_library_binding_image_id} = $q->param('mlbii');

        #************************************
        # 図鑑表紙用画像リスト
        #************************************
        my $myContentsCategory  = MyClass::JKZDB::MyContentsStatus->new($self->getDBConnection);
        my $my_getimage_id_ref  = $myContentsCategory->getAllSetOfCategoryID($gree_user_id);

        foreach my $ref (@{ $my_getimage_id_ref }) {
            my @tmp = split(/,/, $ref->{sum_category_id});
            map { push @{ $obj->{character_id} }, sprintf("%s:%s", $ref->{contentsm_id}, (log($_) / log(2))) } @tmp;
        }
        map {
            $obj->{LCONTENTS_RESIZED_IMAGE_SCRIPTDATABASE_URL}->[$_] = $ResizingScript; 
            $obj->{IfBR}->[$_] = 1 if ( 0 == ($_ + 1) % 4 );

            # 選択済みで修正からの遷移の場合
            $obj->{IfMyLibraryBindingImageIsSelected}->[$_] = 1 if $obj->{character_id}->[$_] eq $obj->{my_library_binding_image_id};

        } 0..$#{ $obj->{character_id} };

        $obj->{$IfTag}  = 1;
        $obj->{$LoopTag} =  $#{ $obj->{character_id} };

        ## userid_cipheredを元に32文字のmy_item_idを生成
        $obj->{my_library_id}   = MyClass::WebUtil::createHash(join('', $self->userid_ciphered, time, $$, rand(9999)), 32);

        $obj->{IfStep1} = 1;

    }
    elsif ($obj->{IfStep2}) {
        #************************************
        # Step2 
        #************************************
        $obj->{my_library_id} = $my_library_id;
        $obj->{IfCheckValueError}   = 0; # 項目の内容不足フラグ 初期値は０としておく
        $obj->{IfCheckValueOK}      = 0; # 項目内容OKフラグ

        $obj->{CONTENTS_RESIZED_IMAGE_SCRIPTDATABASE_URL} = $ResizingScript;
        #my $my_library_binding_image_id = ;

        if(!$q->param('mlbii')) {
            $obj->{IfLibraryBindingImageIsNotSelected} = 1;
            $obj->{IfCheckValueError} = 1;
        }
        else {
            $obj->{IfLibraryBindingImageIsSelected} = 1;
            $obj->{my_library_binding_image_id} = $q->param('mlbii');
        }

        $obj->{my_library_name}         = $q->escapeHTML($q->param('my_library_name'));
        $obj->{my_library_description}  = $q->escapeHTML($q->param('my_library_description'));

        $obj->{IfCheckValueError} = 
            ( 1 == $obj->{IfLibraryBindingImageIsNotSelected} ) ? 1 :
            ( 4 > length($obj->{my_library_name}))              ? 1 :
            ( 8 > length($obj->{my_library_description}))       ? 1 :
                                                                  0 ;

        $obj->{IfCheckValueOK} = 1 if ! $obj->{IfCheckValueError};
    }
    elsif ($obj->{IfStep3}) {
        #************************************
        # Step3  図鑑基本データ・表紙画像の加工とINSERT
        #************************************

        $obj->{my_library_name}             = $q->param('my_library_name');
        $obj->{my_library_description}      = $q->param('my_library_description');
        #$obj->{my_library_name}             = $q->escapeHTML($q->param('my_library_name'));
        #$obj->{my_library_description}      = $q->escapeHTML($q->param('my_library_description'));

    #**************
    # 画像加工処理準備と処理
    #**************
        my ($contentsm_id, $categorym_id)   = split(/:/, $q->param('mlbii'));
        # コロンは削除して格納
        $obj->{my_library_binding_image_id} = $contentsm_id . $categorym_id;

        my $dbh = $self->getDBConnection();
        my $sql                      = sprintf("SELECT mime_type, image FROM %s.tContentsImageM WHERE contentsm_id=? AND categorym_id = ?;", $self->waf_name_space);
        my ($mime_type, $image_data) = $dbh->selectrow_array($sql, undef, $contentsm_id, $categorym_id);

        my ($resized_120_160_image_data, $resized_56_75_image_data);
        require Image::Magick;
        my $img = Image::Magick->new();
        my $err = $img->BlobToImage($image_data);
        $img->Scale(geometry=>'120x160');
        $resized_120_160_image_data = $img->ImageToBlob();
        $img->Scale(geometry=>'56x75');
        $resized_56_75_image_data = $img->ImageToBlob();

        undef $img;

    #**************
    # データベースINSERT HASH
    #**************
        my $InsertData = {
            my_library_id               => $my_library_id,
            gree_user_id                => $gree_user_id,
            status_flag                 => 1,
            my_library_binding_image_id => $obj->{my_library_binding_image_id},
            my_library_name             => $obj->{my_library_name},
            my_library_description      => $obj->{my_library_description},
        };

        my $InsertImageData = {
            my_library_id                   => $my_library_id,
            my_getimage_id                  => $obj->{my_library_binding_image_id},
            my_library_binding_image_flag   => 1,
            image                           => $resized_120_160_image_data,
            resized_image                   => $resized_56_75_image_data,
            mime_type                       => $mime_type,
        };

        my $myLibrary       = MyClass::JKZDB::MyLibrary->new($dbh);
        my $myLibraryImage  = MyClass::JKZDB::MyLibraryImage->new($dbh);
        my $attr_ref        = MyClass::UsrWebDB::TransactInit($dbh);

        eval {
            $self->setDBCharset("sjis");
            $myLibrary->executeUpdate($InsertData, -1);
            $self->setDBCharset("utf8");
            $myLibraryImage->executeUpdate($InsertImageData);

            $dbh->commit();
        };
        if ($@) {
            $dbh->rollback();
            $obj->{IfInsertDBError} = 1;
        }
        else {
            $obj->{IfInsertDBSuccess} = 1;
            
            $obj->{my_library_id}               = $my_library_id;
            $obj->{mblii}                       = sprintf("%s:%s", $contentsm_id, $categorym_id);
            $obj->{my_library_name}             = $q->escapeHTML($obj->{my_library_name});
            $obj->{my_library_description}      = $q->escapeHTML($obj->{my_library_description});
            $obj->{CONTENTS_RESIZED_IMAGE_SCRIPTDATABASE_URL} = $ResizingScript;
        }
        MyClass::UsrWebDB::TransactFin($dbh, $attr_ref, $@);

=pod
        ( 1 == $obj->{IfLibraryBindingImageIsNotSelected} ) ? $obj->{IfCheckValueError} = 1 : 
        ( 2 > length $obj->{my_library_name} ) ? $obj->{IfCheckValueError} = 1 : 
        ( 2 > length $obj->{my_library_description} ) ? $obj->{IfCheckValueError} = 1 : 
=cut

    }

    $obj->{s} = $q->param('s');#$self->userid_ciphered;

    return $obj;
}


#******************************************************
# @desc     図鑑用の画像登録
# @desc    Step4からStep5
# @param    
# @return   
#******************************************************
sub regist_my_library_image {
    my $self = shift;
    my $gree_user_id    = $self->opensocial_owner_id;
    my $q               = $self->query;
    my $obj;

    my $my_library_id   = $q->param('mli')  || undef;
    my $redo_flag       = $q->param('redo') || undef;
    my $opt             = $q->param('opt')  || undef;

    my $checkbox_allchecked = $q->param('ca') || 0;
    ## 全てチェックするが選択された場合の判定
    my @If_Loop_tag = ('GetResizedImageAllUnChecked', 'GetResizedImageAllChecked');
    my $IfTag       = sprintf("If%s", $If_Loop_tag[$checkbox_allchecked]);
    my $LoopTag     = sprintf("Loop%sList", $If_Loop_tag[$checkbox_allchecked]);

    # 画像サイズ生成プログラム
    my $ResizingScript = sprintf("%s%s", $self->MAIN_URL, $self->cfg->param('CONTENTS_RESIZED_IMAGE_SCRIPTDATABASE_NAME'));

    (5 == $opt && $my_library_id)                           ? $obj->{IfStep5} = 1 :
    (4 == $opt && $my_library_id)                           ? $obj->{IfStep4} = 1 :
                                                              $obj->{IfStep4} = 1 ;

    $obj->{my_library_id} = $my_library_id;
    $obj->{s} = $q->param('s');


    if ($obj->{IfStep4}) {
    #************************************
    # Step4 
    #************************************

        #************************************
        # 図鑑用アイテム取得
        #************************************
        my $namespace    = $self->waf_name_space() . '_gsa_user_mylibraryitem';
        my $itemobj      =  $self->memcached->get("$namespace:$gree_user_id");

        if (!$itemobj) {
            my $myItemobj = MyClass::JKZDB::MyItem->new($self->getDBConnection);
            $self->setDBCharset("sjis");
            my $aryref = $myItemobj->fetchMyItemForMyLibrary($gree_user_id);

            if ( 0 <= $#{ $aryref } ) {
                map {
                    my $cnt = $_;
                    foreach my $key (keys %{ $aryref }) {
                        $itemobj->{$key}->[$cnt]    = $aryref->[$cnt]->{$key};
                        $itemobj->{Escapeditem_name}->[$cnt] = $q->escape($aryref->[$cnt]->{item_name});
                    }
                } 0..$#{ $aryref };

               $itemobj->{LoopMyItemForMyLibraryList} = $#{ $aryref };
               $itemobj->{IfExistsMyItemForMyLibrary} = 1;
            }
            else {
                $itemobj->{IfNotExistsMyItemForMyLibrary} = 1;
            }
                $self->memcached->add("$namespace:$gree_user_id", $itemobj, 600);
        }

        map { $obj->{$_} = $itemobj->{$_} } keys %{ $itemobj };

        #************************************
        # 図鑑用画像リスト
        #************************************
        my $checkbox_allchecked = $q->param('ca') || 0;

        ## 全てチェックするが選択された場合の判定
        my @If_Loop_tag = ('GetResizedImageAllUnChecked', 'GetResizedImageAllChecked');
        my $IfTag       = sprintf("If%s", $If_Loop_tag[$checkbox_allchecked]);
        my $LoopTag     = sprintf("Loop%sList", $If_Loop_tag[$checkbox_allchecked]);

        my $myContentsCategory  = MyClass::JKZDB::MyContentsStatus->new($self->getDBConnection);
        my $my_getimage_id_ref  = $myContentsCategory->getAllSetOfCategoryID($gree_user_id);

        foreach my $ref (@{ $my_getimage_id_ref }) {
            my @tmp = split(/,/, $ref->{sum_category_id});
            map { push @{ $obj->{character_id} }, sprintf("%s:%s", $ref->{contentsm_id}, (log($_) / log(2))) } @tmp;
        }
        map {
            $obj->{LCONTENTS_RESIZED_IMAGE_SCRIPTDATABASE_URL}->[$_] = $ResizingScript; 
            $obj->{IfBR}->[$_] = 1 if ( 0 == ($_ + 1) % 4 );
        } 0..$#{ $obj->{character_id} };

        $obj->{$IfTag}  = 1;
        $obj->{$LoopTag} =  $#{ $obj->{character_id} };
    }
    elsif ($obj->{IfStep5}) {
    #************************************
    # Step5 
    #************************************

        my @selectedimage = $q->param('mgi');
        $obj->{mgi} = $q->param('mgi');
        if (0 > scalar @selectedimage) {
            $obj->{IfMyLibraryImageIsNotSelected} = 1;
            $obj->{IfCheckValueError} = 1;
        }
        else {
            $obj->{IfMyLibraryImageIsSelected} = 1;
            $obj->{LoopMyLibraryImageList} = $#selectedimage;
            foreach my $idx (0..$#selectedimage) {
                $obj->{my_getimage_id}->[$idx] = $selectedimage[$idx];
                $obj->{IfBR}->[$idx] = 1 if ( 0 == ($idx + 1) % 4 );
             }
        }

        #************************************
        # 図鑑用ｱｲﾃﾑが選択されてる場合
        #************************************
        if($q->param('mii_n')) {
            #my ($my_item_id, $itemm_id, $Escapeditem_name) = split(/:/, $q->param('mii_n'));
            ( $obj->{my_item_id}, $obj->{itemm_id}, $obj->{Escapeditem_name} ) = split(/:/, $q->param('mii_n'));
            $obj->{item_name} = $q->unescape($obj->{Escapeditem_name});
            $obj->{IfMyItemForMyLibraryIsSet} = 1;
        }
        else {
            $obj->{IfMyItemForMyLibraryIsNotSet} = 1;
        }

        $obj->{IfCheckValueOK} = 1 if ! $obj->{IfCheckValueError};
    $obj->{DUMP} = scalar @selectedimage;
    }

        #$obj->{LoopGetResizedImageList} = $#{ $obj->{character_id} };

    return $obj;
}


1;
__END__