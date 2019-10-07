#******************************************************
# @desc      画像管理クラス
# @package   MyClass::JKZApp::AppImage
# @access    public
# @author    Iwahase Ryo
# @create    2009/02/26
# @update    2009/05/26    AM uploadSwfFile
#                          AM _storeSwfData
# @update     2009/06/26    AM _convertImageForEmoji            ┓
# @update     2009/06/26    AM _convertImageForPuchiDecoDecome    ┣これらのメソッドは戻り値は必ず３つ（不足分はundefを返す）
# @update     2009/06/26    AM _convertImageForDecoTmpltFlash    ┛
# @update     2009/06/30    MyClass::JKZDB::ProductImageの廃止
# @update     2010/01/16    _convertImageFor追加
# @update     2009/06/26    
# @update     2009/06/26    
# @update     2009/06/26    
# @version    1.00
#******************************************************
package MyClass::JKZApp::AppImage;

use 5.008005;
our $VERSION = '1.00';

use strict;
use base qw(MyClass::JKZApp);

use MyClass::WebUtil;
use MyClass::JKZDB::SiteImage;

use Image::Magick;

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

    !defined($self->query->param('action')) ? $self->action('imageTopMenu') : $self->action();

    $self->SUPER::dispatch();
}


#******************************************************
# @access    
# @desc      
# @param     
# @param     
# @return    
#******************************************************
sub imageTopMenu {
    my $self = shift;
    my $q    = $self->query();
    my $obj  = $self->_getSiteImageList($self->_myMethodName());

    $obj->{LoopImageList} = $obj->{countRec};
    if ( 0 <= $obj->{LoopImageList}) {
        foreach my $i (0..$obj->{countRec}) {
            ## まだループがあるとき
            unless ($i == $obj->{LoopImageList}) {
                ## 3個の場合
                $obj->{TR}->[$i] = (0 == ($i+1) % 3 ) ? '</tr><tr><!-- auto generated end tag and begin tag -->' : "";
            } else { ## 最終ループで終わりのとき
                ## 3個の場合
                $obj->{TR}->[$i] =
                    (0 == ($i+1) % 3 ) ? '</tr><!-- auto generated tr end tag -->'                         :
                    (2 == ($i+1) % 3 ) ? '<td></td></tr><!-- auto generated one pair of td tag tr end tag -->'         :
                                         '<td></td><td></td></tr><!-- auto generated two pair of td tag tr end tag -->';
            }
        }
        $obj->{IfExistsImages} = 1;
    }
    else {
        $obj->{IfNotExistsImages} = 1;
    }

    return $obj;
}


#******************************************************************************************************************************************************

#******************************************************
# @access   
# @desc     画像リスト
# @param    
# @param    
# @return   
#******************************************************
sub siteImageList {
    my $self = shift;
    my $obj  = $self->_getSiteImageList($self->_myMethodName());

    $obj->{LoopImageList} = $obj->{countRec};

    map { $obj->{cssstyle}->[$_] = 0 == $_ % 2 ? 'focusodd' : 'focuseven' } 0..$obj->{countRec};

    return $obj;
}


#******************************************************
# @access    private
# @desc        画像のリストデータ取得
# @param    
# @param    
# @return    obj
#******************************************************
sub _getSiteImageList {
    my $self   = shift;
    my $caller = shift;

    #*************************
    # 画像情報の取得
    #*************************
    my $record_limit    = 21;
    my $offset          = $self->query->param('off') || 0;
    my $condition_limit = $record_limit+1;

    my $obj = {};
    my $dbh = $self->getDBConnection();
    ## 文字化け防止
    $dbh->do('set names sjis');
    my $ImageList = MyClass::JKZDB::SiteImage->new($dbh);

    my $maxrec    = $ImageList->getCountSQL(
                        {
                            columns     =>  "id",
                            orderbySQL  => 'id DESC',
                            limitSQL    => "$offset, $condition_limit",
                        }
                    );

    my @navilink;
    ## レコード数が1ページ上限数より多い場合
    if ($maxrec > $record_limit) {
        #my $myname = $self->_myMethodName();
        my $url    = sprintf("app.mpl?app=AppImage;action=%s", $caller);

    ## 前へページの生成
        if (0 == $offset) { ## 最初のページの場合
            push(@navilink, "<font size=-1>&lt;&lt;前</font>&nbsp;");
        } else { ## 2ページ目以降の場合
            push(@navilink, $self->genNaviLink($url, "<font size=-1>&lt;&lt;前</font>&nbsp;", $offset - $record_limit));
        }

    ## ページ番号生成
        for (my $i = 0; $i < $maxrec; $i += $record_limit) {

            my $pageno = int ($i / $record_limit) + 1;

            if ($i == $offset) { ###現在表示してるﾍﾟｰｼﾞ分
                push (@navilink, '<font size=+1>' . $pageno . '</font>');
            } else {
                push (@navilink, $self->genNaviLink($url, $pageno, $i));
            }
        }

    ## 次へページの生成
        if (($offset + $record_limit) > $maxrec) {
            push (@navilink, "&nbsp;<font size=-1>次&gt;&gt;</font>");
        } else {
            push (@navilink, $self->genNaviLink($url, "&nbsp;<font size=-1>次&gt;&gt;</font>", $offset + $record_limit));
        
        }

        @navilink = map{ "$_\n" } @navilink;

        $obj->{pagenavi} = sprintf("<font size=-1>[全%s件 / %s件\表\示]</font><br />", $maxrec, $record_limit) . join(' ', @navilink);
    }


    $ImageList->executeSelectList ({
                            orderbySQL  => 'id DESC',
                            limitSQL    => "$offset, $record_limit",
                        });

    $obj->{countRec} = $ImageList->countRecSQL();
    if ( 0 <= $obj->{countRec}) {
        foreach my $i (0..$obj->{countRec}) {
            map { $obj->{$_}->[$i] = $ImageList->{columnslist}->{$_}->[$i] } keys %{$ImageList->{columnslist}};
        }
    }

    return $obj;
}



