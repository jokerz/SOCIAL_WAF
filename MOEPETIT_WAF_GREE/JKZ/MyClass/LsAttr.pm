#******************************************************
# @desc		指定ディレクトリ配下のファイル名を全て得る
# @package	JKZ::LsAttr
# @access	public
# @author	Iwahase Ryo
# @create	2007/01/10
# @version	1.00
#******************************************************
package MyClass::LsAttr;

use 5.008000;
our $VERSION = 'JOKERZ1.00';

use strict ;

#******************************************************
# @access	public
#			my $lsattr = JKZ::LsAttr->new ();
# @desc		コンストラクタ
# @param		
# @return		
# @author		
#******************************************************
	sub new {
		my ($class, $initializer) = @_;
		my $self = {};
		# SEPARATOR変数を定義。デフォルトはUNIX,LINUX用
		$self->{SEPARATOR} = "/";
		# ファイルリスト一覧変数
		$self->{ALLFNAMES} = [
			{
				fleaf	=> undef,
				fname	=> undef,#0
				fmode	=> undef,#2
				fuid	=> undef,#4
				fgid	=> undef,#5
				fsize	=> undef,#7
				fmtime	=> undef,#9
			}
		];

		bless ($self);
		# 初期化処理を行う
		$self->_initialize ($initializer);
		return $self;
	}


#******************************************************
# @access	private
# @desc		セパレータ文字列初期化
#			$self->_initialize ($initializer);
# @param		
# @return		
# @author		
#******************************************************
	sub _initialize {
		my ($self, $initializer) = @_;

		# 引数の値が'\'であれば
		if( defined ($initializer) && $initializer eq "\\" ) {
			# '\'をSEPARATOR変数へ格納
			$self->{SEPARATOR} = "\\";
		}
	}

#******************************************************
# @access	public
# @desc		セパレータ文字列初期化
#			@files = $lsattr->getFileList ("/usr/local", 0);
#
# @param	$parent_dir    = 親ディレクトリ名
#			$sub_searchflg = 検索MODE
#				 0:サブディレクトリを検索しない
#				 1:サブディレクトリを検索する
# @return	ARRAY ファイル一覧
# @author		
#******************************************************
	sub getFileList () {
		my $self          = shift;
		my $parent_dir    = shift;
		my $sub_searchflg = shift;

		# separator文字が'\'であれば
		if( $self->{SEPARATOR} eq "\\" ) {
			# ケツにseparator文字が存在すれば
			if( $parent_dir=~/(.*?)(\\)+$/ ) {
				# それを削除
				$parent_dir=$1;
			}
		}
		# separator文字が'/'であれば {
		else {
			if( $parent_dir=~/(.*?)(\/)+$/ ) {
				$parent_dir=$1;
			}
		}

		# カレントディレクトリーを開く
		opendir (DOCS, $parent_dir);
		# ファイル名を配列に取り込む
		my @fnames = readdir (DOCS);

		# サブディレクトリを検索する場合は
		if( $sub_searchflg==1 ) {
			# getSubFileListをCallしてファイル名を順に取得する
			$self->getSubFileList ($parent_dir, @fnames);
		}
		else {
			$self->FnameBufCat ($parent_dir, @fnames);
		}
		return @{$self->{ALLFNAMES}};
	}

#******************************************************
# @access	private
# @desc		カレントディレクトリのファイル名の一覧を取得する実行部。実行結果
#			はFnameBufCat関数をcallしてセットする。
#			$self->getSubFileList ($parent_dir, @fnames)
# @param	$work_dir      = 親ディレクトリ名
#			$sub_searchflg = 検索MODE
#				 0:サブディレクトリを検索しない
#				 1:サブディレクトリを検索する
#			@parent_fnames = 親ディレクトリのファイル一覧
# @return		
# @author		
#******************************************************
	sub getSubFileList() {
		my $self          = shift;
		my $work_dir      = shift;
		my (@parent_fnames) = @_;

		# @parent_fnamesの各要素へアクセスするカウンター変数
		my $loopcnt=0;

		# 全ファイルに対して再帰的にファイル取得処理をする
		foreach my $file (@parent_fnames){
			if( $file =~ /^\./ ) {
			}
			else {
				if ( opendir (DOCS2, join ( "", $work_dir, $self->{SEPARATOR}, $file )) ) {

					# サブディレクトリ内のファイル一覧を取得
					my @fnames = readdir(DOCS2);
					$self->getSubFileList ( $work_dir.$self->{SEPARATOR}.$file ,@fnames);

					# 解析済みのフォルダ名は補正処理する
					$parent_fnames[$loopcnt]="...";
				}
			}
			# カウンタを更新する
			$loopcnt++;
		}
		# FnameBufCatをCallしてファイルリスト一覧変数を更新する
		$self->FnameBufCat ( $work_dir,@parent_fnames );
	}


#******************************************************
# @access	private
# @desc		ファイル名の一覧を管理関数
#			$self->FnameBufCat ( $work_dir,@parent_fnames );
# @param	$work_dir      = 親ディレクトリ名
#			@parent_fnames = 親ディレクトリのファイル一覧
# @return		
# @author		
#******************************************************
	sub FnameBufCat () {
		my $self          = shift;
		my $work_dir      = shift;
		my (@parent_fnames) = @_;

		# @parent_fnamesの各要素に対して
		foreach my $file (@parent_fnames) {
			if( $file =~ /^\./ ) {
			} else {
				my $fullfile = $work_dir.$self->{SEPARATOR}.$file;
				my @filedata = stat ($fullfile);
				#push( @{$self->{ALLFNAMES}}, $file );
				push ( @{$self->{ALLFNAMES}}, {
						fleaf	=> $file,
						fname	=> $fullfile,
						fmode 	=> $filedata[2],
						fuid	=> $filedata[4],
						fgid	=> $filedata[5],
						fsize	=> $filedata[7],
						fmtime	=> $filedata[9],
					}
				);
			}
		}
	}

1;
__END__
