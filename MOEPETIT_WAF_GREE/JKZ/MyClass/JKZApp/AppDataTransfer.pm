#******************************************************
# @desc      コンテンツのデータ管理クラス flash deco template
# @package   MyClass::JKZApp::AppDataTransfer
# @access    public
# @author    Iwahase Ryo
# @create    2009/05/28
# @update    2009/07/02    画像データ変換と登録機能追加
# @update                 _convertImageForEmoji  _convertImageForPuchiDecoDecome _convertImageForDecoTmpltFlash
# @update    2009/07/02    AM convert_insert_SampleImage
# @update    2011/04/04    image2Blob関数を追加
# 依存ライブラリのインスコ 2010/1/16
# Data-TemporaryBag-0.09
# SWF-File-0.42
# SWF-Header-0.04
#
# @version   1.00
#******************************************************
package MyClass::JKZApp::AppDataTransfer;

use 5.008005;
our $VERSION = '1.00';

use strict;
use Carp qw(confess);


use base qw(MyClass::JKZApp);

use MyClass::WebUtil;

use MyClass::JKZApp::AppImage;
use MyClass::JKZDB::Contents;
#use MyClass::JKZDB::ContentsSwf;
use MyClass::JKZDB::ContentsImage;
use MyClass::JKZDB::ItemImage;


#use SWF::Header;

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

    $self->SUPER::dispatch();
}


