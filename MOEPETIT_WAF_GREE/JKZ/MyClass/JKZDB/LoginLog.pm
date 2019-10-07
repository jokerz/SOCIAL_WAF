#******************************************************
# @desc        
#            
# @package    MyClass::JKZDB::LoginLog
# @access    public
# @author    Iwahase Ryo AUTO CREATE BY ./createClassDB
# @create    Tue Jan 12 19:40:10 2010
# @version    1.30
# @update    2008/05/30 executeUpdate�����̖߂�l����
# @update    2008/03/31 JKZ::DB::JKZDB�̃T�u�N���X��
# @update    2009/02/02 �f�B���N�g���\����JKZ::JKZDB�ɕύX
# @update    2009/02/12 ���X�e�B���O������ǉ�
# @update    2009/09/28 executeUpdate���\�b�h�̏����ύX
# @version    1.10
# @version    1.20
# @version    1.30
#******************************************************
package MyClass::JKZDB::LoginLog;

use 5.008005;
use strict;
our $VERSION ='1.30';

use base qw(MyClass::JKZDB);


#******************************************************
# @access    public
# @desc        �R���X�g���N�^
# @param    
# @return    
# @author    
#******************************************************
sub new {
    my ($class, $dbh) = @_;
    my $table = 'dMOEPETIT_LOG.tLoginLogF';
    return $class->SUPER::new($dbh, $table);
}


#******************************************************
# @access    
# @desc        SQL�����s���܂��B
# @param    $sql
#            @placeholder
# @return    
#******************************************************
sub executeQuery {
    my ($self, $sqlMoji, $placeholder) = @_;

    my ($package, $filename, $line, $subroutine) = caller(1);

    if ($subroutine =~ /executeSelectList/) {
        my $aryref = $self->{this_dbh}->selectall_arrayref($sqlMoji, undef, @$placeholder);

        $self->{reccnt} = $#{$aryref};
        for (my $i = 0; $i <= $self->{reccnt}; $i++) {
#************************ AUTO GENERATED BEGIN ************************
$self->{columnslist}->{gree_user_id}->[$i] = $aryref->[$i]->[0];
$self->{columnslist}->{in_date}->[$i] = $aryref->[$i]->[1];
$self->{columnslist}->{last_login_datetime}->[$i] = $aryref->[$i]->[4];
#************************ AUTO  GENERATED  END ************************
        }
    }
    elsif ($subroutine =~ /executeSelect$/) {
        my $sth = $self->{this_dbh}->prepare($sqlMoji);
        my $row = $sth->execute(@$placeholder);
        if (0==$row || !defined($row)) {
            return 0;
        } else {
#************************ AUTO GENERATED BEGIN ************************
            (
$self->{columns}->{gree_user_id},
$self->{columns}->{in_date},
$self->{columns}->{last_login_datetime}
            ) = $sth->fetchrow_array();
#************************ AUTO  GENERATED  END ************************
        }
        $sth->finish();
    } else {
        my $rc = $self->{this_dbh}->do($sqlMoji, undef, @$placeholder);
        return $rc;
    }
}


#******************************************************
# @access    public
# @desc        ���R�[�h�X�V����
#            �v���C�}���L�[�����ɂ����INSERT�Ȃ�����UPDATE�̏������s�Ȃ��܂��B
# @param    
# @return    
#******************************************************
sub executeUpdate {
    my ($self, $param) = @_;

    my $sqlMoji;
    #******************************************************
    # TYPE    : arrayreference
    #            [
    #             [ columns name array],        0
    #             [ placeholder array ],        1
    #             [ values array        ],        2
    #            ]
    #******************************************************
    my $sqlref;
    my $rv;

    if ($self->{this_dbh} == "") {
        #�G���[����
    }


#    $self->{columns}->{in_datehour} = $param->{in_datehour};

    ## ������PrimaryKey���ݒ肳��Ă���ꍇ��Update
    ## �ݒ肪�Ȃ��ꍇ��Insert
#    if ($self->{columns}->{in_datehour} < 0) {
        ##1. AutoIncrement�łȂ��ꍇ�͂����ōő�l���擾
        ##2. �}�� 

        #************************ AUTO GENERATED COLUMNS AND PLACEHOLDERS HAS BENN COMBINED BEGIN ************************
        push( @{ $sqlref->[0] }, "gree_user_id" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{gree_user_id} ) if $param->{gree_user_id} != "";
        push( @{ $sqlref->[0] }, "in_date" ), push( @{ $sqlref->[1] }, "DATE_FORMAT(NOW(), '%Y%m%d')" );#, push( @{ $sqlref->[2] }, $param->{in_datehour} ) if $param->{in_datehour} ne "";
        #push( @{ $sqlref->[0] }, "last_login_datetime" ), push( @{ $sqlref->[1] }, "?" ), push( @{ $sqlref->[2] }, $param->{last_login_datetime} ) if $param->{last_login_datetime} ne "";

        #************************ AUTO GENERATED COLUMNS AND PLACEHOLDERS HAS BENN COMBINED   END ************************


    #******************************************************************************************
    # ���ʏ����ǉ� primarykey(gree_user_id+in_datehour)�����݂���Ƃ��́Ain_datehour���X�V���������s
    #******************************************************************************************
        #$sqlMoji = sprintf("INSERT INTO %s (%s) VALUES (%s);", $self->{table}, join(',', @{ $sqlref->[0] }), join(',', @{ $sqlref->[1] }));
        $sqlMoji = sprintf("INSERT INTO %s (%s) VALUES (%s) ON DUPLICATE KEY UPDATE last_login_datetime=NOW();", $self->{table}, join(',', @{ $sqlref->[0] }), join(',', @{ $sqlref->[1] }));
        $rv = $self->executeQuery($sqlMoji, $sqlref->[2]);

        return $rv; # return value
}


1;
__END__
