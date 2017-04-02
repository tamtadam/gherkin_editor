use strict;
use warnings;
use Data::Dumper;

use FindBin ;
use lib $FindBin::RealBin;
use lib $FindBin::RealBin . "../../../common/cgi-bin/" ;
use lib $FindBin::RealBin . "../../cgi-bin/" ;

use Test::More tests => 3;

use TestMock;

sub BEGIN {
    $ENV{ TEST_SQLITE } = q~../sql/gherkin_editor.sqlite~;
    TestMock::set_test_dependent_db();
}

sub END {
    TestMock::remove_test_db();
}


my $cgi_file = "SaveForm1_win.pl";
my $path     = "f:/xampp/cgi-bin/gherkin_editor/" ;

my $json = qq(
    {
      "LoginForm": {
        "acc":"trenyika","pwd":"ebbc3c26a34b609dc46f5c3378f96e08"
      },
      "session_data":{"session":""}
    }
);

my $res = TestMock::get_result_of_fcgi( $path . $cgi_file, $json);

print Dumper $res;