#******************************************************
# @access   public
# @desc     画像を格納新規 は複数OK
# @desc     画像更新はひとつづつ
# @         問題点あり。画像格納処理完了後のページ表示がまだ 2009/02/27
#         ↑修正済み2009/08/28
#******************************************************
sub uploadSiteImage {
    my $self = shift;
    my $q    = $self->query();
    my $obj  = {};

    if (!$q->param('image')) {
        $obj->{ERRORMSG} = '画像がありません。選択してください。';
        $obj->{IfHistoryBack} = 1;

        return $obj;
    }

    my @imagef      = $q->upload('image');
    my @description = $q->param('description');

    ## 新規のときはauto_incrementでDB依存。データ更新時は単一処理だけなのでoｋ
    my $id          = defined($q->param('id')) && 0 < $q->param('id') ? $q->param('id') : "-1";
    my $cnt = 0;
    foreach my $fh (@imagef) {

        my $mime_type = $q->uploadInfo($fh)->{'Content-Type'};

        require Image::Magick;
        my $imgObj = Image::Magick->new();
        my $imagedata;
        (read($fh, $imagedata, -s $fh) == -s $fh);

        my $err = $imgObj->BlobToImage($imagedata);
        die "Can't convert image data: $err" if $err;

        my ($width, $height) = $imgObj->Get('width', 'height');

        ## image/x-png や image/pjpeg だとSBとAUで表示できないので修正
        $mime_type =~ s!(^image/)x-(png)$!$1$2!;
        $mime_type =~ s!(^image/).+?(jpeg)$!$1$2!;

        use NKF;
        my $InsertImage = {
            id          => $id,
            image       => $imagedata,
            width       => $width,
            height      => $height,
            mime_type   => $mime_type,
            description => nkf('-w', $description[$cnt]),
        };

        if (!$self->_storeSiteImage($InsertImage)) {
            $obj->{ERROR_MSG} = "Image Data Insert Failed Operation is aborted";
            ## DBインサート失敗
            $obj->{IfInsertDBFail} = 1;
            return $obj;
        } else {
            $obj->{IfInsertDBSuccess} = 1;
        }
        $cnt++;
    }

    $self->action('imageTopMenu');
    $self->imageTopMenu();
}


#******************************************************
# @access    private
# @desc        サイト内画像を格納
# @param
# @param
# @return    boolean
#******************************************************
sub _storeSiteImage {
    my ($self, $data) = @_;

    my $dbh = $self->getDBConnection();
    $dbh->do('set names utf8');
    my $Image = MyClass::JKZDB::SiteImage->new($dbh);
    if (!$Image->executeUpdate($data)) {
        return -1;
    }
    ## Modified Replaceでデータを格納しているから、上書きの場合はinsert_idを取得できないからコメントアウト 2010/03/05
    ## サイトの画像管理ではデータアップ後にその画像のIDは不要だから問題が無い
    #my  $insert_id = $Image->mysqlInsertIDSQL();
    #return $insert_id;
    return 1;
}


#******************************************************
# @access    public
# @desc        画像削除
# @param
# @param
# @return    boolean
#******************************************************
sub deleteSiteImage {
    my $self = shift;
    my $q    = $self->query();
    my $obj  = {};

    unless ($q->param('i')) {
        $obj->{IfNoIDSelected} = 1;
        return $obj;
    }

    my $id    = $q->param('i');
    my $dbh   = $self->getDBConnection();
    my $Image = MyClass::JKZDB::SiteImage->new($dbh);

    if (!$Image->deleteImageSQL($id)) {

            $obj->{ERROR_MSG} = "Delete Image Data Failed Operation is aborted";
            ## DB削除失敗
            $obj->{IfDeleteDBFail} = 1;
            return $obj;
    }

    $obj->{id}                 = $id;
    $obj->{IfDelelteDBSuccess} = 1;
    $self->flushAllFromCache();

    return $obj;
}

#******************************************************************************************************************************************************


#******************************************************
# @access   クラスメソッドではない
# @desc     画像を変換
# @param    240x320 60x の2パターンの画像を生成
# @param
# @param    filehandle $fh(画像のファイルハンドル)
# @return    $image_data, $resized_image_data
#******************************************************
sub _convertImageFor {
    my $fh = shift;

    my ($err, $image_data, $resized_60_75_image_data, $resized_30_38_image_data);
    #**********************************
    # 画像の読みこみとデータ化
    #**********************************
    my $img = Image::Magick->new();

    (read($fh, $image_data, -s $fh) == -s $fh)
        or die ("Can't read image file: $!");
    $err = $img->BlobToImage($image_data);
    die "Can't read image file: $err\n" if $err;

    my ($width, $height) = $img->Get('width','height');

    $img->Scale(geometry=>"$width x $height");
    $image_data = $img->ImageToBlob();
    #$img->Scale(geometry=>"$resized_width x $resized_height");
    $img->Scale(geometry=>'60x75');
    $resized_60_75_image_data = $img->ImageToBlob();
    $img->Scale(geometry=>'30x38');
    $resized_30_38_image_data = $img->ImageToBlob();

    return ($image_data, $resized_60_75_image_data, $resized_30_38_image_data);
}


1;

__END__