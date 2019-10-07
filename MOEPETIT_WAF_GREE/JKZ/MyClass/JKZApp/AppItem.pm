#******************************************************
# @desc      アイテム管理クラス
# @package   MyClass::JKZApp::AppItem
# @access    public
# @author    Iwahase Ryo
# @create    2011/03/30
# @update    
# @version   1.00
#******************************************************
package MyClass::JKZApp::AppItem;

use 5.008005;
our $VERSION = '1.00';
use strict;

use base qw(MyClass::JKZApp);

use MyClass::JKZApp::AppDataTransfer;


use MyClass::JKZDB::ItemCategory;
use MyClass::JKZDB::Item;
use MyClass::JKZDB::ItemImage;
#use MyClass::JKZDB::ContentsItem;
#use MyClass::JKZDB::ContentsImage;

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


#******************************************************
# @access    public
# @desc        親クラスのメソッド
# @param    
#******************************************************
sub dispatch {
    my $self = shift;
    !defined($self->query->param('action')) ? $self->action('registItem') : $self->action();
    $self->SUPER::dispatch("IfAppContents");
}


sub viewItemCategoryList {
    my $self = shift;
    my $q    = $self->query();

    my $record_limit    = 20;
    my $offset          = $q->param('off') || 0;
    my $condition_limit = $record_limit+1;
    my $obj;

    my $contentsitemcategorylist = $self->fetchContentsItemCategory($condition_limit, $offset);
    $obj->{LoopItemCategoryList} = $#{$contentsitemcategorylist->{item_category_id}} - 1;

    if (0 <= $obj->{LoopItemCategoryList}) {
        $obj->{IfExistsItemCategoryList} = 1;

        my @IfStatus_flag = ('IfInvalid', 'IfValid',);

        for (my $i =0; $i <= $obj->{LoopItemCategoryList}; $i++) {
            map { $obj->{$_}->[$i] = $contentsitemcategorylist->{$_}->[$i+1] } keys %{$contentsitemcategorylist};

            $obj->{status_flagDescription}->[$i]    = $self->fetchOneValueFromConf('STATUS', ($obj->{status_flag}->[$i]-1));
            $obj->{status_flagImages}->[$i]         = $self->fetchOneValueFromConf('STATUSIMAGES', ($obj->{status_flag}->[$i]-1));
            $obj->{item_category_description}->[$i] = MyClass::WebUtil::escapeTags($obj->{item_category_description}->[$i]);
            $obj->{registration_date}->[$i]         =~ s!-!/!g;
            $obj->{EncodedItemCategoryName}->[$i]   = $q->escape($obj->{item_category_name}->[$i]);
            $obj->{$IfStatus_flag[$obj->{status_flag}->[$i] - 1]}->[$i] = 1;
         }

         $obj->{rangeBegin} = ($offset+1);
         $obj->{rangeEnd}   = ($obj->{rangeBeginCT}+$obj->{LoopItemCategoryList});

         if ($record_limit == $obj->{LoopCategoryList}) {
             $obj->{offsetTOnext} = (0 < $offset) ? ($offset + $condition_limit - 1) : $record_limit;
             $obj->{IfNextData}   = 1;
         }
         if ($record_limit <= $offset) {
             $obj->{offsetTOprevious} = ($offset - $condition_limit + 1);
             $obj->{IfPreviousData}   = 1;
         }
     }
     else {
         $obj->{IfNotExistsItemCategoryList} = 1;
     }

    return $obj;
}


