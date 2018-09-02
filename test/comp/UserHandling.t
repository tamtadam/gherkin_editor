use strict;
use warnings;
use Data::Dumper;

use FindBin ;
use lib $FindBin::RealBin;
use lib $FindBin::RealBin . "../../../../common/cgi-bin/" ;
use lib $FindBin::RealBin . "../../../../gherkin_editor/cgi-bin/" ;


use DBConnHandler;
use DBH;

use Test::More tests => 3;

use TestMock;

$|=1;

sub BEGIN {
    $ENV{ TEST_SQLITE } = $FindBin::RealBin . '/../../sql/gherkin_editor.sqlite';
    TestMock::set_test_dependent_db();
}

sub END {
    TestMock::remove_test_db();
}


my $cgi_file = "SaveForm1_win.pl";
my $path     = $FindBin::RealBin . "../../../../common/cgi-bin/" ;

my $DBH = new DBH( { DB_HANDLE => &DBConnHandler::init(), noparams => 1 } ) ;

subtest 'invalid_inputs' => sub {
    my $json = qq({'LoginForm':{'acc':'trenyika','pwd':'sss'}});
    
    my $res = %{ TestMock::get_result_of_fcgi( $path . $cgi_file, $json) }{ref};
    ok(!defined $res->{ LoginForm }, "returned object is undefined");
    ok(defined $res->{ 'time' }->{ LoginForm }, "execution time for LoginForm calculated");
    
    #
    $DBH->my_insert({
        table   => "partner",
        insert  => {
            username  => "trenyika",
            password  => "ebbc3c26a34b609dc46f5c3378f96e08",
            activated => 0
        }
    });
    $json = qq({'LoginForm':{'acc':'trenyika','pwd':'ebbc3c26a34b609dc46f5c3378f96e08'}});
    $res = %{ TestMock::get_result_of_fcgi( $path . $cgi_file, $json) }{ref};
    ok(!defined $res->{ LoginForm }, "returned object is undefined in case of not activated");
    ok(defined $res->{ 'time' }->{ LoginForm }, "execution time for LoginForm calculated");
    
    #
    $DBH->my_update({
        table   => "partner",
        where  => {
            username  => "trenyika",
            password  => "ebbc3c26a34b609dc46f5c3378f96e08",
        },
        relation => 'AND',
        update => {
            activated => 1
        }
    });
    $json = qq({'LoginForm':{'acc':'trenyika','pwd':'ebbc3c26a34b609dc46f5c3378f96e08s'}});
    $res = %{ TestMock::get_result_of_fcgi( $path . $cgi_file, $json) }{ref};
    ok(!defined $res->{ LoginForm }, "returned object is undefined in case of not activated");
    ok(defined $res->{ 'time' }->{ LoginForm }, "execution time for LoginForm calculated");
    
};

subtest 'valid login' => sub {
    # set up mock data
    $DBH->my_update({
        table   => "partner",
        where  => {
            username  => "trenyika",
            password  => "ebbc3c26a34b609dc46f5c3378",
        },
        relation => 'AND',
        update => {
            activated => 1
        }
    });
    
    # call service wih json
    my $json = qq({'LoginForm':{'acc':'trenyika','pwd':'ebbc3c26a34b609dc46f5c3378'}});
    my $res = %{ TestMock::get_result_of_fcgi( $path . $cgi_file, $json) }{ref};
    
    # assertions
    ok($res->{ LoginForm }->{ username } eq 'trenyika', "username returned");
    ok(defined $res->{ LoginForm }->{ session }, "session id calculated");
};


subtest 'send_activation_request' => sub {
    #
    my $json = qq({'send_activation_request':{'name':'tadam','partner_id':'1','email':'bla.bla\@bla.hu'}});
    my $res = %{ TestMock::get_result_of_fcgi( $path . $cgi_file, $json) }{ref};
    
    ok( $res->{ send_activation_request }->{ to } eq 'bla.bla@bla.hu', 'email is ok' );
    ok( $res->{ send_activation_request }->{ body } =~ /ValidateUser="1"/smx, "user id passed");
    ok( $res->{ send_activation_request }->{ body } =~ /tadam/smx, "name of the applicant");
};




$DBH->disconnect();