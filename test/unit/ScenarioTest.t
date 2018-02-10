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
use Errormsg;
my $db;
my $ma;
my $DBH;


my $err_handler_mock = TestMock->new( 'Errormsg' );
   $err_handler_mock->mock( 'new' );
   $err_handler_mock->mock( 'add_error' );

$ma = Modell_ajax->new( { DB_HANDLE => $db } );

sub BEGIN {
    $ENV{ TEST_SQLITE } = q~f:/GIT/gherkin_editor/sql/gherkin_editor.sqlite~;
    TestMock::set_test_dependent_db();
    $db = DBConnHandler::init();
    $DBH = new DBH( { DB_HANDLE => $db, noparams => 1 } ) ;
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
                   'Locked' => $_ % 2,
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

subtest 'add_new_scen_to_scenlist' => sub {
    my $res = $ma->add_new_scen_to_scenlist( {
        Description => 'New Scenario'
    } );

    $res = $ma->add_new_scen_to_scenlist( { Description => undef } ) ;

    my @error = $err_handler_mock->add_error();
    is( ref $error[ 0 ], 'Modell_ajax', 'correct package' );
    is( $error[ 1 ], 'NEW_SCENARIO', 'Error: NEW_SCENARIO' );
    $err_handler_mock->empty_buffers( 'add_error' );
};

subtest 'clear_scen' => sub {
    my $res = $ma->clear_scen({
        ScenarioID => 5
    });
    ok($res, 'Scenario deleted');
    $res = $DBH->my_select({
        from   => 'Scenario',
        select => 'ALL',
        where  => {
            ScenarioID => 5
        },
    });
    is($res, undef, 'succesfully deleted');
};

subtest 'check_input_data_for_add_scenario' => sub {
    my $res = $ma->check_input_data_for_add_scenario({
        Title => '23123'
    });
    ok($res, 'all data filled');

    $res = $ma->check_input_data_for_add_scenario({
        Title => undef
    });
    ok(0 == $res, 'some data isn\'t filled');

    $res = $ma->check_input_data_for_add_scenario();
    ok(0 == $res, 'some data isn\'t filled');
};


subtest 'get_scen_list' => sub {
    my $res = $ma->get_scen_list();
    is_deeply( $res,
    [
          {
            'Description' => 'desc0',
            'Cnt' => 0,
            'ScenarioID' => 1,
            'Locked' => 0,
            'LastModified' => '2016',
            'Title' => 'TestScenario0'
          },
          {
            'Description' => 'desc1',
            'Cnt' => 0,
            'ScenarioID' => 2,
            'Locked' => 0,
            'Title' => 'TestScenario1',
            'LastModified' => '2016'
          },
          {
            'Description' => 'desc2',
            'Cnt' => 0,
            'ScenarioID' => 3,
            'Title' => 'TestScenario2',
            'Locked' => 0,
            'LastModified' => '2016'
          },
          {
            'Title' => 'TestScenario3',
            'Cnt' => 0,
            'Locked' => 0,
            'LastModified' => '2016',
            'ScenarioID' => 4,
            'Description' => 'desc3'
          }
        ], 'scen list');

    $DBH->my_delete({
        from  => 'Scenario',
        where => {
            ScenarioID => $_
        },
    }) for 0..4;

    $res = $ma->get_scen_list();
    is_deeply($res, [], 'empty list');
};