#******************************************************
# @access    public
# @desc      アイテム一覧
# @param    
# @return    
#******************************************************
sub viewItemList {
    my $self = shift;
    my $q    = $self->query();

    my $record_limit    = 20;
    my $offset          = $q->param('off') || 0;
    my $condition_limit = $record_limit+1;

    my $namespame = $self->waf_name_space() . 'AppItemList';
    my $obj       = $self->memcached->get("$namespame");

    if (!$obj) {
        my $dbh = $self->getDBConnection();
        $self->setDBCharset('sjis');

        my $cmsItemList = MyClass::JKZDB::Item->new($dbh);
        $cmsItemList->executeSelectList();
        map { $obj->{$_} = $cmsItemList->{columnslist}->{$_} } keys %{ $cmsItemList->{columnslist} };

        $self->memcached->add("$namespame", $obj, 600);
       }

    $obj->{LoopItemList} = $#{ $obj->{item_id} } - 1;
    if (0 <= $obj->{LoopItemList}) {
        $obj->{IfExistsItemList} = 1;

        my $itemcategoryobj = $self->getFromObjectFile( { CONFIGURATION_VALUE => 'ITEMCATEGORYLIST_OBJ' } );

        my @IfStatus_flag = ('IfInvalid', 'IfValid',);
        map {
            $obj->{ITEM_ID}->[$_]                = ($obj->{item_categorym_id}->[$_] + $obj->{item_id}->[$_]);
            $obj->{category_id}->[$_]            = ($obj->{item_categorym_id}->[$_] / 1000);
            $obj->{item_category_name}->[$_]     = $itemcategoryobj->[$obj->{category_id}->[$_]]->{item_category_name};
            $obj->{status_flagDescription}->[$_] = $self->fetchOneValueFromConf('STATUS', ($obj->{status_flag}->[$_]-1));
            $obj->{status_flagImages}->[$_]      = $self->fetchOneValueFromConf('STATUSIMAGES', ($obj->{status_flag}->[$_]-1));
            $obj->{item_detail}->[$_]            = MyClass::WebUtil::escapeTags($obj->{item_detail}->[$_]);
            $obj->{registration_date}->[$_]      =~ s!-!/!g;
            $obj->{ITEMTYPEJP}->[$_]             = MyClass::WebUtil::convertByNKF('-s', $self->fetchOneValueFromConf('ITEMTYPEJP', ( log($obj->{item_type}->[$_]) / log(2) ) ));
            $obj->{$IfStatus_flag[$obj->{status_flag}->[$_] - 1]}->[$_] = 1;
            $obj->{LITEMIMAGE_SCRIPTDATABASE_URL}->[$_] = $self->CONFIGURATION_VALUE('ITEM_IMAGE_SCRIPTDATABASE_NAME');
            $obj->{SetComma}->[$_] = $_ < $obj->{LoopItemList} ? ',' : '';
        }0..$obj->{LoopItemList};
    }
    else {
        $obj->{IfNotExistsItemList} = 1;
    }

    return $obj;
}


