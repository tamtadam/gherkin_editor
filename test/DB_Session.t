use strict;
use warnings;
use Data::Dumper;

use FindBin ;
use lib $FindBin::RealBin;
use lib $FindBin::RealBin . "../../../common/cgi-bin/" ;
use lib $FindBin::RealBin . "../../cgi-bin/" ;

use Test::More tests => 1;

use TestMock;
use DBConnHandler;
use DB_Session;
use Errormsg;

my $db;
my $db_session;
my $DBH;

$db_session = DB_Session->new( { DB_HANDLE => $db } );

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
    $DBH->my_insert({
        table => 'partner',
        insert => {
            (map { $_ => $_ } qw(email username name password)),
            activated => 1
        }
    });
}


subtest 'check_password' => sub {
    my $res = $db_session->check_password({
        acc => 'username',
        pwd => 'password',
    });
    ok( $res, 'user ok' );
    
    $res = $db_session->check_password({
        acc => 'username',
        pwd => 'pasasdfasdasdf',
    });
    ok( !$res, 'user not ok' );
};