#******************************************************
# @access    public
# @desc        コンテンツ登録とそのコンテンツの付随する画像の登録
# @desc        画像更新はひとつづつ
#******************************************************
sub registContents_with_ImageData {
    my $self = shift;
    my $q    = $self->query();
    my $obj  = {};

    #********************************
    # 一連のエラー処理
    #********************************
=pod
    if (!$q->param('swffile')) {
        $obj->{IfError}       = 1;
        $obj->{ERROR_MSG}      = MyClass::WebUtil::convertByNKF('-s', 'フラッシュファイルがありません。選択してください。');
        $obj->{IfHistoryBack} = 1;
        return $obj;
    }
=cut

   #****************************
   # 複数処理開始
   #****************************
=pod
   my $contents_id      = $q->param('contents_id');
   my $status_flag      = $q->param('status_flag');
   my $latest_flag      = $q->param('latest_flag');
   my $recommend_flag   = $q->param('recommend_flag');
   my $name             = $q->escapeHTML($q->param('name'));
   my $name_kana        = $q->escapeHTML($q->param('name_kana'));
   my $personality      = $q->escapeHTML($q->param('personality'));
   my $appearance       = $q->escapeHTML($q->param('appearance'));
   my $grade            = $q->escapeHTML($q->param('grade'));
   my $bloodtype        = $q->param('bloodtype') || 0;
   my $year_of_birth    = $q->escapeHTML($q->param('year_of_birth'));
   my $month_of_birth   = $q->escapeHTML($q->param('month_of_birth'));
   my $date_of_birth    = $q->escapeHTML($q->param('date_of_birth'));
   my $constellation    = $q->escapeHTML($q->param('constellation'));
   my $hobby            = $q->escapeHTML($q->param('hobby'));
   my $message          = $q->escapeHTML($q->param('message'));
   my $contentsimage_id = $q->param('contentsimage_id');
   my $painter          = $q->escapeHTML($q->param('painter'));
=cut

#********************************
# ここで入力エラーチェック
#********************************
   my @error;
    push @error, ' name data needed' if 5 > length($q->param('name'));
    push @error, ' name kana data needed' if 5 > length($q->param('name_kana'));
    push @error, ' personality data needed' if 5 > length($q->param('personality'));
    push @error, ' appearance data needed' if 5 > length($q->param('appearance'));
    push @error, ' hobby data needed' if 5 > length($q->param('hobby'));
    push @error, ' message data needed' if 5 > length($q->param('message'));
    push @error, ' painter data needed' if 5 > length($q->param('painter'));

    if (@error) {
        $obj->{IfError}       = 1;
        map { $obj->{ERROR_MSG} .= $_ } @error;
        $obj->{IfHistoryBack} = 1;
        return $obj;
    }

    my @images        = $q->upload('image');

    unless ($#images == 5) {
        $obj->{IfError}       = 1;
        $obj->{ERROR_MSG}     = MyClass::WebUtil::convertByNKF('-s', 'キャラクタ画像がありません');
        $obj->{IfHistoryBack} = 1;
        return $obj;
    }

   #my $contents_id      = $q->param('contents_id');
    my $status_flag      = $q->param('status_flag');
    my $latest_flag      = $q->param('latest_flag');
    my $recommend_flag   = $q->param('recommend_flag');
    my $name             = $q->param('name');
    my $name_kana        = $q->param('name_kana');
    my $personality      = $q->param('personality');
    my $appearance       = $q->param('appearance');
    my $grade            = $q->param('grade');
    my $bloodtype        = $q->param('bloodtype') || 0;
    my $year_of_birth    = $q->param('year_of_birth');
    my $month_of_birth   = $q->param('month_of_birth');
    my $date_of_birth    = $q->param('date_of_birth');
    my $constellation    = $q->param('constellation');
    my $hobby            = $q->param('hobby');
    my $message          = $q->param('message');
    my $contentsimage_id = $q->param('contentsimage_id');
    my $painter          = $q->param('painter');

    my ( $category_id, $subcategory_id, $EncodedCategoryName, $EncodedSubCategoryName ) = split(/;/, $q->param('allcategory_id'));
    #my ( $tmplt_id, $EncodedSummary ) = split(/;/, $q->param('tmplt_id'));

    ## コンテンツデータ.このデータは複数であっても全部同じ
    my $updateData = {
        contents_id      => -1,
        status_flag      => $status_flag,
        latest_flag      => $latest_flag,
        recommend_flag   => $recommend_flag,
        name             => $name,
        name_kana        => $name_kana,
        personality      => $personality,
        appearance       => $appearance,
        grade            => $grade,
        bloodtype        => $bloodtype,
        year_of_birth    => $year_of_birth,
        month_of_birth   => $month_of_birth,
        date_of_birth     => $date_of_birth,
        constellation    => $constellation,
        hobby            => $hobby,
        message          => $message,
        contentsimage_id => $contentsimage_id,
        painter          => $painter,
    };

    my $dbh         = $self->getDBConnection();
    my $cmsContents = MyClass::JKZDB::Contents->new($dbh);
    my $attr_ref    = MyClass::UsrWebDB::TransactInit($dbh);

    eval {
        $dbh->do('set names sjis');
        $cmsContents->executeUpdate($updateData);
        ## 新規の場合にcontents_idが何かをわかるように mysqlInsertIDSQLはcommitの前で取得
        my $contentsm_id = $cmsContents->mysqlInsertIDSQL();

        $obj->{contents_id}        = $contentsm_id;
        $dbh->commit();

    };
    if ($@) {
        $dbh->rollback();
        $obj->{IfError}        = 1;
        $obj->{ERROR_MSG}      = MyClass::WebUtil::convertByNKF('-s', $self->ERROR_MSG("ERR_MSG20"));
    }

    # カテゴリのデータ
    my $categorylist = $self->getCategoryFromObjectFile();
    my $idx;
    #foreach my $swf_fh (@swfs) {}
    foreach my $img_fh (@images) {

      #***************************
      # 画像 サンプル画像のデータセット
      # contentsm_idはコンテンツデータ格納後にmysqlinsertidから取得
      #***************************
        my ( $image, $resized_image, $sample_image, $resized_sample_image ) = &_convertImageFor($img_fh);

       # 画像のmime_type
        my $mime_type = $q->uploadInfo($img_fh)->{'Content-Type'};
        $mime_type    =~ s!(^image/)x-(png)$!$1$2!;
        $mime_type    =~ s!(^image/).+?(jpeg)$!$1$2!;

        my $name_utf8          = MyClass::WebUtil::convertByNKF('-w', $name);
        my $category_name_utf8 = MyClass::WebUtil::convertByNKF('-w', $categorylist->[$idx+1]->{'category_name'});

        my $InsertImage = {
            contentsm_id         => $obj->{contents_id},
            categorym_id         => $categorylist->[$idx+1]->{'category_id'},
            contentsm_name       => $name_utf8,
            categorym_name       => $category_name_utf8,
            image                => $image,
            resized_image        => $resized_image,
            sampel_image         => $sample_image,
            resized_sample_image => $resized_sample_image,
            mime_type            => $mime_type,
        };

        if (!$self->_storeImageData($InsertImage)) {
            ## 失敗したらループ脱出
            last;
        }

        $idx++;

    }

    $obj->{IfInsertDBSuccess} = 1 unless $obj->{IfError};
    $obj->{LoopContentsList} = $idx - 1;

    ## autocommit設定を元に戻す
    MyClass::UsrWebDB::TransactFin($dbh, $attr_ref, $@);
    undef($cmsContents);

    $self->flushAllFromCache();

    return $obj;
}