#******************************************************
# @access    public
# @desc      アイテム登録
# @param    
# @return    
#******************************************************
sub registItem {
    my $self = shift;
    my $q    = $self->query();
    $q->autoEscape(0);

    my $record_limit    = 30;
    my $offset          = $q->param('off') || 0;
    my $condition_limit = $record_limit+1;

    my $obj = {};

    defined($q->param('md5key')) ? $obj->{IfConfirmItemForm} = 1 : $obj->{IfRegistItemForm} = 1;

    $obj->{md5key} = MyClass::WebUtil::createHash($self->__session_id(), 20);

    if ( $obj->{IfConfirmItemForm} ) {

        ( $obj->{item_category_id}, $obj->{EncodedItemCategoryName}) = split(/;/, $q->param('item_category_id'));

        $obj->{IfItemNameIsEmpty}           = 1 if 6 > length($q->param('item_name'));
        $obj->{IfItemCategoryIsNotSelected} = 1 if 1 > $obj->{item_category_id};
        $obj->{IfItemDescriptionIsEmpty}    = 1 if 6 > length($q->param('item_description'));
        $obj->{IfItemDetailIsEmpty}         = 1 if 6 > length($q->param('item_detail'));
        $obj->{IfItemImageIsEmpty}          = 1 if !$q->upload('image');
        $obj->{IfRequirementNotFilled}      = 1 if 0 < ( $obj->{IfItemNameIsEmpty} + $obj->{IfItemCategoryIsNotSelected} + $obj->{IfItemDescriptionIsEmpty} + $obj->{IfItemDetailIsEmpty} + $obj->{IfItemImageIsEmpty} );

    #****************************
    # データ不十分のためエラー
    #****************************
        return $obj if 1 == $obj->{IfRequirementNotFilled};

        my $image = MyClass::JKZApp::AppDataTransfer->new();
        # 画像は別にパブリッシュする必要があるから
        #$obj->{image}     = $image->uploadImageData()->{image};
        $obj->{mime_type} = $image->uploadImageData()->{mime_type};

        $obj->{item_category_name} = $q->unescape($obj->{EncodedItemCategoryName});
      # アイテムカテゴリIDはアイテムカテゴリマスターのID値ｘ1000
        $obj->{item_categorym_id}  = ( $obj->{item_category_id} * 1000 );
        $obj->{status_flag}        = $q->param('status_flag');
        $obj->{item_type}          = 2 ** $q->param('item_type');
        $obj->{item_name}          = $q->escapeHTML($q->param('item_name'));
        $obj->{item_description}   = $q->escapeHTML($q->param('item_description'));
        $obj->{item_detail}        = $q->escapeHTML($q->param('item_detail'));
        $obj->{item_unit_price}    = $q->param('item_unit_price') || 0;

        my $publish = $self->PUBLISH_DIR() . '/admin/' . $obj->{md5key};
        MyClass::WebUtil::publishObj({file=>$publish, obj=>$obj});

        # 画像をパブリッシュ。パブリッシュ名はmd5key+mime_type
        # 画像は管理画面ドキュメントルート/tmpに格納(Webからみえるようにする)
        $obj->{image} = $image->uploadImageData()->{image};
        my $tmp_image = $obj->{mime_type};
        $tmp_image    =~ s!(^image/)(.+?)!$2!;
        $tmp_image    = $obj->{md5key} . '.' . $tmp_image;
        my $data;

        $publish              = sprintf("%s/admin/%s", $self->PUBLISH_DIR(), $tmp_image);
        my $publish_link      = sprintf("%s/tmp/%s", $self->CONFIGURATION_VALUE("CMS_DOCUMENT_ROOT"), $tmp_image);

        #$publish              = sprintf("%s/admin/%s.%s", $self->PUBLISH_DIR(), $obj->{md5key}, $image_ext);
        #$obj->{publish_image} = sprintf("/tmp/%s.%s", $obj->{md5key}, $image_ext);
=pod
        MyClass::WebUtil::publishObj({
            file =>$publish,
            obj  => {
                #imagedata => $obj->{image},
                imagedata => $q->upload('image'),
                mime_type => $obj->{mime_type},
            }
        });
=cut
        open (STORAGE, ">$publish") or die "Error: $publish $!\n";
        if ($obj->{mime_type} !~ /text/) {
            binmode ($obj->{image});
            binmode (STORAGE);
        }
        while( read($obj->{image}, $data, 1024) ) { print STORAGE $data; }
        close STORAGE;

        ## Webで表示できるようにシンボリックリンクを作成
        if (-e $publish_link) {
            unlink($publish_link);
        }
        if (symlink($publish, $publish_link)) {
            $obj->{publish_image} = sprintf("/tmp/%s", $tmp_image);
        }


        2 == $obj->{status_flag} ? $obj->{IfStatusFlagIsActive} = 1 : $obj->{IfStatusFlagIsNotActive} = 1;
        $obj->{ITEMTYPEJP} = MyClass::WebUtil::convertByNKF('-s', $self->fetchOneValueFromConf('ITEMTYPEJP', $q->param('item_type')));

        $obj->{IfRequirementFilled} = 1;
    }
    elsif ($obj->{IfRegistItemForm}) {

        my $itemcategorylist = $self->viewItemCategoryList();
        map { $obj->{$_} = $itemcategorylist->{$_} } keys %{ $itemcategorylist };
        my $itemtype = $self->fetchItemType;
        map { $obj->{$_} = $itemtype->{$_} } keys %{ $itemtype };
    }

    return  $obj;
}



