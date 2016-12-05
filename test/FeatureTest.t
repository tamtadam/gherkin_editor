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

subtest 'get_feature_list' => sub {
    my $res = $ma->get_feature_list();
    is_deeply($res, [
          {
            'FeatureID' => 1,
            'Title' => 'TestFeature0',
            'Locked' => 0,
            'LastModified' => '2016'
          },
          {
            'LastModified' => '2016',
            'Locked' => 1,
            'Title' => 'TestFeature1',
            'FeatureID' => 2
          },
          {
            'FeatureID' => 3,
            'Title' => 'TestFeature2',
            'Locked' => 0,
            'LastModified' => '2016'
          }
        ], 'All feature');

    $DBH->my_delete({
        from  => 'Feature',
        where => {
            FeatureID => $_
        },
    }) for 0..3;

    $ma->get_feature_list();
    my @error = $err_handler_mock->add_error();

    is(ref $error[ 0 ], 'Modell_ajax', 'correct package');
    is( $error[ 1 ], 'FEA_LIST', 'Error: fealist' );

    $DBH->my_insert({
        table  => 'Feature',
        insert => {
                   Title  => 'TestFeature' . $_ ,
                   Locked => $_ % 2,
        },
    }) for 0..2;
    $err_handler_mock->empty_buffers( 'add_error' );
};

subtest 'add_new_fea_to_fealist' => sub {
    my $res = $ma->add_new_fea_to_fealist( { Title => 'NewFeature' } ) ;
    ok( $res, 'ID returned' );

    $res = $ma->add_new_fea_to_fealist( { Title => undef } ) ;

    my @error = $err_handler_mock->add_error();
    is( ref $error[ 0 ], 'Modell_ajax', 'correct package' );
    is( $error[ 1 ], 'FAILEDPARAMETER', 'Error: fealist' );
    $err_handler_mock->empty_buffers( 'add_error' );
};

subtest 'get_feature_locked_status' => sub {
    my $res = $ma->get_feature_locked_status();
    is( (scalar @{ $res }), (scalar grep { $_->{LockedStatus} } @{ $res }), 'only locked features' );

    $DBH->my_update({
        table => 'Feature',
        update => {
            Locked => 0,
        },
        where => {
            Locked => 1,
        }
    });

    $res = $ma->get_feature_locked_status();
    my @error = $err_handler_mock->add_error();
    is( ref $error[ 0 ], 'Modell_ajax', 'correct package' );
    is( $error[ 1 ], 'LOCKUNLOCK', 'Error: LOCKUNLOCK' );
    $err_handler_mock->empty_buffers( 'add_error' );

};

subtest 'Feature_is_locked' => sub {
    $DBH->my_update({
        table => 'Feature',
        update => {
            Locked => 0,
        },
        where => {
            FeatureID => 5,
        }
    });
    my $res = $ma->Feature_is_locked({ FeatureID => 5 });
    my $fea = $DBH->my_select({
        from   => 'Feature',
        select => 'ALL',
        where  => {
            FeatureID => 5 
        },
    });
    is( $fea->[ 0 ]{Locked}, 1, "Locked" );

    $res = $ma->Feature_is_locked();
    my @error = $err_handler_mock->add_error();
    is( ref $error[ 0 ], 'Modell_ajax', 'correct package' );
    is( $error[ 1 ], 'FEATUREIDISMISSING', 'Error: FEATUREIDISMISSING' );
};

subtest 'Feature_is_unlocked' => sub {
    $DBH->my_update({
        table => 'Feature',
        update => {
            Locked => 1,
        },
        where => {
            FeatureID => 5,
        }
    });
    my $res = $ma->Feature_is_unlocked({ FeatureID => 5 });
    my $fea = $DBH->my_select({
        from   => 'Feature',
        select => 'ALL',
        where  => {
            FeatureID => 5 
        },
    });
    is( $fea->[ 0 ]{Locked}, 0, "UNLocked" );

    $res = $ma->Feature_is_locked();
    my @error = $err_handler_mock->add_error();
    is( ref $error[ 0 ], 'Modell_ajax', 'correct package' );
    is( $error[ 1 ], 'FEATUREIDISMISSING', 'Error: FEATUREIDISMISSING' );
};