#******************************************************
# @access    public
# @desc        パラメータimageもしくはsampleimageで画像かｻﾝﾌﾟﾙ画像かを判定
# @desc        画像更新はひとつづつ
#******************************************************
sub uploadContentsImage {
    my $self = shift;
    my $q    = $self->query();
    my $obj  = {};

    if (!$q->param('contents_id')) {
        $obj->{ERROR_MSG}      = MyClass::WebUtil::convertByNKF('-s', '対象データがありません。');
        $obj->{IfHistoryBack} = 1;

        return $obj;
    }
    if (!$q->param('category_id')) {
        $obj->{ERROR_MSG}      = MyClass::WebUtil::convertByNKF('-s', '対象カテゴリデータがありません。');
        $obj->{IfHistoryBack} = 1;

        return $obj;
    }

    my $fh           = $q->upload('image');

    warn Dumper($fh);
    my $contentsm_id = $q->param('contents_id');
    my $categorym_id = $q->param('category_id');

#   foreach my $fh (@imagef) {
    my ( $image, $resized_image, $sample_image, $resized_sample_image ) = &_convertImageFor($fh);
    my $mime_type = $q->uploadInfo($fh)->{'Content-Type'};

    ## image/x-png や image/pjpeg だとSBとAUで表示できないので修正
    $mime_type =~ s!(^image/)x-(png)$!$1$2!;
    $mime_type =~ s!(^image/).+?(jpeg)$!$1$2!;

    my $InsertImage = {
        contentsm_id         => $contentsm_id,
        categorym_id         => $categorym_id,
        image                => $image,
        resized_image        => $resized_image,
        sampel_image         => $sample_image,
        resized_sample_image => $resized_sample_image,
        mime_type            => $mime_type,
    };

    my $rv = $self->_storeImageData($InsertImage);

    if (!$rv) {
        $obj->{ERROR_MSG}      = "Image Data Insert Failed Operation is aborted";
        ## DBインサート失敗
        $obj->{IfInsertDBFail} = 1;
    }
    else {
        $obj->{contents_id}       = $contentsm_id;
        $obj->{IfInsertDBSuccess} = 1;
    }
#    }

    ## キャッシュから古いデータをなくすため全て削除 2009/07/21
    $self->flushAllFromCache();

    return $obj;
}



sub uploadImageData {
    my $self = shift;

    my $image     = $self->query->upload('image');
    my $mime_type = $self->query->uploadInfo($image)->{'Content-Type'};
    $mime_type    =~ s!(^image/)x-(png)$!$1$2!;
    $mime_type    =~ s!(^image/).+?(jpeg)$!$1$2!;

    return ({ image => $image, mime_type => $mime_type } );

}


#******************************************************
# @access    private
# @desc      アイテム画像を格納
# @param
# @return    boolean
#******************************************************
sub storeItemImageData {
    my ($self, $data) = @_;

    my $dbh = $self->getDBConnection();
    $dbh->do("set names utf8");
    my $Image = MyClass::JKZDB::ItemImage->new($dbh);
    if (!$Image->executeUpdate($data)) {
        return -1;
    }

    return 1;
}


#******************************************************
# @access    private
# @desc        フラッシュファイルを格納
# @param
# @return    boolean
#******************************************************
sub _storeSwfData {
    my ($self, $data) = @_;

    my $dbh = $self->getDBConnection();
    $dbh->do('set names utf8');
    my $SwfData = MyClass::JKZDB::ContentsSwf->new($dbh);
    if (!$SwfData->executeUpdate($data)) {
        return -1;
    }

    return 1;
}


#******************************************************
# @access    private
# @desc      画像を格納
# @param
# @return    boolean
#******************************************************
sub _storeImageData {
    my ($self, $data) = @_;

    my $dbh = $self->getDBConnection();
    $dbh->do('set names utf8');
    my $Image = MyClass::JKZDB::ContentsImage->new($dbh);
    if (!$Image->executeUpdate($data, -1)) {
        return -1;
    }

    return 1;
}


