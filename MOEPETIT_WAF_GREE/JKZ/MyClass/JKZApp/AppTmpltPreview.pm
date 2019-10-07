#******************************************************
# @desc      �e���v���[�g�v���r���[�N���X
# @package   MyClass::JKZApp::AppTmpltPreview
# @access    public
# @author    Iwahase Ryo
# @create    2009/08/31
# @version   1.00
#******************************************************
package MyClass::JKZApp::AppTmpltPreview;

use 5.008005;
our $VERSION = '1.00';

use strict;
use base qw(MyClass::JKZApp);
use MyClass::WebUtil;
use MyClass::JKZHtml;

#******************************************************
# @access    public
# @desc        �R���X�g���N�^
# @param    
# @return    
#******************************************************
sub new {
    my ($class, $cfg) = @_;

    return $class->SUPER::new($cfg);
}


#******************************************************
# @access   public
# @desc     �����ł͂��̃N���X����уT�u�N���X�ł̕K�v�ȑO����
#           ���s��
# @param    
# @return   
#******************************************************
sub run {
    my $self = shift;

    $self->dispatch();
}


#******************************************************
# @access    public
# @desc        dispatch �p�����[�^�[�̒l�ɂ�菈��������
# @param    
# @return    
#******************************************************
sub dispatch {
    my $self  = shift;
    my $obj   = {};
    my $tmplt = $self->query->param('tmplt');

    $obj->{IMAGE_SCRIPTDATABASE_NAME}     = $self->CONFIGURATION_VALUE('IMAGE_SCRIPTDATABASE_NAME');
    $obj->{SITEIMAGE_SCRIPTDATABASE_URL} = $self->CONFIGURATION_VALUE('SITEIMAGE_SCRIPTDATABASE_NAME');

    #$obj->{SITEIMAGE_SCRIPTDATABASE_URL} = $self->SITEIMAGE_SCRIPTDATABASE_NAME();
    #$obj->{IMAGE_SCRIPTDATABASE_URL}     = $self->IMAGE_SCRIPTDATABASE_NAME();
    #$obj->{FLASH_SCRIPT_URL}             = $self->FLASH_SCRIPTFILE_NAME();
    #$obj->{DECOTMPLT_SCRIPT_URL}         = $self->DECOTMPLT_SCRIPTFILE_NAME();
    #$obj->{DECOICON_SCRIPT_URL}          = $self->DECOICON_SCRIPTFILE_NAME();

    my $myHtml = MyClass::JKZHtml->new($obj, $tmplt, 1, 0);
    my $page = $myHtml->convertHtmlTags($obj);

    print "Content-type: text/html", "\n\n";
    print $page;

}


1;

__END__