#******************************************************
# @access    public
# @desc        商品情報更新/新規登録
# @param    
#******************************************************
sub modifyItem {
    my $self = shift;

    my $q = $self->query();
    my $obj = {};

    if (!$q->MethPost()) {
        $obj->{ERROR_MSG} = $self->ERROR_MSG("ERR_MSG18");
    }

    my $updateData = {
        item_categorym_id=> undef,
        status_flag      => undef,
        item_id          => undef,
        item_type        => undef,
        item_name        => undef,
        item_unit_price  => undef,
        item_description => undef,
        item_detail      => undef,
    };

    my $imageData  = {
        itemm_id  => undef,
        image     => undef,
        mime_type => undef,
    };

    my $publish = sprintf("%s/admin/%s", $self->PUBLISH_DIR(), $q->param('md5key'));
    my $image_file;
    eval {
        my $publishobj = MyClass::WebUtil::publishObj( { file=>$publish } );
        map { exists($updateData->{$_}) ? $updateData->{$_} = $publishobj->{$_} : "" } keys%{$publishobj};

        if (exists( $publishobj->{mime_type} )) {
            my $image_ext = $publishobj->{mime_type};
            $image_ext    =~ s!(^image/)(.+?)!$2!;

            $image_file = sprintf("%s/admin/%s.%s", $self->PUBLISH_DIR(), $q->param('md5key'), $image_ext);

            #**********************************
            # 画像の読みこみとデータ化
            #**********************************
            $imageData->{image} = MyClass::JKZApp::AppDataTransfer::image2Blob($image_file);
            $imageData->{mime_type} = $publishobj->{mime_type};

        }
=pod
        if (exists( $publishobj->{image} )) {
            $imageData->{image}     = $publishobj->{image};
            $imageData->{mime_type} = $publishobj->{mime_type};
        }
=cut
        if (1 > $updateData->{item_id}) {
            $updateData->{item_id} = -1;
            $obj->{IfRegistItem} = 1;
        } else {
            $obj->{IfModifyItem} = 1;
        }
    };
    ## パブリッシュオブジェクトの取得失敗の場合
    if ($@) {

    } else {
        my $dbh = $self->getDBConnection();
        my $cmsItem = MyClass::JKZDB::Item->new($dbh);
        ## autocommit設定をoffにしてトランザクション開始
        my $attr_ref = MyClass::UsrWebDB::TransactInit($dbh);
        eval {

            $cmsItem->executeUpdate($updateData);
            ## 新規の場合にproduct_idが何かをわかるように mysqlInsertIDSQLはcommitの前で取得
            #$obj->{item_id_is} = $obj->{IfRegistItem} ? $cmsItem->mysqlInsertIDSQL() : $updateData->{item_id};
            $obj->{item_id_is} = ( 0 > $updateData->{item_id} ) ? $cmsItem->mysqlInsertIDSQL() : $updateData->{item_id};

            $dbh->commit();
            $obj->{item_name}         = $updateData->{item_name};
            $obj->{item_id}           = $updateData->{item_id};
            $obj->{item_categorym_id} = $updateData->{item_categorym_id};

            map { $obj->{$_} = $updateData->{$_} } qw(item_type item_unit_price item_description item_detail);

            #**************************
            # アイテム画像格納
            #**************************
            if ($imageData->{image}) {
                $imageData->{itemm_id}          = ( $updateData->{item_categorym_id} + $obj->{item_id_is} );
#                $imageData->{item_categorym_id} = $updateData->{item_categorym_id};
                #my $appDataTransfer             = MyClass::JKZApp::AppDataTransfer->new();
                #$appDataTransfer->storeItemImageData($imageData);

                use MyClass::JKZDB::ItemImage;
                $dbh->do("set names utf8");
                my $Image = MyClass::JKZDB::ItemImage->new($dbh);
                $Image->executeUpdate($imageData);
                $obj->{itemm_id} = $imageData->{itemm_id};
            }


            ## シリアライズオブジェクトの破棄
            MyClass::WebUtil::clearObj($publish);
            unlink($image_file);
        };
        ## 失敗のロールバック
        if ($@) {
            $dbh->rollback();
            $obj->{ERROR_MSG} = Dumper($@);
            $obj->{ERROR_MSG} .= MyClass::WebUtil::convertByNKF('-s', $self->ERROR_MSG("ERR_MSG20"));
            
            $obj->{IfFailExecuteUpdate} = 1;
        } else {
            ## キャッシュから古いデータをなくすため全て削除
            $self->flushAllFromCache();

            2 == $obj->{status_flag} ? $obj->{IfStatusFlagIsActive} = 1 : $obj->{IfStatusFlagIsNotActive} = 1;
            $obj->{item_category_name} = $self->getFromObjectFile({ CONFIGURATION_VALUE=>'ITEMCATEGORYLIST_OBJ', subject_id=> ($obj->{item_categorym_id} / 1000) });
            $obj->{ITEMTYPEJP} = MyClass::WebUtil::convertByNKF('-s', $self->fetchOneValueFromConf('ITEMTYPEJP', ( log($obj->{item_type}) / log(2) ) ));


            $obj->{IfSuccessExecuteUpdate} = 1;

        }
        ## autocommit設定を元に戻す
        MyClass::UsrWebDB::TransactFin($dbh, $attr_ref, $@);
        undef($cmsItem);
    }
    my $namespame = $self->waf_name_space() . 'AppItemList';
    $self->memcached->delete($namespame);
    return $obj;
}