#******************************************************
# @access    private
# @desc      サンプル画像を格納
# @param
# @return    boolean
#******************************************************
sub _storeSampleImageData {
    my ($self, $data) = @_;
    my $dbh = $self->getDBConnection();
    $dbh->do('set names utf8');
    my $Image = MyClass::JKZDB::ContentsSampleImage->new($dbh);
    if (!$Image->executeUpdate($data)) {
        return -1;
    }

    return 1;
}


#******************************************************
# @access   クラスメソッドではない
# @desc      ローカルディレクトリにある画像ファイルから
# @param     blobにする
# @return    
#******************************************************
sub image2Blob {
	my $fh = shift;
	my $img = Image::Magick->new();
	my $err = $img->Read ($fh);
	die "Can't read image file: $err\n" if $err;
	my $image_data = $img->ImageToBlob();

	return $image_data;
}


#******************************************************
# @access   クラスメソッドではない
# @desc     画像を変換
# @param
# @param    filehandle $fh(画像のファイルハンドル)
# @param    もう一つ引数がある場合はsample.gif画像と合成する
# @return    $image_data, $resized_image_data,  $sample_image_data, $resized_sample_image_data,
#******************************************************
sub _convertImageFor {
    my $fh  = shift;
    #my $opt = shift || undef;

    #my ($err, $image_data, $resized_60_75_image_data, $resized_30_38_image_data);
    #$my ($err, $image_data, $resized_60_75_image_data, $resized_30_38_image_data, $sample_image_data, $resized_60_75_sample_image_data, $resized_30_38_sample_image_data);
    my ($err, $image_data, $resized_image_data, $sample_image_data, $resized_sample_image_data);
    #**********************************
    # 画像の読みこみとデータ化
    #**********************************
    use Image::Magick;
    my $img = Image::Magick->new();

    (read($fh, $image_data, -s $fh) == -s $fh)
        or die ("Can't read image file: $!");
    $err = $img->BlobToImage($image_data);
    die "Can't read image file: $err\n" if $err;

    my ($width, $height) = $img->Get('width','height');

    my $clone = $img->Clone();

    my $READFILE    = '/home/vhosts/MOEPETIT/JKZ/MyClass/JKZApp/SAMPLE.gif';
    my $sampletmplt = Image::Magick->new();
    $sampletmplt->Read($READFILE);

    #$img->Composite(image=>$sampletmplt, gravity=>"south", -geometry=>'+0+10');
    $clone->Composite( image => $sampletmplt, gravity=>"south" ); ## 合成画像をセンターで合体
    $clone->Scale( geometry=>"$width x $height" );
    $sample_image_data = $clone->ImageToBlob();
    $clone->Scale( geometry => '60x75' );
    $resized_sample_image_data = $clone->ImageToBlob();

    $img->Scale( geometry => "$width x $height" );
    $image_data = $img->ImageToBlob();
    $img->Scale( geometry => '60x75' );
    $resized_image_data = $img->ImageToBlob();

    undef $sampletmplt;
    undef $clone;
    undef $img;

    return ($image_data, $resized_image_data, $sample_image_data, $resized_sample_image_data);

    ## ここでsample.gifとの合成をする
=pod
    if ($opt) {
        my $READFILE    = '/home/vhosts/DENISMCD/JKZ/MyClass/JKZApp/SAMPLE.gif';
        my $sampletmplt = Image::Magick->new();
        $sampletmplt->Read($READFILE);

        #$img->Composite(image=>$sampletmplt, gravity=>"south", -geometry=>'+0+10');
        $img->Composite(image=>$sampletmplt, gravity=>"center"); ## 合成画像をセンターで合体
        $img->Scale(geometry=>"$width x $height");
        $image_data = $img->ImageToBlob();
        $img->Scale(geometry=>'60x75');
        $resized_60_75_image_data = $img->ImageToBlob();
        $img->Scale(geometry=>'30x38');
        $resized_30_38_image_data = $img->ImageToBlob();
    }
    else {
        $img->Scale(geometry=>"$width x $height");
        $image_data = $img->ImageToBlob();
        $img->Scale(geometry=>'60x75');
        $resized_60_75_image_data = $img->ImageToBlob();
        $img->Scale(geometry=>'30x38');
        $resized_30_38_image_data = $img->ImageToBlob();
    }
=cut
    #return ($image_data, $resized_60_75_image_data, $resized_30_38_image_data);
}


