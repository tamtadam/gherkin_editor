use strict;
use warnings;
use Data::Dumper;

use FindBin ;
use lib $FindBin::RealBin;
use lib $FindBin::RealBin . "../../../common/cgi-bin/" ;

use TestMock;
use DBConnHandler;
use Modell_ajax;

my $ma = Modell_ajax->new();

sub BEGIN {
    $ENV{ TEST_SQLITE } = q~f:\GIT\gherkin_editor\sql\gherkin_editor.sqlite~;
    TestMock::set_test_dependent_db();
    my $db = DBConnHandler::init();
    DBConnHandler::init_sqlite_db( q~F:\GIT\gherkin_editor\sql\session.sqlite~ );
}

sub END {
    DBConnHandler::disconnect();
    TestMock::remove_test_db();
}


