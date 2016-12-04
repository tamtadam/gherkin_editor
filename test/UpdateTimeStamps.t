use strict;
use warnings;
use Data::Dumper;

use FindBin ;
use lib $FindBin::RealBin;
use lib $FindBin::RealBin . "../../../common/cgi-bin/" ;
use lib $FindBin::RealBin . "../../cgi-bin/" ;

use Test::More tests => 4;

use TestMock;
use DBConnHandler;
use Modell_ajax;

my $db;
my $ma;
my $DBH;


my $err_handler_mock = TestMock->new( 'Errormsg' );
   $err_handler_mock->mock( 'new' );
   $err_handler_mock->mock( 'new' );

sub BEGIN {
    $ENV{ TEST_SQLITE } = q~f:\GIT\gherkin_editor\sql\gherkin_editor.sqlite~;
    TestMock::set_test_dependent_db();
    $db = DBConnHandler::init();
    #DBConnHandler::init_sqlite_db( map{
    #    '../sql/' . $_
    #} qw( session.sqlite feature.sqlite scenario.sqlite ) );
    $ma = Modell_ajax->new( { DB_HANDLE => $db } );
    $DBH = new DBH( { DB_HANDLE => $db } ) ;
}

sub END {
    DBConnHandler::disconnect();
    TestMock::remove_test_db();
}


sub INIT {
    $DBH->my_insert({
        table  => 'Feature',
        insert => {
                   'Title' => 'TestFeature' . $_ ,
        },
    }) for 0..2;
    
    $DBH->my_insert({
        table  => 'Scenario',
        insert => {
                   Title => 'TestScenario' . $_ ,
                   Description => 'desc' . $_,
        },
    }) for 0..3;
}

subtest '_update_timestamp_in_table' => sub {
    $ma->_update_timestamp_in_table('Feature', 'FeatureID', 1);
    my $res = $DBH->my_select(
                                {
                                  'from'   => 'Feature',
                                  'select' => 'ALL',
                                  'where'  => {
                                      FeatureID => 1,   
                                  },
                                }
                              ) ;
    is($res->[ 0 ]{ LastModified }, convert_time_to_format(), 'Time updated');
    
};
  
subtest 'update_timestamp_in_feature' => sub {
    $ma->update_timestamp_in_feature(2);
    my $res = $DBH->my_select({
       'from'   => 'Feature',
       'select' => 'ALL',
       'where'  => {
                FeatureID => 2,   
            },
    }) ;
    is($res->[ 0 ]{ LastModified }, convert_time_to_format(), 'Time updated');
};

subtest 'update_timestamp_in_scenario' => sub {
    $ma->update_timestamp_in_scenario(2);
    my $res = $DBH->my_select({
       'from'   => 'Scenario',
       'select' => 'ALL',
       'where'  => {
                ScenarioID => 2,   
            },
    }) ;
    is($res->[ 0 ]{ LastModified }, convert_time_to_format(), 'Time updated');
};

subtest 'update_timestamps' => sub {
    $ma->update_timestamps(1, 1);
    my $res = $DBH->my_select({
       'from'   => 'Scenario',
       'select' => 'ALL',
       'where'  => {
                ScenarioID => 1,   
            },
    }) ;
    is($res->[ 0 ]{ LastModified }, convert_time_to_format(), 'Time updated');
    
    $res = $DBH->my_select({
       'from'   => 'Feature',
       'select' => 'ALL',
       'where'  => {
                FeatureID => 1,   
            },
    }) ;
    is($res->[ 0 ]{ LastModified }, convert_time_to_format(), 'Time updated');
};


sub convert_time_to_format {
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    my $now = sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $mday, $hour, $min, $sec);
    return $now;
}
    