1;
__END__


#******************************************************
# @access    public
# @desc        フラッシュファイルを格納
# @desc        画像更新はひとつづつ
#******************************************************
=pod
sub uploadSwfData_with_ImageData {
    my $self = shift;
    my $q    = $self->query();
    my $obj  = {};

    #********************************
    # 一連のエラー処理
    #********************************
    if (!$q->param('swffile')) {
        $obj->{IfError}       = 1;
        $obj->{ERROR_MSG}      = MyClass::WebUtil::convertByNKF('-s', 'フラッシュファイルがありません。選択してください。');
        $obj->{IfHistoryBack} = 1;
        return $obj;
    }

    my $contentsm_id = $q->param('contents_id');

   #****************************
   # 複数処理開始
   #****************************
    my $status_flag    = $q->param('status_flag');
    my $latest_flag    = $q->param('latest_flag');
    my $recommend_flag = $q->param('recommend_flag');
    my $charge_flag    = $q->param('charge_flag') || 0;
    my $point_flag     = $q->param('point_flag') || 0;
    my $point          = $q->param('point') || 0;
    my ( $category_id, $subcategory_id, $EncodedCategoryName, $EncodedSubCategoryName ) = split(/;/, $q->param('allcategory_id'));
    #my ( $tmplt_id, $EncodedSummary ) = split(/;/, $q->param('tmplt_id'));

    my @swfs          = $q->upload('swffile');
    my @images        = $q->upload('image');
#    my @sample_images = $q->upload('sample_image');
    my $names         = $q->param('contents_name');
    $names            =~ s/^[\s|,]+//g;
    $names            =~ s/[\s|,]+$//g;
    $names            =~ s/[\s|,]+/,/g;
    my @contentsnames = split(/,/, $names);

    ## コンテンツデータ.このデータは複数であっても全部同じ
    my $updateData = {
        contents_id     => -1,
        status_flag     => $status_flag,
        charge_flag     => $charge_flag,
        point_flag      => $point_flag,
        latest_flag     => $latest_flag,
        recommend_flag  => $recommend_flag,
        contents_name   => undef,
        categorym_id    => $category_id,
        subcategorym_id => $subcategory_id,
        tmplt_id        => 0,
        point           => $point,
    };

    my $dbh         = $self->getDBConnection();
    my $cmsContents = MyClass::JKZDB::Contents->new($dbh);
    my $attr_ref    = MyClass::UsrWebDB::TransactInit($dbh);

    my $idx;

    foreach my $swf_fh (@swfs) {
        if ( "" eq $contentsnames[$idx] ) {
            $obj->{IfError}       = 1;
            $obj->{ERROR_MSG}     = 'コンテンツ名がありません';
            $obj->{IfHistoryBack} = 1;
            return $obj;
        }

       # flashのmime_type
        my $swf_mime_type = $q->uploadInfo($swf_fh)->{'Content-Type'};
       # 画像のmime_type
        my $image_mime_type = $q->uploadInfo($images[$idx])->{'Content-Type'};
       # サンプル画像のmime_type
       # my $sample_image_mime_type = $q->uploadInfo($sample_images[$idx])->{'Content-Type'};

        $image_mime_type        =~ s!(^image/)x-(png)$!$1$2!;
        $image_mime_type        =~ s!(^image/).+?(jpeg)$!$1$2!;
        #$sample_image_mime_type =~ s!(^image/)x-(png)$!$1$2!;
        #$sample_image_mime_type =~ s!(^image/).+?(jpeg)$!$1$2!;

        ## Flashの処理 ファイルサイズ取得
        my $swf_file_size = (stat($swf_fh))[7];
        my ($swfdata, $swf_height, $swf_width);
        (read($swf_fh, $swfdata, -s $swf_fh) == -s $swf_fh)
            or confess ("Can't read data file: $!");

        my $header_data = SWF::Header->read_data($swfdata);
        $swf_height = $header_data->{height};
        $swf_width  = $header_data->{width};

       ## 画像とサンプル画像の処理
        #my ( $image, $resized_60_75_image, $resized_30_38_image )                      = MyClass::JKZApp::AppImage::_convertImageFor($images[$idx]);
        #my ( $sample_image, $resized_60_75_sample_image, $resized_30_38_sample_image ) = MyClass::JKZApp::AppImage::_convertImageFor($sample_images[$idx]);
        #my ( $image, $resized_60_75_image, $resized_30_38_image )                      = &_convertImageFor($images[$idx]);
        #my ( $sample_image, $resized_60_75_sample_image, $resized_30_38_sample_image ) = &_convertImageFor($images[$idx], 1);
        my ( $image, $resized_60_75_image, $resized_30_38_image, $sample_image, $resized_60_75_sample_image, $resized_30_38_sample_image ) = &_convertImageFor($images[$idx]);
      #***************************
      # Flash 画像 サンプル画像のデータセット
      # contentsm_idはコンテンツデータ格納後にmysqlinsertidから取得
      #***************************
        # Flash
        my $InsertSwf = {
            swf         => $swfdata,
            mime_type   => $swf_mime_type,
            file_size   => $swf_file_size,
            height      => $swf_height,
            width       => $swf_width,
        };
        # ImageM
        my $InsertImage = {
            image               => $image,
            resized_image       => $resized_60_75_image,
            resized_30_38_image => $resized_30_38_image,
            mime_type           => $image_mime_type,
        };
        # SampleImageM

        my $InsertSampleImage = {
            image               => $sample_image,
            resized_image       => $resized_60_75_sample_image,
            resized_30_38_image => $resized_30_38_sample_image,
            mime_type           => $image_mime_type,
        };

        eval {
            $updateData->{contents_name} = $contentsnames[$idx];
            $dbh->do('set names sjis');
            $cmsContents->executeUpdate($updateData);

            ## 新規の場合にcontents_idが何かをわかるように mysqlInsertIDSQLはcommitの前で取得
            my $contentsm_id = $cmsContents->mysqlInsertIDSQL();

            $obj->{contents_id}->[$idx]        = $contentsm_id;

            $InsertSwf->{contentsm_id}         = $contentsm_id;
            $InsertImage->{contentsm_id}       = $contentsm_id;
            $InsertSampleImage->{contentsm_id} = $contentsm_id;

            $self->_storeSwfData($InsertSwf);
            $self->_storeImageData($InsertImage);
            $self->_storeSampleImageData($InsertSampleImage);

            $dbh->commit();

            ## flashのオブジェクトファイル生成
            my $published      = sprintf("%s/contents/swf/%s", $self->cfg->param('SERIALIZEDOJB_DIR'), $contentsm_id);
            MyClass::WebUtil::publishObj({
                file => $published,
                obj  => {
                    swfdata   => $swfdata,
                    mime_type => $swf_mime_type
                }
            });

        };
        if ($@) {
            $dbh->rollback();
            $obj->{IfError}        = 1;
            $obj->{ERROR_MSG}      = MyClass::WebUitl::convertByNKF('-s', $self->ERROR_MSG("ERR_MSG20"));
            $obj->{IfInsertDBFail} = 1;

        ## ループを終了する
            last;
        }

        $obj->{contents_name}->[$idx]    = $contentsnames[$idx];
        $obj->{category_name}->[$idx]    = $q->unescape($EncodedCategoryName);
        $obj->{subcategory_name}->[$idx] = $q->unescape($EncodedSubCategoryName);

        $idx++;

    }

    $obj->{IfInsertDBSuccess} = 1 unless $obj->{IfError};
    $obj->{LoopContentsList} = $idx - 1;

    ## autocommit設定を元に戻す
    MyClass::UsrWebDB::TransactFin($dbh, $attr_ref, $@);
    undef($cmsContents);

    $self->flushAllFromCache();

    return $obj;
}
=cut