sub detailItemCategory {
    my $self = shift;
    my $q    = $self->query();
    $q->autoEscape(0);
	my $obj;

    defined($q->param('md5key')) ? $obj->{IfConfirmItemCategoryForm} = 1 : $obj->{IfModifyItemCategoryForm} = 1;

    $obj->{md5key} = MyClass::WebUtil::createHash($self->__session_id(), 20);
    ## こちらの評価を先にする。パブリッシュするため
    #*********************************
    # 更新情報をシリアライズ
    #*********************************
    if ($obj->{IfConfirmCategoryForm}) {
        $obj->{category_id}        = $q->param('item_category_id');
        $obj->{status_flag}        = $q->param('status_flag');
        $obj->{category_name}      = $q->param('item_category_name');
        $obj->{description}        = $q->escapeHTML($q->param('item_category_description'));
        $obj->{description_detail} = $q->escapeHTML($q->param('item_category_warning'));
        ## 現在は未使用 2009/03/18
        #$obj->{rank}                = $q->param('rank') || 0;

        my $publish = $self->PUBLISH_DIR() . '/admin/' . $obj->{md5key};
        MyClass::WebUtil::publishObj({file=>$publish, obj=>$obj});

        2 == $obj->{status_flag} ? $obj->{IfStatusFlagIsActive} = 1 : $obj->{IfStatusFlagIsNotActive} = 1;

    }
    elsif ($obj->{IfModifyCategoryForm}) {
		my $item_category_id = $q->param('item_category_id');
	    my $namespame 	= $self->waf_name_space() . 'AppContentsItemCategory';
	    my $cacheobj	= $self->memcached->get("$namespame:$item_category_id");

		if (!$cacheobj) {
	        my $dbh         = $self->getDBConnection();
	        $self->setDBCharset('sjis');
	        my $cmsItemCategory = MyClass::JKZDB::ItemCategory->new($dbh);

	        if (!$cmsItemCategory->executeSelect( { whereSQL => "item_category_id=?", placeholder => [$item_category_id,] } )) {
	            $obj->{DUMP} = "データの取得失敗のまき";
	        } else {

	            map { $obj->{$_} = $cmsItemCategory->{columns}->{$_} } keys %{ $cmsItemCategory->{columns} };
	            $obj->{item_category_description}   = $q->escapeHTML($obj->{item_category_description});
	            $obj->{item_category_warning}		= $q->escapeHTML($obj->{item_category_warning});
	            2 == $obj->{status_flag} ? $obj->{IfStatusFlagIsActive} = 1 : $obj->{IfStatusFlagIsNotActive} = 1;
	        }

	        $self->memcached->add("$namespame:$item_category_id", $obj, 600);

	        undef($cmsItemCategory);
		}
    }

    return $obj;

}


#******************************************************
# @access    public
# @desc      item type
# @param    
#******************************************************
sub fetchItemType {
    my $self         = shift;
    my $obj          = {};
    my $itemtypeobj  = $self->fetchValuesFromConf("ITEMTYPEJP");
    map { $obj->{$_} = $itemtypeobj->{$_}  } %{ $itemtypeobj };

    $obj->{LoopITEMTYPEJPList} = $obj->{LoopITEMTYPEJPList} - 1;
    ## タイプで「ノーマル」は不要のためデータから削除
    shift @{ $obj->{ITEMTYPEJPValue} };
    shift @{ $obj->{ITEMTYPEJPIndex} };

    return $obj;
}


#******************************************************
# @access    public
# @desc        カテゴリリスト
# @param    
#******************************************************
sub fetchContentsItemCategory {
    my $self      = shift;
    my $namespame = $self->waf_name_space() . 'AppContentsItemCategorylist';
    my $obj       = $self->memcached->get("$namespame");

    if (!$obj) {
        my $dbh = $self->getDBConnection();
        $self->setDBCharset('SJIS');

        my $cmsContentsItemCategorylist = MyClass::JKZDB::ItemCategory->new($dbh);
        $cmsContentsItemCategorylist->executeSelectList();
        map { $obj->{$_} = $cmsContentsItemCategorylist->{columnslist}->{$_} } keys %{$cmsContentsItemCategorylist->{columnslist}};

        $self->memcached->add("$namespame", $obj, 600);

        undef($cmsContentsItemCategorylist);
    }

    return $obj;
}


1;

__END__