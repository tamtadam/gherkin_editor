use strict;
use warnings;
use Data::Dumper;

use FindBin ;
use lib $FindBin::RealBin;
use lib $FindBin::RealBin . "../../../common/cgi-bin/" ;
use lib $FindBin::RealBin . "../../cgi-bin/" ;

use Test::More tests => 3;

use TestMock;
use DBConnHandler;
use Modell_ajax;
use Errormsg;

my $db;
my $ma;
my $DBH;


my $err_handler_mock = TestMock->new( 'Errormsg' );
   $err_handler_mock->mock( 'new' );
   $err_handler_mock->mock( 'add_error' );

my $email_mock = TestMock->new( 'Email' );
   $email_mock->mock( 'send_mail' );

my $cfg_mock = TestMock->new( 'Cfg' );
   $cfg_mock->mock( 'get_data' );

my $template_mock = TestMock->new( 'Template' );
   $template_mock->mock( 'new' );
   $template_mock->mock( 'fill_in' );
   $template_mock->mock( 'return_string' );  

$ma = Modell_ajax->new( { DB_HANDLE => $db } );

sub BEGIN {
    $ENV{ TEST_SQLITE } = q~../sql/gherkin_editor.sqlite~;
    TestMock::set_test_dependent_db();
    $db = DBConnHandler::init();
    $DBH = new DBH( { DB_HANDLE => $db } ) ;
}

sub END {
    DBConnHandler::disconnect();
    TestMock::remove_test_db();
}

sub INIT {

}


subtest "check_input_data_for_save_new_user" => sub {
    my $res = $ma->check_input_data_for_save_new_user();
    ok(!$res, 'no param');
    
    $res = $ma->check_input_data_for_save_new_user({ email => 'email'});
    ok(!$res, 'no param');
    
    $res = $ma->check_input_data_for_save_new_user({ 
        email => 'email',
        password => 'password'
    });
    ok(!$res, 'no param');
    
    $res = $ma->check_input_data_for_save_new_user({ 
        email => 'email',
        password => 'password',
        username => 'username'
    });
    ok(!$res, 'no param');
    
    $res = $ma->check_input_data_for_save_new_user({ 
        email => 'email',
        password => 'password',
        username => 'username',
        name => 'name'
    });
    ok($res, 'all params defined');
};

subtest 'saveNewUser' => sub {
    my $res = $ma->saveNewUser({});
    
    my @error = $err_handler_mock->add_error();
    is( ref $error[ 0 ], 'Modell_ajax', 'correct package' );
    is( $error[ 1 ], 'PARAM_ERROR', 'Error: PARAM_ERROR' );
    $err_handler_mock->empty_buffers( 'add_error' );
    
    $res = $ma->saveNewUser({
        map { $_ => $_ } qw(email password username name)
    });

    $res = $DBH->my_select({
        from => 'partner',
        where => {
            email => 'email'
        }
    });
    ok( $res->[0]->{ partner_id }, 'new user added' );
    
    $res = $ma->saveNewUser({
        map { $_ => $_ } qw(email password username name)
    });

    @error = $err_handler_mock->add_error();
    is( ref $error[ 0 ], 'Modell_ajax', 'correct package' );
    is( $error[ 1 ], 'USER_EXISTS', 'Error: USER_EXISTS' );
    $err_handler_mock->empty_buffers( 'add_error' );
    
};

subtest 'send_activation_request' => sub {
    $email_mock->empty_buffers( 'send_mail' );
    $template_mock->empty_buffers( 'fill_in' );
    $template_mock->return_string( 'return_string' );

    $cfg_mock->get_data('url');
    $ma->send_activation_request({
        email      => 'email',
        name       => 'name',
        partner_id => 12
    });

    is_deeply($email_mock->send_mail(), {
        subject => 'Activation link',
        body    => 'return_string',
        to      => 'email',
        contenttype => 'text/html'
    }, 'send_mail' );
    is_deeply([$template_mock->fill_in()]->[1], {
        URL      => 'url?ValidateUser="12"',
        USERNAME => 'name'
    }, 'fill_in' );
};