#******************************************************
# @access    public
# @desc        フラッシュファイルを格納
# @desc        画像更新はひとつづつ
#******************************************************
=pod
sub uploadSwfFile {
    my $self = shift;
    my $q    = $self->query();
    my $obj  = {};

    #********************************
    # 一連のエラー処理
    #********************************
    if (!$q->param('contents_id')) {
        $obj->{ERRORMSG}      = '対象データがありません。';
        $obj->{IfHistoryBack} = 1;
        return $obj;
    }
    if (!$q->param('swffile')) {
        $obj->{ERRORMSG}      = 'フラッシュファイルがありません。選択してください。';
        $obj->{IfHistoryBack} = 1;
        return $obj;
    }

    my $contentsm_id = $q->param('contents_id');
    my $fh           = $q->upload('swffile');

    ## Mime-type取得
    my $mime_type = $q->uploadInfo($fh)->{'Content-Type'};

    ## ファイルサイズ取得
    my $file_size = (stat($fh))[7];

    my ($swfdata, $height, $width);

    (read($fh, $swfdata, -s $fh) == -s $fh)
        or confess ("Can't read data file: $!");

    #********************************
    # flashファイルから縦・横幅を取得
    #********************************
    my $header_data = SWF::Header->read_data($swfdata);
    $height = $header_data->{height};
    $width  = $header_data->{width};

    my $InsertData = {
        contentsm_id => $contentsm_id,
        swf          => $swfdata,
        mime_type    => $mime_type,
        file_size    => $file_size,
        height       => $height,
        width        => $width,
    };

    if (!$self->_storeSwfData($InsertData)) {
        $obj->{ERROR_MSG} = "FlashFile Data Insert Failed Operation is aborted";
        ## DBインサート失敗
        $obj->{IfFailUploadSwf} = 1;
            return $obj;
    } else {
          $obj->{IfSuccessUploadSwf} = 1;
          $obj->{filename}   = $fh;
          $obj->{contents_id} = $contentsm_id;
          $obj->{mime_type}  = $mime_type;
          $obj->{file_size}  = $file_size;
          $obj->{height}     = $height;
          $obj->{width}      = $width;

        ## Modified flashのオブジェクトファイル生成 -- 2010/08/10 --
          my $published      = sprintf("%s/contents/swf/%s", $self->cfg->param('SERIALIZEDOJB_DIR'), $contentsm_id);
          MyClass::WebUtil::publishObj({
              file => $published,
              obj  => {
                  swfdata   => $swfdata,
                  mime_type => $mime_type
              }
          });
$self->action('uploadContentsImage');

          return $obj;
    }
}
=cut


=pod
sub uploadContentsImage {
    my $self = shift;
    my $q    = $self->query();
    my $obj  = {};

    if (!$q->param('contents_id')) {
        $obj->{ERROR_MSG}      = MyClass::WebUtil::convertByNKF('-s', '対象データがありません。');
        $obj->{IfHistoryBack} = 1;

        return $obj;
    }

   ## サンプル画像か本番画像かの判定フラグ
    #my $SAMPLE_IMAGE_FLAG = defined($q->param('sampleimage')) ? 1 : 0;
    my $SAMPLE_IMAGE_FLAG = defined($q->upload('sampleimage')) ? 1 : 0;

    ## 複数アップ処理対応
    #my @imagef       = $q->upload('image') || $q->upload('sampleimage');
    my $fh   = $q->upload('image') || $q->upload('sampleimage');

    my $contentsm_id = $q->param('contents_id');

#    foreach my $fh (@imagef) {

        #my ($image, $resized_60_75_image, $resized_30_38_image) = MyClass::JKZApp::AppImage::_convertImageFor($fh);
        my ($image, $resized_60_75_image, $resized_30_38_image) = &_convertImageFor($fh);
        my $mime_type = $q->uploadInfo($fh)->{'Content-Type'};

        ## image/x-png や image/pjpeg だとSBとAUで表示できないので修正
        $mime_type =~ s!(^image/)x-(png)$!$1$2!;
        $mime_type =~ s!(^image/).+?(jpeg)$!$1$2!;

        my $InsertImage = {
            contentsm_id        => $contentsm_id,
            image               => $image,
            resized_image       => $resized_60_75_image,
            resized_30_38_image => $resized_30_38_image,
            mime_type           => $mime_type,
        };

        my $rv = ( 1 == $SAMPLE_IMAGE_FLAG ) ? $self->_storeSampleImageData($InsertImage) : $self->_storeImageData($InsertImage);

        if (!$rv) {
            $obj->{ERROR_MSG}      = "Image Data Insert Failed Operation is aborted";
            ## DBインサート失敗
            $obj->{IfInsertDBFail} = 1;
        }
        else {
            $obj->{contents_id}       = $contentsm_id;
            $obj->{IfInsertDBSuccess} = 1;
        }
#    }

    ## キャッシュから古いデータをなくすため全て削除 2009/07/21
    $self->flushAllFromCache();

    return $obj;
}
=cut