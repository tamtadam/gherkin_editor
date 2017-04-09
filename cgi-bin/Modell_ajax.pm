package Modell_ajax ;

use FindBin ;
use lib $FindBin::RealBin;
use lib $FindBin::RealBin . "/cgi-bin/" ;

use strict ;
use warnings ;
use DBH ;
use Data::Dumper ;
use Log ;
use Errormsg ;
use JSON ;
use utf8 ;
use DBConnHandler qw( $DB) ;
use DBDispatcher qw( convert_sql );
use Email;
use Template;
use constant SINGLE   => 'single' ;
use constant MULTIPLE => 'multiple' ;

our @ISA = qw( Log DBH Errormsg ) ;
my $complete_sentence_IDs_array ;

my $item_name          = "ItemID" ;
my $screen_name        = "ScreenID" ;
my $comunication_line  = "CommunicationLineID" ;
my $scroll_name        = "ScrollbarID" ;
my $screenshot_sent_id = 0 ;
my $path_prefix        = "feature_" ;
my $gherkin_words ;
my $screenshot_name = "ScreenstateID" ;

my $ITEM_TYPE_TO_TABLE = {
                           $item_name => {
                                           'table'       => 'Item',
                                           'id'          => 'ItemID',
                                           'name'        => 'ItemName',
                                           'id_on_c_s_t' => 'ItemID',
                                         },
                           $scroll_name => {
                                             'table'       => 'Item',
                                             'id'          => 'ItemID',
                                             'name'        => 'ItemName',
                                             'id_on_c_s_t' => 'ScrollbarID',
                                           },
                           $screen_name => {
                                             'table'       => 'Screen',
                                             'id'          => 'ScreenID',
                                             'name'        => 'ScreenName',
                                             'id_on_c_s_t' => 'ScreenID',
                                           },
                           $screenshot_name => {
                                                 'table'       => 'Screenstate',
                                                 'id'          => 'ScreenstateID',
                                                 'name'        => 'ScreenStateName',
                                                 'id_in_c_s_t' => 'ScreenstateID',
                                               },
                           $comunication_line => {
                                                   'table'       => 'CommunicationLine',
                                                   'id'          => 'CommunicationLineID',
                                                   'name'        => 'CommunicationLineText',
                                                   'id_on_c_s_t' => 'CommunicationLineID',
                                                 },
                         } ;

sub new {
    my $instance = shift ;
    my $class    = ref $instance || $instance ;
    my $self     = {} ;

    bless $self, $class ;

    $self->start_time( @{ [ caller( 0 ) ] }[ 3 ], \@_ ) ;
    $self->init( @_ ) ;
    $self ;
} ## end sub new

sub init {
    my $self = shift ;
    eval '$self->' . "$_" . '::init( @_ )' for @ISA ;

    $self->{ $_ } = $_[ 0 ]->{ $_ } for qw(DB_HANDLE DB_Session);

    $self->start_time( @{ [ caller( 0 ) ] }[ 3 ], \@_ ) ;

    $self ;
} ## end sub init

#unit tested
sub get_feature_list {
    my $self   = shift ;
    my $result = undef ;

    $result = $self->my_select(
                                {
                                  'from'   => 'feature AS f',
                                  'select' => [
                                  				'f.Title             AS Title',
                                  				'f.Locked            AS Locked',
                                  				'f.FeatureID         AS FeatureID',
                                  				'count(fs.FeatureID) AS Cnt'
                                  			  ],
                                  'group_by' => "f.FeatureID",
                                  "join" => "LEFT JOIN featurescenario fs ON (f.FeatureID = fs.FeatureID)",		
                                  "sort" => "f.Title",
                                }
                              ) ;
    if ( !$result ) {
        $self->add_error( 'FEA_LIST' ) ;
        return $result;
    } ## end if ( !$result )
    $self->delete_expired_locks_in_feature() ;
    $self->delete_expired_locks_in_scenario() ;
    return $result ;
} ## end sub get_feature_list

#FEATURE-SCENARIO

sub get_feature_scenario_datas {
    my $self = shift ;

    my $result = $self->my_select(
                                   {
                                     'from'     => 'featurescenario',
                                     'select'   => 'FeatureID',
                                     'group_by' => 'FeatureID',
                                   }
                                 ) ;
    if ( !$result ) {
        $self->add_error( 'DB_SELECT' ) ;

    } ## end if ( !$result )
    return $result ;
} ## end sub get_feature_scenario_datas

#unit tested
sub add_new_fea_to_fealist {
    my $self        = shift ;
    my $result;

    $self->start_time( @{ [ caller( 0 ) ] }[ 3 ], $_[ 0 ] ) ;

    if ( $self->check_input_data_for_add_feature( @_ ) and
         $_[ 0 ]->{ 'Title' } =~ /\w+/ ) {
        unless (
                 $self->my_select(
                                   {
                                     'from'   => 'Feature',
                                     'select' => 'FeatureID',
                                     'where'  => {
                                                  "Title" => $_[ 0 ]->{ 'Title' },
                                                }
                                   }
                                 )
               )
        {
            $result = $self->my_insert(
                                                       {
                                                         'insert' => {
                                                                       'Title' => $_[ 0 ]->{ 'Title' },
                                                                     },
                                                         'table'  => 'Feature',
                                                         'select' => 'FeatureID',
                                                       }
                                                     ) ;

        } else {
            $self->add_error( 'FEATURE_NOT_ADDED' );
        }
    } else {
        $self->add_error( 'FAILEDPARAMETER' ) ;

    } ## end else [ if ( $self->check_input_data_for_add_feature...)]

    return $result ;
} ## end sub add_new_fea_to_fealist


#TODO add_error!!
sub add_new_proj_to_projlist {
    my $self        = shift ;
    my $result;

    $self->start_time( @{ [ caller( 0 ) ] }[ 3 ], $_[ 0 ] ) ;

    if ( $self->check_input_data_for_add_feature( @_ ) and
         $_[ 0 ]->{ 'Title' } =~ /\w+/ ) {
        unless (
                 $self->my_select(
                                   {
                                     'from'   => 'project',
                                     'select' => 'ProjectID',
                                     'where'  => {
                                                  "Title" => $_[ 0 ]->{ 'Title' },
                                                }
                                   }
                                 )
               )
        {
            $result = $self->my_insert(
                                                       {
                                                         'insert' => {
                                                                       'Title' => $_[ 0 ]->{ 'Title' },
                                                                     },
                                                         'table'  => 'project',
                                                         'select' => 'ProjectID',
                                                       }
                                                     ) ;

        } else {
            $self->add_error( 'FEATURE_NOT_ADDED' );
        }
    } else {
        $self->add_error( 'FAILEDPARAMETER' ) ;

    } ## end else [ if ( $self->check_input_data_for_add_feature...)]

    return $result ;
} ## end sub add_new_fea_to_fealist


#unit tested
#OK
sub check_input_data_for_add_feature {
    my $self = shift ;
    my $param = shift || {};

    return $param->{ 'Title' } ? 1 : 0; ## end sub check_input_data_for_add_feature
}

#unit tested
#OK
sub delete_feature {
    my $self = shift ;
    my $params = shift || {};
    $self->add_error( 'FAILEDPARAMETER' ) unless $params->{ 'FeatureID' };
    my $result;

    $result = $self->my_delete(
                               {
                                 'from'  => 'featurescenario',
                                 'where' => {
                                              FeatureID => $params->{ 'FeatureID' },
                                            },
                               }
                             ) ;
    $result = $self->my_delete(
                               {
                                 'from'  => 'Feature',
                                 'where' => {
                                              FeatureID => $params->{ 'FeatureID' },
                                            },
                               }
                             ) ;
    return $result ;
} ## end sub delete_feature

#OK
sub get_scenario_locked_status {
    my $self = shift ;

    my $result = $self->my_select(
              {
                'from'   => 'Scenario',
                'select' => [ 'Locked AS LockedStatus', 'Title  AS ScenarioName', 'ScenarioID  AS ScenarioID', ],
                'where' => { 'Locked' => 1 },
              }
    ) ;
    if ( !$result ) {
        $self->add_error( 'LOCKUNLOCK' ) ;

    } ## end if ( !$result )
    return $result ;
} ## end sub get_scenario_locked_status


#unit tested
sub get_feature_locked_status {
    my $self = shift ;

    my $result = $self->my_select(
           {
             'from'   => 'Feature AS fea',
             'select' => [ 'fea.Locked AS LockedStatus', 'fea.Title  AS FeatureName', 'fea.FeatureID  AS FeatureID', ],
             'where' => { 'fea.Locked' => 1 },
           }
    ) ;
    $self->start_time( @{ [ caller( 0 ) ] }[ 3 ], $result ) ;
    if ( !$result ) {
        $self->add_error( 'LOCKUNLOCK' ) ;

    } ## end if ( !$result )
    return $result ;
} ## end sub get_feature_locked_status


#unit tested
sub Feature_is_locked {
    my $self = shift ;
    my $feature_id = $_[ 0 ]->{ FeatureID } or do {
        $self->add_error( 'FEATUREIDISMISSING' );
        return;
    };

    $self->start_time( @{ [ caller( 0 ) ] }[ 3 ], \@_ ) ;

    $self->update_timestamp_in_feature( $_[ 0 ]->{ 'FeatureID' } ) ;

    my $result = $self->my_update(
                                   {
                                     'update' => { 'Locked' => "1" },
                                     'where'  => {
                                                  'FeatureID' => $feature_id,
                                                },
                                     'table' => 'Feature',
                                   }
                                 ) ;

    $self->start_time( @{ [ caller( 0 ) ] }[ 3 ], \@_ ) ;

    $self->delete_expired_locks_in_feature() ;
    $self->delete_expired_locks_in_scenario() ;
    return $result ;
} ## end sub Feature_is_locked

#unit tested
sub Feature_is_unlocked {
    my $self = shift ;
    my $feature_id = $_[ 0 ]->{ FeatureID } or do {
        $self->add_error( 'FEATUREIDISMISSING' );
        return;
    };

    $self->start_time( @{ [ caller( 0 ) ] }[ 3 ], \@_ ) ;

    my $result = $self->my_update(
                                   {
                                     'update' => { 'Locked' => "0" },
                                     'where'  => {
                                                  'FeatureID' => $feature_id,
                                                },
                                     'table' => 'Feature',
                                   }
                                 ) ;
    $self->delete_expired_locks_in_feature() ;
    $self->delete_expired_locks_in_scenario() ;
    return $result ;
} ## end sub Feature_is_unlocked

#unit tested
sub update_timestamps {
    my $self       = shift ;
    my $FeatureID  = shift ;
    my $ScenarioID = shift ;

    if ( -1 != $FeatureID ) {
        $self->update_timestamp_in_feature( $FeatureID ) ;
    } ## end if ( -1 != $FeatureID )

    if ( -1 != $ScenarioID ) {
        $self->update_timestamp_in_scenario( $ScenarioID ) ;
    } ## end if ( -1 != $ScenarioID)

    $self->delete_expired_locks_in_feature() ;
    $self->delete_expired_locks_in_scenario() ;
} ## end sub update_timestamps


#unit tested
sub update_timestamp_in_feature {
    my $self   = shift ;
    my $fea_id = shift ;

    $self->_update_timestamp_in_table( "Feature", "FeatureID", $fea_id ) ;
} ## end sub update_timestamp_in_feature

#unit tested
sub update_timestamp_in_scenario {
    my $self        = shift ;
    my $scenario_id = shift ;

    $self->_update_timestamp_in_table( "Scenario", "ScenarioID", $scenario_id ) ;
} ## end sub update_timestamp_in_scenario

#unit tested
sub _update_timestamp_in_table {
    my $self    = shift ;
    my $table   = shift ;
    my $id_name = shift ;
    my $id_data = shift ;

    $self->execute_sql( "UPDATE $table SET LastModified = " . convert_sql("NOW{}") .  " WHERE $id_name = ?", $id_data ) ;
} ## end sub _update_timestamp_in_table

sub delete_expired_locks_in_scenario {

    #$_[ 0 ]->_delete_expired_locks_in_table( "Scenario" ) ;
} ## end sub delete_expired_locks_in_scenario

sub delete_expired_locks_in_feature {

    #$_[ 0 ]->_delete_expired_locks_in_table( "Feature" ) ;
} ## end sub delete_expired_locks_in_feature

sub _delete_expired_locks_in_table {
    my $self  = shift ;
    my $table = shift ;

    #$self->execute_sql( convert_sql( "SQLSAFEUPDATES{0}" ) );

#$gth = $self->{ 'DB_HANDLE' }->prepare( "UPDATE $table SET Locked = 0 WHERE TIME_TO_SEC( TIMEDIFF( NOW(), LastModified ) ) / 60 > 120" ) ;
#$self->start_time( @{ [ caller(0) ] }[3], $gth ) ;
#$res = $gth->execute() ;

    return 1 ;
} ## end sub _delete_expired_locks_in_table

#SCENARIO
#OK
sub get_features_by_scenario_id {
    my $self   = shift ;
    my $result = undef ;

    $result = $self->my_select(
        {
           'from' => 'Feature AS fea',

           'select' => [ 'fea.Title     AS Title', 'fea.FeatureID AS FeatureID', ],

           'join' => 'JOIN featurescenario AS fea_scen ON ( fea.FeatureID = fea_scen.FeatureID )',

           'where' => {
                        "fea_scen.ScenarioID" => $_[ 0 ]->{ 'ScenarioID' }
                      },
            'group_by' => 'fea.FeatureID',
			'order_by' => 'fea.Title',
        }
    ) ;

    return $result ;
} ## end sub get_features_by_scenario_id

#unit tested
sub clear_scen {
    my $self   = shift ;
    my $result = undef ;

    $result = $self->my_delete(
                                {
                                  'from'   => 'Scenario',
                                  'select' => '',
                                  'where'  => {
                                               "ScenarioID" => $_[ 0 ]->{ 'ScenarioID' },
                                             },
                                }
                              ) ;

    if ( !$result ) {
        $self->add_error( 'DELETE_SCENARIO' ) ;

    } ## end if ( !$result )
    return $result ;
} ## end sub clear_scen

#OK
#unit tested
sub add_new_scen_to_scenlist {
    my $self         = shift ;
    my $new_scenario = undef ;

    if ( $self->check_input_data_for_add_scenario( @_ ) ) {
        unless (
                 $self->my_select(
                                   {
                                     'from'   => 'Scenario',
                                     'select' => 'ScenarioID',
                                     'where'  => {
                                                  "Title" => $_[ 0 ]->{ 'Title' },
                                                }
                                   }
                                 )
               )
        {
            $new_scenario = $self->my_insert(
                                              {
                                                'insert' => {
                                                              'Title' => $_[ 0 ]->{ 'Title' },
                                                            },
                                                'table'  => 'Scenario',
                                                'select' => 'ScenarioID',
                                              }
                                            ) ;
        } ## end unless ( $self->my_select(...))
    } ## end if ( $self->check_input_data_for_add_scenario...)

    if ( !$new_scenario ) {
        $self->add_error( 'NEW_SCENARIO' ) ;

    } ## end if ( !$new_scenario )
    return $new_scenario ;
} ## end sub add_new_scen_to_scenlist

#unit tested
sub check_input_data_for_add_scenario {
    my $self = shift ;
    if ( $_[ 0 ]->{ 'Title' } ) {
        return 1 ;
    } else {
        return 0 ;
    } ## end else [ if ( $_[ 0 ]->{ 'Title'...})]
} ## end sub check_input_data_for_add_scenario

#OK
#unit tested
sub get_scen_list {
    my $self   = shift ;
    my $result = undef ;

    $result = $self->my_select(
                                {
                                  'from'   => 'Scenario',
                                  'select' => 'ALL',
                                  "sort"   => "Title",
                                }
                              ) ;
	
    if ( !$result ) {
        $self->add_error( 'SCENARIO_LIST' ) ;

    } ## end if ( !$result )

    if($result){
    	foreach(@{$result}){
    		$_->{Cnt} = 0;
    	}
    }

    return $result || [] ;

} ## end sub get_scen_list

#OK
sub save_scenarios_to_feature {
    my $self      = shift ;
    my $order_cnt = 0 ;
    my $result;

    if ( $self->check_input_data_for_save_scenarios_to_feature( @_ ) ) {

        #      $self->update_timestamps( $_[ 0 ]->{ 'FeatureID' }, -1 ) ;
        $self->my_delete(
                          {
                            'from'   => 'featurescenario',
                            'select' => '',
                            'where'  => {
                                         "FeatureID" => $_[ 0 ]->{ 'FeatureID' },
                                       },
                          }
                        ) ;
        foreach my $scenario_id ( @{ $_[ 0 ]->{ 'ScenarioList' } } ) {
            $result = $self->my_insert(
                                                       {
                                                         'insert' => {
                                                                       "FeatureID"  => $_[ 0 ]->{ 'FeatureID' },
                                                                       "ScenarioID" => $scenario_id,
                                                                       "Position"   => $order_cnt,
                                                                     },
                                                         'table'  => 'featurescenario',
                                                         'select' => 'featurescenarioID',
                                                       }
                                                     ) ;

            if ( $result ) {
                $order_cnt++ ;
            } ## end if ( $result->{ 'VERDICT'...})
        } ## end foreach my $scenario_id ( @...)
    } else {

    } ## end else [ if ( $self->check_input_data_for_save_scenarios_to_feature...)]
    $self->start_time( @{ [ caller( 0 ) ] }[ 3 ], $result ) ;

    if ( !$result ) {
        $self->add_error( 'SAVE_SCENARIOS_FOR_FEAS' ) ;

    } ## end if ( !$result )
    return $result ;
} ## end sub save_scenarios_to_feature

#unit tested
#OK
sub check_input_data_for_save_scenarios_to_feature {
    my $self = shift ;
    my $param = shift || {};
    return ( $param->{ FeatureID } and $param->{ ScenarioList } ? 1 : 0 ) ;
} ## end sub check_input_data_for_save_scenarios_to_feature

#unit tested
sub add_scen_to_fea {
    my $self = shift ;
    my $param = shift || {};

    my $result = $self->my_insert({
        'insert' => {
            "FeatureID"  => $param->{ 'FeatureID' },
            "ScenarioID" => $param->{ 'ScenarioID' },
            "Position"   => $param->{ 'Position' },
        },
        'table'  => 'featurescenario',
    'select' => 'featurescenarioID',
    });
    if ( !$result ) {
        $self->add_error( 'featurescenario' ) ;

    } ## end if ( !$result )

    return $result;
} ## end sub add_scen_to_fea


sub saveNewUser {
    my $self  = shift;
    my $param = shift;
    $self->start_time( @{ [ caller(0) ] }[3], $param );

    $self->add_error( 'PARAM_ERROR' ) and return unless $self->check_input_data_for_save_new_user( $param );
    my $res = $self->my_select({
        from => 'partner',
        where => {
            email => $param->{ email }
        }
    });

    $self->add_error( 'USER_EXISTS' ) and return if $res;

    $param->{activated} = 0;

    $param->{ partner_id } = $self->my_insert(
        {
            table  => 'partner',
            insert => {
                map { $_ => $param->{ $_ } } qw(email username name password)
            },
            select => 'partner_id',
       }
    );
    if ( $param->{ partner_id } ) {
        $self->send_activation_request( $param );
    }
    return $param->{ partner_id };
}

sub send_activation_request {
    my $self = shift;
    $self->start_time( @{ [ caller(0) ] }[3], \@_ );
    my $param = shift || return ;
    my $templ = Template->new({
        "TYPE"   => Template::TYPE->{ FILE },
        "SOURCE" => "./templates/activation_link.tmpl",
    }) ;

    $templ->fill_in({
        USERNAME => $param->{ name },
        URL      => Cfg::get_data('CGIURL') . '?' . "ValidateUser=\"" . $param->{ partner_id } . '"'
    });

    Email::send_mail({
        to          => $param->{ email },
        body        => $templ->return_string(),
        subject     => 'Activation link',
        contenttype => 'text/html',
    });
}

sub check_input_data_for_save_new_user {
    my $self = shift ;
    my $param = shift || {};
    return ( ( scalar grep { $_ } map { $param->{ $_ } } qw(email username name password) ) == 4 ) ;
} ## end sub check_input_data_for_save_scenarios_to_feature


sub ValidateUser {
    my $self = shift;
    $self->start_time( @{ [ caller(0) ] }[3], \@_ );

    my $uid  = shift;
    $self->my_update({
        table  => 'partner',
        update => {
            activated => 1
        },
        where => {
            partner_id => $uid,
        }
    });
}


sub rename_scenario {
    my $self = shift;
    $self->start_time( @{ [ caller(0) ] }[3], \@_ );
    my $param = shift;

    return $self->my_update({
        table  => 'Scenario',
        update => {
            Title => $param->{NewScenarioName}
        },
        where => {
            ScenarioID => $param->{ScenarioID},
        }
    });
}

#OK
sub delete_scen_from_fea {
    my $self   = shift ;
    $self->start_time( @{ [ caller(0) ] }[3], \@_ );
    if ( $self->check_input_data_for_delete_scenario_from_feature( @_ ) ) {
        my $result = undef ;
        my $params = shift;
        my @feature_ids = ('ARRAY' eq ref $params->{ 'FeatureID' } ? @{ $params->{ 'FeatureID' } } : $params->{ 'FeatureID' } );


        $result = $self->my_delete(
                                    {
                                      'from'   => 'featurescenario',
                                      'select' => '',
                                      'where'  => {
                                                   "ScenarioID" => $params->{ 'ScenarioID' },
                                                   "FeatureID"  => $_
                                                 },
                                      "relation" => "and",
                                    }
                                  ) for @feature_ids;

        if ( !$result ) {
            $self->add_error( 'DEL_SCEN_FROM_FEA' ) ;
        } ## end if ( !$result )
        return $result ;
    } ## end if ( $self->check_input_data_for_delete_scenario_from_feature...)
} ## end sub delete_scen_from_fea

sub check_input_data_for_delete_scenario_from_feature {
    my $self = shift ;
    $self->start_time( @{ [ caller(0) ] }[3], \@_ );
    if (     $_[ 0 ]->{ 'ScenarioID' }
         and $_[ 0 ]->{ 'FeatureID' } )
    {
        return 1 ;
    } else {
        return 0 ;
    } ## end else [ if ( $_[ 0 ]->{ 'ScenarioID'...})]
} ## end sub check_input_data_for_delete_scenario_from_feature

#OK
sub get_scen_list_by_fea {
    my $self   = shift ;
    my $result = undef ;
    $self->start_time( @{ [ caller(0) ] }[3], \@_ );

    $result = $self->my_select({
           from   => 'Feature AS fea',
           select => [
                         'fea.FeatureID         AS FeatureID',
                         'fea.Title             AS FeatureName',
                         'fea_scen.ScenarioID   AS ScenarioID',
                         'scen.Title      AS ScenarioName'
                       ],
           join   => 'JOIN featurescenario AS fea_scen ON ( fea.FeatureID       = fea_scen.FeatureID )
                      JOIN Scenario        AS scen     ON ( fea_scen.ScenarioID = scen.ScenarioID )',
           where  => {
                        "fea.FeatureID" => $_[ 0 ]->{ 'FeatureID' }
                      },
           sort   => 'fea_scen.Position'
    });

    if ( !$result ) {
        $self->add_error( 'SCENLIST_BY_FEA' ) ;

    } ## end if ( !$result )
    return $result ;
} ## end sub get_scen_list_by_fea

sub get_feature_number_by_scen_id {
    my $self   = shift ;
    my $result = undef ;
    $self->start_time( @{ [ caller(0) ] }[3], \@_ );

    $result = $self->my_select({
           from   => 'featurescenario',
          'select' => [
                        'count(*) AS cnt'
                      ],
           where  => {
                        "ScenarioID" => $_[ 0 ]->{ 'ScenarioID' }
                      },
    });

    if ( !$result ) {
        $self->add_error( 'SCENLIST_BY_FEA' ) ;

    } ## end if ( !$result )
    return $result ;
}

###########################################################################################
###########################################################################################
###########################################################################################
###########################################################################################


sub Save_TestRunnerJUnit {
    my $self = shift ;

    my $outfile = 'TestRunnerJUnit' . '.java' ;
    open( FILE, ">$outfile" ) || die "problem opening $outfile\n" ;

    my $TestRunnerText = "" ;
    $TestRunnerText = $_[ 0 ]->{ 'TestRunnerText' } ;

    print FILE "$TestRunnerText" ;

    close( FILE ) ;

    return $outfile ;
} ## end sub Save_TestRunnerJUnit

sub get_versions {
    my $self   = shift ;
    my $result = undef ;

    $result = $self->my_select(
                                {
                                  'from'   => 'Versions',
                                  'select' => 'ALL',
                                  'sort'   => 'VersionID',
                                }
                              ) ;

    return $result ;
} ## end sub get_versions

sub Save_Feature {
    my $self = shift ;
    my $link = '/opt/lampp/htdocs/system_testeditor/temp_FeatureFiles/' ;

    unless ( -e $link ) {
        mkdir( $link ) ;
    } ## end unless ( -e $link )
    my $fea_name     = $_[ 0 ]->{ 'FeatureName' } ;
    my $outfile      = $link . "$fea_name.txt" ;
    my $sikerese     = open( FILE, ">", "$outfile" ) or die ;
    my $Feature_Text = "" ;
    print FILE "$_[ 0 ]->{ 'FeatureText' }" ;
    close( FILE ) ;

    if ( !$sikerese ) {
        $self->add_error( 'SAVE_FEATURE_TEXT' ) ;
        return 0 ;
    } else {
        return 1 ;
    } ## end else [ if ( !$sikerese ) ]
} ## end sub Save_Feature

sub Save_File {
    my $self = shift ;

    my $test_file->{ 'Name' } = $_[ 0 ]->{ 'Name' } ;
    my $filename = $_[ 0 ]->{ 'Name' } . '.js' ;
    $test_file->{ 'FileName' } = $filename ;
    $test_file->{ 'Text' }     = $_[ 0 ]->{ 'Text' } ;

    my $link    = '/opt/lampp/htdocs/scenario_editor_test/TestCaseFiles/' ;
    my $outfile = $link . $filename ;

    my $sikerese = open( FILE, ">$outfile" ) or $self->start_time( @{ [ caller( 0 ) ] }[ 3 ], $! . "ajjajj:$outfile" ) ;
    print FILE Dumper @{ $_[ 0 ]->{ 'Text' } } ;

    close( FILE ) ;

    if ( !$sikerese ) {
        $self->add_error( 'SAVE_FEATURE_TEXT' ) ;
        return 0 ;
    } else {
        return $test_file ;
    } ## end else [ if ( !$sikerese ) ]
} ## end sub Save_File

sub update_ScreenshotMode_evening_running {
    my $self = shift ;

    my $result = $self->my_update(
                                   {
                                     'update' => { 'Mode' => $_[ 0 ]->{ 'Mode' } },
                                     'where'  => {
                                                  'FeatureName' => $_[ 0 ]->{ 'FeatureName' }
                                                },
                                     'table' => 'Evening_running',
                                   }
                                 ) ;

    return $result ;
} ## end sub update_ScreenshotMode_evening_running

sub update_ScreenshotMode {
    my $self = shift ;
    $self->start_time( @{ [ caller( 0 ) ] }[ 3 ], \@_ ) ;

    my $result = $self->my_update(
                                   {
                                     'update' => { 'ScreenshotModeID' => $_[ 0 ]->{ 'ScreenshotModeID' } },
                                     'where'  => {
                                                  'FeatureID' => $_[ 0 ]->{ 'FeatureID' }
                                                },
                                     'table' => 'Feature',
                                   }
                                 ) ;
    $self->start_time( @{ [ caller( 0 ) ] }[ 3 ], $result ) ;

    return $result ;

} ## end sub update_ScreenshotMode

sub get_testfiles {
    my $self   = shift ;
    my $result = undef ;

    $result = $self->my_select(
                                {
                                  'from'   => 'Feature',
                                  'format' => 'FeatureID as value, Title as label',
                                }
                              ) ;

    if ( !$result ) {
        $self->add_error( 'FEA_LIST' ) ;
    } ## end if ( !$result )

    return $result ;

} ## end sub get_testfiles

sub get_regions {
    my $self   = shift ;
    my $result = undef ;

    $result = $self->my_select(
                                {
                                  'from'   => 'Region',
                                  'select' => 'ALL',
                                  'sort'   => 'RegionName',
                                }
                              ) ;

    $self->start_time( @{ [ caller( 0 ) ] }[ 3 ], $result ) ;

    if ( !$result ) {
        $self->add_error( 'REGION' ) ;
    } ## end if ( !$result )

    return $result ;
} ## end sub get_regions

sub get_testtypes {
    my $self   = shift ;
    my $result = undef ;

    $result = $self->my_select(
                                {
                                  'from'   => 'Test_type',
                                  'select' => 'ALL',
                                }
                              ) ;

    $self->start_time( @{ [ caller( 0 ) ] }[ 3 ], $result ) ;

    if ( !$result ) {
        $self->add_error( 'TEST_TYPE' ) ;
    } ## end if ( !$result )

    return $result ;
} ## end sub get_testtypes

sub get_fea_scen_ids {
    my $self = shift ;
    $self->my_select(
                      {
                        'from'   => 'featurescenario',
                        'select' => 'ScenarioID',
                        'where'  => {
                                     "FeatureID" => $_[ 0 ]->{ 'FeatureID' },
                                   },
                        "sort" => "Position",
                      }
                    ) ;
} ## end sub get_fea_scen_ids

sub ScenarioIds_by_FeatureID {
    my $self = shift ;
    $self->my_select(
                      {
                        'from'   => 'featurescenario',
                        'select' => 'ScenarioID',
                        'where'  => {
                                     "FeatureID" => $_[ 0 ]->{ 'FeatureID' },
                                   },
                        "sort" => "Position",
                      }
                    ) ;
} ## end sub ScenarioIds_by_FeatureID

sub get_scen_id_by_scen_in_fea_id {
    my $self = shift ;
    $self->my_select(
                      {
                        'from'   => 'featurescenario',
                        'select' => 'ScenarioID',
                        'where'  => {
                                     "FeatureID" => $_[ 0 ]->{ 'FeatureID' },
                                   },
                        "sort" => "Position",
                      }
                    ) ;
} ## end sub get_scen_id_by_scen_in_fea_id

sub get_max_position {
    my $self = shift ;
    $self->my_select(
                      {
                        'from'   => 'featurescenario',
                        'select' => 'Position',
                        'where'  => {
                                     "FeatureID" => $_[ 0 ]->{ 'FeatureID' },
                                   },
                        "sort" => "Position",
                      }
                    ) ;
} ## end sub get_max_position

sub get_act_position_by_fea_scenario_id {
    my $self   = shift ;
    my $result = undef ;

    return
      $result->{ 'VERDICT' } = $self->my_select(
                                                 {
                                                   'from'   => 'featurescenario',
                                                   'select' => 'Position',
                                                   'where'  => {
                                                                "featurescenarioID" => $_[ 0 ]->{ 'featurescenarioID' },
                                                              },
                                                 }
                                               ) ;
} ## end sub get_act_position_by_fea_scenario_id

sub get_gherkintext_by_fea {
    my $self        = shift ;
    my $feature_str = "" ;
    my $feature_with_gherkint_text_by_ids ;

    if ( $self->check_input_data_for_get_gherkintext_by_fea( @_ ) ) {

        $feature_with_gherkint_text_by_ids =
          $self->my_select(
                            {
                              'from'   => 'featurescenario',
                              'select' => "ScenarioID",
                              'where'  => {
                                           "FeatureID" => $_[ 0 ]->{ 'FeatureID' }
                                         },
                              "sort" => "Position",
                            }
                          ) ;
        my $scenario_header_in_feature = "" ;
        foreach my $comp_sent_id ( @{ $feature_with_gherkint_text_by_ids } ) {
            my $scenario_header_in_feature .=
              $self->set_scenario_header_in_feature(
                                                     {
                                                       'ScenarioID' => $comp_sent_id->{ 'ScenarioID' },
                                                     }
                                                   ) ;
            $feature_str .= $scenario_header_in_feature ;
            $feature_str .= $self->get_gherkintext_by_scen(
                {
                   'ScenarioID' => $comp_sent_id->{ 'ScenarioID' },

                }
              )
              . "\n\n" ;
        } ## end foreach my $comp_sent_id ( ...)

        $feature_str .= "And End Test" ;
        return $feature_str ;
    } ## end if ( $self->check_input_data_for_get_gherkintext_by_fea...)
} ## end sub get_gherkintext_by_fea

sub get_scen_name_by_scen_id {
    my $self           = shift ;
    my $scenario_datas = [] ;
    my $scenario_name  = [] ;

    $scenario_datas = $self->my_select(
                      {
                        'from'   => 'featurescenario AS fea_scen',
                        'select' => [ 'fea_scen.ScenarioID   AS ScenarioID', 'scen.Title      AS ScenarioName' ],
                        'join'   => 'JOIN Scenario        AS scen     ON ( fea_scen.ScenarioID = scen.ScenarioID )',
                        'where'  => {
                                     "fea_scen.ScenarioID" => $_[ 0 ]->{ 'fea_scen.ScenarioID' }
                                   }
                      }
      ),
      $scenario_datas = $scenario_datas->[ 0 ] ;
    $scenario_name = $scenario_datas->{ 'ScenarioName' },

      return $scenario_name ;
} ## end sub get_scen_name_by_scen_id

sub check_input_data_for_get_gherkintext_by_fea {
    my $self = shift ;
    if ( $_[ 0 ]->{ 'FeatureID' } ) {
        return 1 ;
    } else {
        return 0 ;
    } ## end else [ if ( $_[ 0 ]->{ 'FeatureID'...})]
} ## end sub check_input_data_for_get_gherkintext_by_fea

sub set_scenario_header_in_feature {
    my $self      = shift ;
    my $scen_id   = "" ;
    my $scen_name = "" ;

    my $scenario_header_in_feature_1 = "Scenario: " ;
    my $scenario_header_in_feature_2 = "\nGiven Scenario ID is " ;
    my $double_quote                 = "\"" ;

    foreach my $comp_sent_id ( @_ ) {

        $scen_name .= $self->get_scen_name_by_scen_id( { 'fea_scen.ScenarioID' => $comp_sent_id->{ 'ScenarioID' }, } ) ;
        $scenario_header_in_feature_1 .= $scen_name ;
        $scen_id .= $comp_sent_id->{ 'ScenarioID' } ;

        $scenario_header_in_feature_1 .= $scenario_header_in_feature_2 ;

        #$scenario_header_in_feature_1 .= $double_quote;
        $scenario_header_in_feature_1 .= $scen_id ;

        #$scenario_header_in_feature_1 .= $double_quote;
    } ## end foreach my $comp_sent_id ( ...)

    $scenario_header_in_feature_1 .= "\n" ;

    #return $scen_id;
    return $scenario_header_in_feature_1 ;
} ## end sub set_scenario_header_in_feature

#SCENARIO-WITH-SENTENCE

sub add_complete_scentence_to_scenario {
    my $self = shift ;
    $self->start_time( @{ [ caller( 0 ) ] }[ 3 ], \@_ ) ;
    my $scenario_with_sentence_ids = $_[ 0 ]->{ 'CompleteSentenceIDs' } ;
    my $scenario_id                = $_[ 0 ]->{ 'ScenarioID' } ;
    my $FeatureID                  = $_[ 0 ]->{ 'FeatureID' } ;
    my $order_cnt                  = 0 ;

    unless ( $self->check_input_data_for_add_scentence_to_scenario( $_[ 0 ] ) ) {
        $self->add_error( 'SCENARIO_WITH_SENT' ) ;
        return ;
    } ## end unless ( $self->check_input_data_for_add_scentence_to_scenario...)

    #    $self->update_timestamps( $FeatureID, $scenario_id ) ;

    $self->my_delete(
                      {
                        'from'  => 'Scenario_with_sentence',
                        'where' => {
                                     "ScenarioID" => $_[ 0 ]->{ 'ScenarioID' },
                                   },
                      }
                    ) ;

    foreach my $scenario_with_sentence_id ( @{ $scenario_with_sentence_ids } ) {

        $self->my_insert(
                          {
                            'insert' => {
                                          "ScenarioID"         => $scenario_id,
                                          "CompleteSentenceID" => $scenario_with_sentence_id,
                                          "Position"           => $order_cnt,
                                        },
                            'table'  => 'Scenario_with_sentence',
                            'select' => 'CompleteSentenceID',
                          }
                        ) ;
        $order_cnt++ ;
    } ## end foreach my $scenario_with_sentence_id...
} ## end sub add_complete_scentence_to_scenario

=pod
sub insert_path_to_screenshot{
    my $self          = shift;
    my $sentence_data = shift;
    my $id;
    my $path = "" ;
    my $screenshot_name = $ { ${ [ grep ( defined ${ $_ }, @{ $sentence_data->{ 'items' } } ) ] }[ 0 ] } ;

    $screenshot_name = &throw_double_quote_off( $screenshot_name ) ;
    my $screenshot_number = sprintf("%03d", ${ $sentence_data->{ 'screenshot_number' } } ) ;

    $path = $path_prefix . $featureID . "/refimages/" . $screenshot_number . ".png" ;

    my $screenshot_datas = {
        'FeatureID'       => $featureID       ,
        'ScreenshotName'  => $screenshot_name ,
        'Path'            => $path            ,
        'isValid'         => 0                ,
    };


    $id = $self->my_select({
                    'from'   => "Screenshot"     ,
                    'select' => "ScreenshotID"   ,
                    'where'  => $screenshot_datas,
                    'relation' => 'and'
    }) ;

    unless ( defined $id ){

        $id = $self->my_insert({
           'insert' => $screenshot_datas  ,
           'table'  => "Screenshot"       ,
           'select' => 'ScreenshotID'     ,
        })  ;
        $sentence_data->{ 'ScreenshotID' } = $id ;
    } else {
        $sentence_data->{ 'ScreenshotID' } = $id->[ 0 ]->{ 'ScreenshotID' } ;
    }
    $ { $sentence_data->{ 'screenshot_number' } }++ ;
}
=cut

sub check_input_data_for_add_scentence_to_scenario {
    my $self = shift ;
    if (     $_[ 0 ]->{ 'CompleteSentenceIDs' }
         and $_[ 0 ]->{ 'ScenarioID' } )
    {
        return 1 ;
    } else {
        return 0 ;
    } ## end else [ if ( $_[ 0 ]->{ 'CompleteSentenceIDs'...})]
} ## end sub check_input_data_for_add_scentence_to_scenario

sub get_screenshot_id_by_complete_sentence_id {
    my $self = shift ;
    my $scrshot_id = $self->my_select(
                                       {
                                         'from'   => 'Complete_sentence',
                                         'select' => 'ScreenshotID',
                                         'where'  => {
                                                      "CompleteSentenceID" => $_[ 0 ]->{ 'CompleteSentenceID' },
                                                    }
                                       }
                                     ) ;

    if ( defined $scrshot_id ) {
        if ( scalar @{ $scrshot_id } > 1 ) {
            return $scrshot_id ;
        } else {
            return $scrshot_id->[ 0 ] ;
        } ## end else [ if ( scalar @{ $scrshot_id...})]
    } else {
        return undef ;
    } ## end else [ if ( defined $scrshot_id)]
} ## end sub get_screenshot_id_by_complete_sentence_id

sub getcomm_modeline_id_by_complete_sentence_id {
    my $self = shift ;
    my $scrshot_id = $self->my_select(
                                       {
                                         'from'   => 'Complete_sentence',
                                         'select' => 'CommunicationLineID',
                                         'where'  => {
                                                      "CompleteSentenceID" => $_[ 0 ]->{ 'CompleteSentenceID' },
                                                    }
                                       }
                                     ) ;

    if ( defined $scrshot_id ) {
        if ( scalar @{ $scrshot_id } > 1 ) {
            return $scrshot_id ;
        } else {
            return $scrshot_id->[ 0 ] ;
        } ## end else [ if ( scalar @{ $scrshot_id...})]
    } else {
        return undef ;
    } ## end else [ if ( defined $scrshot_id)]
} ## end sub getcomm_modeline_id_by_complete_sentence_id

sub get_complete_sentence_ids_by_scenarioID {
    my $self = shift ;
    my $result ;
    my $complete_sentence_ids ;
    my $ScreenshotNumber = 0 ;

    foreach my $scenario_ID ( @{ $_[ 0 ]->{ 'Scenario_IDs' } } ) {
        $result = $self->my_select(
                                    {
                                      'from'   => 'Scenario_with_sentence',
                                      'select' => 'CompleteSentenceID',
                                      'where'  => {
                                                   "ScenarioID" => $scenario_ID,
                                                 },
                                      "sort" => "Position",
                                    }
                                  ) ;
        &get_ids_from_Object( $result ) ;
    } ## end foreach my $scenario_ID ( @...)

    foreach my $comp_sent_ID ( @{ $complete_sentence_IDs_array } ) {
        $ScreenshotNumber++ ;
        &get_screenshotID_by_CompleteSentenceID( $comp_sent_ID, $ScreenshotNumber ) ;
    } ## end foreach my $comp_sent_ID ( ...)

    return $complete_sentence_IDs_array ;
} ## end sub get_complete_sentence_ids_by_scenarioID

sub get_ids_from_Object() {
    my $Object = shift ;
    foreach my $comp_sent_id_element ( @{ $Object } ) {
        push @{ $complete_sentence_IDs_array }, $comp_sent_id_element->{ 'CompleteSentenceID' } ;
    } ## end foreach my $comp_sent_id_element...
} ## end sub get_ids_from_Object

#OK
sub get_scenario_with_sentence_datas {
    my $self = shift ;

    my $result = $self->my_select(
                                   {
                                     'from'     => 'Scenario_with_sentence',
                                     'select'   => 'ScenarioID',
                                     'group_by' => 'ScenarioID',
                                   }
                                 ) ;

    if ( !$result ) {
        $self->add_error( 'SCEN_WITH_DATAS' ) ;
    } ## end if ( !$result )
    return $result ;
} ## end sub get_scenario_with_sentence_datas

sub get_gherkintext_by_scen {
    my $self         = shift ;
    my $scenario_str = "" ;
    if ( $self->check_input_data_for_get_gherkintext_by_scen( @_ ) ) {

        my $scenario_with_sentence_by_ids = $self->my_select(
                                                              {
                                                                'from'   => 'Scenario_with_sentence',
                                                                'select' => "CompleteSentenceID",
                                                                'where'  => {
                                                                             "ScenarioID" => $_[ 0 ]->{ 'ScenarioID' }
                                                                           },
                                                                "sort" => "Position",
                                                              }
                                                            ) ;

        foreach my $comp_sent_id ( @{ $scenario_with_sentence_by_ids } ) {
            $scenario_str .=
              $self->get_gherkin_sentence_by_complete_sentence_id(
                                                     {
                                                       'CompleteSentenceID' => $comp_sent_id->{ 'CompleteSentenceID' },
                                                     }
              ) ;
        } ## end foreach my $comp_sent_id ( ...)
        $scenario_str =~ s/(\n)$// ;
        return $scenario_str ;
    } ## end if ( $self->check_input_data_for_get_gherkintext_by_scen...)

} ## end sub get_gherkintext_by_scen

sub check_input_data_for_get_gherkintext_by_scen {
    my $self = shift ;

    if ( $_[ 0 ]->{ 'ScenarioID' } ) {
        return 1 ;
    } else {
        return 0 ;
    } ## end else [ if ( $_[ 0 ]->{ 'ScenarioID'...})]
} ## end sub check_input_data_for_get_gherkintext_by_scen

sub get_sentencelist_by_scen_id {
    my $self = shift ;

    return my $complete_sentence_by_ids = $self->my_select(
        {
           'from'   => 'Scenario_with_sentence AS scen_with_sentence',
           'select' => [
                         'scen_with_sentence.ScenarioID     AS ScenarioID',
                         'scen_with_sentence.Position       AS Complete_sentence_position',
                         'cs.CompleteSentenceID             AS CompleteSentenceID',
                         'gher.GherkinText                  AS Gherkin',
                         'sent.SentenceText                 AS Sentence',
                         'item.ItemName                     AS Item',
                         'scr.ScreenName                    AS Screen',
                         'cs.Value                          AS Value_',
                       ],

           'join' =>
             'JOIN Complete_sentence  AS cs   ON ( scen_with_sentence.CompleteSentenceID = cs.CompleteSentenceID )
                         JOIN Sentence           AS sent ON ( cs.SentenceID = sent.SentenceID )
                         JOIN Gherkin            AS gher ON ( cs.GherkinID  = gher.GherkinID)
                         LEFT JOIN Screen        AS scr  ON ( cs.ScreenID   = scr.ScreenID )
                         LEFT JOIN Item          AS item ON ( cs.ItemID     = item.ItemID )',

           'where' => { "ScenarioID" => $_[ 0 ]->{ 'ScenarioID' }, },
           "sort"  => "Position",
        }
    ) ;
} ## end sub get_sentencelist_by_scen_id

sub get_cmpl_sent_ids_by_scen_id {
    my $self = shift ;

    return my $complete_sentence_by_ids = $self->my_select(
        {
           'from'   => 'Scenario_with_sentence AS scen_with_sentence',
           'select' => [
                         'scen_with_sentence.ScenarioID     AS ScenarioID',
                         'scen_with_sentence.Position       AS Complete_sentence_position',
                         'cs.CompleteSentenceID             AS CompleteSentenceID',
                         'gher.GherkinID                    AS GherkinID',
                         'sent.SentenceID                   AS SentenceID',
                         'item.ItemID                       AS ItemID',
                         'scr.ScreenID                      AS ScreenID',
                         'cs.Value                          AS Value',
                       ],

           'join' =>
             'JOIN Complete_sentence  AS cs      ON ( scen_with_sentence.CompleteSentenceID = cs.CompleteSentenceID )
                         JOIN Sentence           AS sent    ON ( cs.SentenceID = sent.SentenceID )
                         JOIN Gherkin            AS gher    ON ( cs.GherkinID  = gher.GherkinID)
                         LEFT JOIN Screen        AS scr     ON ( cs.ScreenID   = scr.ScreenID )
                         LEFT JOIN Item          AS item    ON ( cs.ItemID     = item.ItemID )',

           'where' => { "ScenarioID" => $_[ 0 ]->{ 'ScenarioID' }, },
           "sort"  => "Position",
        }
    ) ;
} ## end sub get_cmpl_sent_ids_by_scen_id

#COMPLETE SENTENCE
sub throw_double_quote_off {
    my $actual_value = shift ;
    if ( $actual_value =~ /\"(.*?)\"/ ) {
        $actual_value = $1 ;
    } ## end if ( $actual_value =~ ...)
    return $actual_value ;
} ## end sub throw_double_quote_off

sub add_ids_for_complete_sentence_table {
    my $self                   = shift ;
    my $complete_sent_from_web = $_[ 0 ]->{ 'complete_sentencea' } ;
    my $FeatureID              = $_[ 0 ]->{ 'FeatureID' } ;
    my $ScenarioID             = $_[ 0 ]->{ 'ScenarioID' } ;
    my $sentence_datas ;
    my $screenshot_sent_id = $self->get_screenshot_sent_id() ;

    $self->start_time( @{ [ caller( 0 ) ] }[ 3 ], $complete_sent_from_web ) ;

    #    $self->update_timestamps( $FeatureID, $ScenarioID ) ;

    while ( my ( $sent_item_key, $sent_item_val ) = each %{ $complete_sent_from_web } ) {

        if ( defined $sent_item_val->{ 'id' } ) {
            $sentence_datas->{ $sent_item_key } = $sent_item_val->{ 'id' } ;

        } elsif ( $sent_item_val->{ 'data' } && ( $sent_item_val->{ 'pattern' } ne 'VALUE' ) ) {

            $self->start_time( @{ [ caller( 0 ) ] }[ 3 ], $sent_item_val->{ 'data' } ) ;
            $self->start_time( @{ [ caller( 0 ) ] }[ 3 ], $sent_item_key ) ;
            $self->start_time( @{ [ caller( 0 ) ] }[ 3 ], $ITEM_TYPE_TO_TABLE->{ $sent_item_key } ) ;

            $sentence_datas->{ $sent_item_key } =
              $self->add_item_to_table( $ITEM_TYPE_TO_TABLE->{ $sent_item_key },
                                        $sent_item_val->{ 'data' },
                                        $sent_item_key ) ;
        } elsif ( defined $sent_item_val->{ 'data' } && ( $sent_item_val->{ 'pattern' } eq 'VALUE' ) ) {
            $sentence_datas->{ 'Value' } = $sent_item_val->{ 'data' } ;
        } ## end elsif ( defined $sent_item_val...)

    } ## end while ( my ( $sent_item_key...))

    return $self->_add_ids_for_complete_sentence_table( $sentence_datas ) ;
} ## end sub add_ids_for_complete_sentence_table

#OK
sub get_Coordinates_and_RegionType_by_ScreenshotID {
    my $self = shift ;

    my $Coordinates = $self->my_select(
        {
           'from'   => 'RegionOnScreenstate AS region_on_scrst',
           'select' => [
                         'region.RegionTypeID AS type',
                         'region.RegionName   AS RegionName',
                         'pos.X AS x',
                         'pos.Y AS y',
                         'pos.Height AS height',
                         'pos.Width AS width',
                       ],

           'join' => 'LEFT JOIN Region AS region ON ( region.RegionID = region_on_scrst.RegionID )
                         LEFT JOIN Positions AS pos ON ( region.PositionID = pos.PositionID )
                         JOIN Screenstate AS scr_st ON ( scr_st.ScreenstateID = region_on_scrst.ScreenstateID )
                         JOIN Screenshot AS scr_shot ON ( scr_st.ScreenstateID = scr_shot.ScreenstateID )
                         JOIN Feature AS fea ON ( fea.FeatureID = scr_shot.FeatureID )',

           'where' => { "ScreenshotID" => $_[ 0 ]->{ 'ScreenshotID' }, },
        }
    ) ;

    $self->start_time( @{ [ caller( 0 ) ] }[ 3 ], $Coordinates ) ;

    foreach my $Coordinate ( @{ $Coordinates } ) {
        $Coordinate->{ 'type' } = ( $Coordinate->{ 'type' } eq 1 ? "included" : "excluded" ) ;
    } ## end foreach my $Coordinate ( @{...})

    return $Coordinates ;
} ## end sub get_Coordinates_and_RegionType_by_ScreenshotID

#OK
sub get_ButtonCoordinates_by_ScreenID {
    my $self = shift ;

    my $Coordinates = $self->my_select(
        {
           'from'   => 'Item AS item',
           'select' => [
                         'item.ItemName AS RegionName',
                         'pos.X AS x',
                         'pos.Y AS y',
                         'pos.Height AS height',
                         'pos.Width AS width',
                       ],

           'join' => 'RIGHT JOIN ItemOnScreen AS item_on_scr ON ( item.ItemID = item_on_scr.ItemID )
                         LEFT JOIN Positions AS pos ON ( item_on_scr.PositionID = pos.PositionID )',

           'where' => { "ScreenID" => $_[ 0 ]->{ 'ScreenID' }, },
        }
    ) ;

    $self->start_time( @{ [ caller( 0 ) ] }[ 3 ], $Coordinates ) ;

    foreach my $Coordinate ( @{ $Coordinates } ) {
        $Coordinate->{ 'type' } = "included" ;
    } ## end foreach my $Coordinate ( @{...})

    return $Coordinates ;
} ## end sub get_ButtonCoordinates_by_ScreenID

#OK
sub Scenario_is_locked {
    my $self = shift ;
    $self->start_time( @{ [ caller( 0 ) ] }[ 3 ], \@_ ) ;

    $self->update_timestamp_in_scenario( $_[ 0 ]->{ 'ScenarioID' } ) ;

    my $result = $self->my_update(
                                   {
                                     'update' => { 'Locked' => "1" },
                                     'where'  => {
                                                  'ScenarioID' => $_[ 0 ]->{ 'ScenarioID' }
                                                },
                                     'table' => 'Scenario',
                                   }
                                 ) ;
    $self->delete_expired_locks_in_feature() ;
    $self->delete_expired_locks_in_scenario() ;
    return $result ;
} ## end sub Scenario_is_locked

#OK
sub Scenario_is_unlocked {
    my $self = shift ;
    $self->start_time( @{ [ caller( 0 ) ] }[ 3 ], \@_ ) ;
    my $result = $self->my_update(
                                   {
                                     'update' => { 'Locked' => "0" },
                                     'where'  => {
                                                  'ScenarioID' => $_[ 0 ]->{ 'ScenarioID' }
                                                },
                                     'table' => 'Scenario',
                                   }
                                 ) ;
    $self->delete_expired_locks_in_feature() ;
    $self->delete_expired_locks_in_scenario() ;
    return $result ;
} ## end sub Scenario_is_unlocked

sub add_new_button {
    my $self = shift ;
    my $ItemOnScreenDatas ;

    $self->start_time( @{ [ caller( 0 ) ] }[ 3 ], $_[ 0 ]->{ 'PositionDatas' } ) ;
    $self->start_time( @{ [ caller( 0 ) ] }[ 3 ], $_[ 0 ]->{ 'ScreenID' } ) ;

    #get_ItemOnScreenInfos_from_web
    my $ItemOnScreenInfos =
      $self->add_new_button_position_table( $_[ 0 ]->{ 'PositionDatas' }, $_[ 0 ]->{ 'ScreenID' } ) ;
    $self->start_time( @{ [ caller( 0 ) ] }[ 3 ], $ItemOnScreenInfos ) ;

    #get ItemOnScreenIDs by actual Screen
    my $ItemOnScreenIDs =
      $self->add_Button_and_Coordinate_to_ItemOnScreenTable( $ItemOnScreenInfos, $_[ 0 ]->{ 'ScreenID' } ) ;

    return $ItemOnScreenIDs ;
} ## end sub add_new_button

sub add_Button_and_Coordinate_to_ItemOnScreenTable {
    my $self              = shift ;
    my $ItemOnScreenInfos = shift ;
    my $ScreenID          = shift ;
    my $result ;
    my $ItemOnScreenIDs = shift ;

    $result = $self->my_delete(
                                {
                                  'from'   => 'ItemOnScreen',
                                  'select' => '',
                                  'where'  => {
                                               "ScreenID" => $ScreenID,
                                             },
                                }
                              ) ;

    foreach my $ItemOnScreen_Actual_Screen ( @{ $ItemOnScreenInfos } ) {

        $result = $self->my_select(
                                    {
                                      'from'     => "ItemOnScreen",
                                      'select'   => "ItemID",
                                      'where'    => $ItemOnScreen_Actual_Screen,
                                      'relation' => "and"
                                    }
                                  ) ;

        unless ( defined $result ) {
            $result = $self->my_insert(
                {

                    'insert' => $ItemOnScreen_Actual_Screen,
                    'table'  => 'ItemOnScreen',
                    'select' => 'ItemID',
                }
            ) ;
        } else {
            $result = $result->[ 0 ]->{ 'ItemOnScreenID' } ;
        } ## end else
        push @{ $ItemOnScreenIDs }, $result ;
    } ## end foreach my $ItemOnScreen_Actual_Screen...

    return $ItemOnScreenIDs ;
} ## end sub add_Button_and_Coordinate_to_ItemOnScreenTable

sub add_new_Button_to_ItemTable {
    my $self                     = shift ;
    my $Datas                    = shift ;
    my $ItemName->{ 'ItemName' } = $Datas->{ 'ItemName' } ;
    my $result ;

    $result = $self->my_select(
                                {
                                  'from'     => "Item",
                                  'select'   => "ItemID",
                                  'where'    => $ItemName,
                                  'relation' => "and"
                                }
                              ) ;

    unless ( defined $result ) {
        $result = $self->my_insert(
                                    {
                                      'insert' => $ItemName,
                                      'table'  => 'Item',
                                      'select' => 'ItemID',
                                    }
                                  ) ;
    } else {
        $result = $result->[ 0 ]->{ 'ItemID' } ;
    } ## end else

    return $result ;
} ## end sub add_new_Button_to_ItemTable

sub clear_evening_runnings {
    my $self = shift ;

    $self->my_delete(
                      {
                        'from'   => 'Evening_running',
                        'select' => '',
                      }
                    ) ;
} ## end sub clear_evening_runnings

sub add_evening_running_tests {
    my $self                    = shift ;
    my $Datas                   = shift ;
    my $Test->{ 'FeatureName' } = $Datas->{ 'name' } ;
    $Test->{ 'FeatureID' } = $Datas->{ 'id' } ;
    $Test->{ 'Text' }      = $Datas->{ 'text' } ;
    my $result ;

    $self->start_time( @{ [ caller( 0 ) ] }[ 3 ], $result ) ;

    $result = $self->my_select(
                                {
                                  'from'     => "Evening_running",
                                  'select'   => "Evening_runningID",
                                  'where'    => $Test,
                                  'relation' => "and"
                                }
                              ) ;

    $self->start_time( @{ [ caller( 0 ) ] }[ 3 ], $result ) ;

    unless ( defined $result ) {
        $result = $self->my_insert(
                                    {
                                      'insert' => $Test,
                                      'table'  => 'Evening_running',
                                      'select' => 'Evening_runningID',
                                    }
                                  ) ;
    } else {
        $result = $result->[ 0 ]->{ 'FeatureID' } ;
    } ## end else
    $self->start_time( @{ [ caller( 0 ) ] }[ 3 ], $result ) ;
    return $result ;
} ## end sub add_evening_running_tests

sub add_coordinate_to_PositionTable {
    my $self         = shift ;
    my $positiondata = shift ;
    my $only_pos_dat ;
    my $result ;

    $only_pos_dat->{ "X" }      = $positiondata->{ "x" } ;
    $only_pos_dat->{ "Y" }      = $positiondata->{ "y" } ;
    $only_pos_dat->{ "Height" } = $positiondata->{ "height" } ;
    $only_pos_dat->{ "Width" }  = $positiondata->{ "width" } ;

    $result = $self->my_select(
                                {
                                  'from'     => "Positions",
                                  'select'   => "PositionID",
                                  'where'    => $only_pos_dat,
                                  'relation' => "and"
                                }
                              ) ;

    $self->start_time( @{ [ caller( 0 ) ] }[ 3 ], $only_pos_dat ) ;

    unless ( defined $result ) {
        $result = $self->my_insert(
                                    {
                                      'insert' => $only_pos_dat,
                                      'table'  => 'Positions',
                                      'select' => 'PositionID',
                                    }
                                  ) ;
    } else {
        $result = $result->[ 0 ]->{ 'PositionID' } ;
    } ## end else

    return $result ;
} ## end sub add_coordinate_to_PositionTable

sub add_new_button_position_table {
    my $self      = shift ;
    my $positions = shift ;
    my $ScreenID  = shift ;
    my $result ;
    my $ItemOnScreenInfos ;
    my $ItemID ;
    my $PositionID ;

    foreach my $positiondata ( @{ $positions } ) {

        # get ItemID
        $ItemID = $self->add_new_Button_to_ItemTable( $positiondata ) ;

        #get PositionID
        $PositionID = $self->add_coordinate_to_PositionTable( $positiondata ) ;

        #ItemID and PositionID to ItemOnScreen table
        my $OnButtonInfos ;
        $OnButtonInfos->{ 'ItemID' }     = $ItemID ;
        $OnButtonInfos->{ 'PositionID' } = $PositionID ;
        $OnButtonInfos->{ 'ScreenID' }   = $ScreenID ;

        #All button coordinates and names to selected Screen
        push @{ $ItemOnScreenInfos }, $OnButtonInfos ;
    } ## end foreach my $positiondata ( ...)
    return $ItemOnScreenInfos ;
} ## end sub add_new_button_position_table

#OK
sub add_new_region {
    my $self = shift ;
    my $RegionOnScreenshotDatas ;

    my $RegionOnScreenshotInfos = $self->add_new_region_to_position_table( $_[ 0 ]->{ 'PositionDatas' } ) ;

    my $RegionOnScreenshotID =
      $self->add_Region_to_RegionOnScreenstateTable( $RegionOnScreenshotInfos,, $_[ 0 ]->{ 'Screenshot_infos' } ) ;

    $self->start_time( @{ [ caller( 0 ) ] }[ 3 ], $RegionOnScreenshotID ) ;

    return $RegionOnScreenshotID ;
} ## end sub add_new_region

sub update_multi {
    my $self     = shift ;
    my $RegionID = shift ;
    my $result   = undef ;

    $self->start_time( @{ [ caller( 0 ) ] }[ 3 ], $RegionID ) ;

    $result = $self->my_select(
                                {
                                  'from'   => "Region",
                                  'select' => "Multi",
                                  'where'  => {
                                               "RegionID" => $RegionID
                                             },
                                }
                              ) ;

    unless ( $result->[ 0 ]->{ 'Multi' } == 1 ) {
        $result = $self->my_update(
                                    {
                                      'update' => {
                                                    'Multi' => 1,
                                                  },
                                      'where' => {
                                                   "RegionID" => $RegionID
                                                 },
                                      'table'  => 'Region',
                                      'select' => 'RegionID',
                                    }
                                  ) ;
    } ## end unless ( $result->[ 0 ]->{...})

    $self->start_time( @{ [ caller( 0 ) ] }[ 3 ], $result ) ;

    return $result ;
} ## end sub update_multi

sub add_region_from_DB_to_screenshot {
    my $self   = shift ;
    my $result = undef ;

    #my $update = $self->update_multi( $_[ 0 ]->{ 'region_infos' }->{ 'RegionID' } );

    $result = $self->my_select(
                                {
                                  'from'     => "RegionOnScreenstate",
                                  'select'   => "RegionOnScreenshotID",
                                  'where'    => $_[ 0 ]->{ 'region_infos' },
                                  'relation' => "and"
                                }
                              ) ;

    unless ( defined $result ) {
        $result = $self->my_insert(
                                    {
                                      'insert' => $_[ 0 ]->{ 'region_infos' },
                                      'table'  => 'RegionOnScreenstate',
                                      'select' => 'RegionOnScreenshotID',
                                    }
                                  ) ;
    } else {
        $result = $result->[ 0 ]->{ 'RegionOnScreenshotID' } ;
    } ## end else

    return $result ;
} ## end sub add_region_from_DB_to_screenshot

sub add_item_from_DB_to_screenstate {
    my $self   = shift ;
    my $result = undef ;

    $result = $self->my_select(
                                {
                                  'from'     => "ItemOnScreen",
                                  'select'   => "ItemOnScreenID",
                                  'where'    => $_[ 0 ]->{ 'item_infos' },
                                  'relation' => "and"
                                }
                              ) ;

    unless ( defined $result ) {
        $result = $self->my_insert(
                                    {
                                      'insert' => $_[ 0 ]->{ 'item_infos' },
                                      'table'  => 'ItemOnScreen',
                                      'select' => 'ItemOnScreenID',
                                    }
                                  ) ;
    } else {
        $result = $result->[ 0 ]->{ 'ItemOnScreenID' } ;
    } ## end else

    return $result ;
} ## end sub add_item_from_DB_to_screenstate

#OK
sub add_Region_to_RegionOnScreenstateTable {
    my $self                    = shift ;
    my $RegionOnScreenshotInfos = shift ;
    my $Screenshot_infos        = shift ;

    my $result ;
    my $RegionOnScreenshotDatas ;
    my $RegionOnScreenstateDatas ;
    my $screenstateIDArray ;

    $self->my_delete(
                      {
                        'from'   => 'RegionOnScreenstate',
                        'select' => '',
                        'where'  => {
                                     "ScreenstateID" => $Screenshot_infos->{ 'ScreenstateID' },
                                   },
                      }
                    ) ;

    foreach my $OneRegion ( @{ $RegionOnScreenshotInfos } ) {
        $RegionOnScreenstateDatas = {
                                      'RegionID'      => $OneRegion->{ 'RegionID' },
                                      'ScreenstateID' => $Screenshot_infos->{ 'ScreenstateID' },
                                    } ;

        $result = $self->my_select(
                                    {
                                      'from'     => "RegionOnScreenstate",
                                      'select'   => "RegionID",
                                      'where'    => $RegionOnScreenstateDatas,
                                      'relation' => "and"
                                    }
                                  ) ;

        if ( $OneRegion->{ 'operation' } eq SINGLE ) {
            unless ( defined $result ) {
                $result = $self->my_insert(
                    {

                        'insert' => $RegionOnScreenstateDatas,
                        'table'  => 'RegionOnScreenstate',
                        'select' => 'RegionID',
                    }
                ) ;
            } else {
                $result = $result->[ 0 ]->{ 'RegionOnScreenshotID' } ;
            } ## end else

        } elsif ( $OneRegion->{ 'operation' } eq 'all' ) {
            my $proba = "proba" ;

            $self->start_time( @{ [ caller( 0 ) ] }[ 3 ], $proba ) ;

            $screenstateIDArray = $self->get_screenstateIDs_by_FeatureID( $Screenshot_infos->{ 'FeatureID' } ) ;

            $self->start_time( @{ [ caller( 0 ) ] }[ 3 ], $screenstateIDArray ) ;

            foreach my $screenstateID ( @{ $screenstateIDArray } ) {

                $RegionOnScreenstateDatas = {
                                              'RegionID'      => $OneRegion->{ 'RegionID' },
                                              'ScreenstateID' => $screenstateID->{ 'ScreenstateID' },
                                            } ;

                $result = $self->my_select(
                                            {
                                              'from'     => "RegionOnScreenstate",
                                              'select'   => "RegionID",
                                              'where'    => $RegionOnScreenstateDatas,
                                              'relation' => "and"
                                            }
                                          ) ;

                unless ( defined $result ) {
                    $result = $self->my_insert(
                                                {
                                                  'insert' => $RegionOnScreenstateDatas,
                                                  'table'  => 'RegionOnScreenstate',
                                                  'select' => 'RegionID',
                                                }
                                              ) ;
                } else {
                    $result = $result->[ 0 ]->{ 'RegionOnScreenshotID' } ;
                } ## end else
            } ## end foreach my $screenstateID (...)
        } ## end elsif ( $OneRegion->{ 'operation'...})
    } ## end foreach my $OneRegion ( @{ ...})

    return $result ;
} ## end sub add_Region_to_RegionOnScreenstateTable

sub get_screenstateIDs_by_FeatureID {
    my $self   = shift ;
    my $fea_id = shift ;
    my $result ;

    $self->start_time( @{ [ caller( 0 ) ] }[ 3 ], $fea_id ) ;

    $result = $self->my_select(
        {
           'from'   => 'Screenshot AS screenshot',
           'select' => [ 'screenstate.ScreenstateID AS ScreenstateID', ],

           'join' => 'JOIN Screenstate AS screenstate ON ( screenshot.ScreenstateID = screenstate.ScreenstateID )',

           'where' => { "screenshot.FeatureID " => $fea_id },
        }
    ) ;

    if ( !$result ) {
        $self->add_error( 'SCREENSHOT_BY_FEA' ) ;
    } ## end if ( !$result )

    $self->start_time( @{ [ caller( 0 ) ] }[ 3 ], $result ) ;

    return $result ;
} ## end sub get_screenstateIDs_by_FeatureID

sub add_new_region_to_position_table {
    my $self      = shift ;
    my $positions = shift ;
    my $result ;
    my %only_pos_data = () ;
    my ( $key, $value ) ;
    my $regionID ;
    my $only_pos_dat ;
    my $RegionOnScreenshotInfos ;

    foreach my $positiondata ( @{ $positions } ) {

        $only_pos_dat->{ "X" }      = $positiondata->{ "X" } ;
        $only_pos_dat->{ "Y" }      = $positiondata->{ "Y" } ;
        $only_pos_dat->{ "Height" } = $positiondata->{ "Height" } ;
        $only_pos_dat->{ "Width" }  = $positiondata->{ "Width" } ;

        $result = $self->my_select(
                                    {
                                      'from'     => "Positions",
                                      'select'   => "PositionID",
                                      'where'    => $only_pos_dat,
                                      'relation' => "and"
                                    }
                                  ) ;

        unless ( defined $result ) {
            $result = $self->my_insert(
                                        {
                                          'insert' => $only_pos_dat,
                                          'table'  => 'Positions',
                                          'select' => 'PositionID',
                                        }
                                      ) ;
        } else {
            $result = $result->[ 0 ]->{ 'PositionID' } ;
        } ## end else

        $positiondata->{ 'Type' } = ( $positiondata->{ 'Type' } eq "excluded" ? 1 : 2 ) ;
        $positiondata->{ 'PositionID' } = $result ;

        $self->start_time( @{ [ caller( 0 ) ] }[ 3 ], $positiondata ) ;

        $regionID = $self->add_new_region_to_RegionTable( $positiondata ) ;

        #nullazashoz, biztos nem igy kell, megkerdezni
        my $OneRegionInfos ;
        $OneRegionInfos->{ 'operation' } = $positiondata->{ "operation" } ;
        $OneRegionInfos->{ 'RegionID' }  = $regionID ;

        push @{ $RegionOnScreenshotInfos }, $OneRegionInfos ;
    } ## end foreach my $positiondata ( ...)

    return $RegionOnScreenshotInfos ;
} ## end sub add_new_region_to_position_table

#OK
sub add_new_region_to_RegionTable {
    my $self        = shift ;
    my $RegionDatas = shift ;
    my $result ;

    $self->start_time( @{ [ caller( 0 ) ] }[ 3 ], $result ) ;
    $self->start_time( @{ [ caller( 0 ) ] }[ 3 ], $RegionDatas ) ;

    $result = $self->my_select(
                                {
                                  'from'   => "Region",
                                  'select' => "RegionID",
                                  'where'  => {
                                               'RegionTypeID' => $RegionDatas->{ 'Type' },
                                               'RegionName'   => $RegionDatas->{ 'RegionName' },
                                             },
                                  'relation' => "and"
                                }
                              ) ;

    unless ( defined $result ) {
        $result = $self->my_insert(
                                    {
                                      'insert' => {
                                                    'RegionTypeID' => $RegionDatas->{ 'Type' },
                                                    'PositionID'   => $RegionDatas->{ 'PositionID' },
                                                    'RegionName'   => $RegionDatas->{ 'RegionName' },
                                                    'Multi' => ( $RegionDatas->{ 'operation' } eq SINGLE ? 0 : 1 )
                                                  },
                                      'table'  => 'Region',
                                      'select' => 'RegionID',
                                    }
                                  ) ;
    } else {
        $self->my_update(
            {
               'update' => {

                   #'Multi'        => ( $RegionDatas->{ 'operation' } eq SINGLE ? 0 : 1 ),
                   'PositionID' => $RegionDatas->{ 'PositionID' },
               },
               'where' => {
                            'RegionName' => $RegionDatas->{ 'RegionName' },
                          },
               'table'  => 'Region',
               'select' => 'RegionID',
            }
        ) ;

        $self->my_update(
                          {
                            'update' => {
                                          'Multi' => ( $RegionDatas->{ 'operation' } eq SINGLE ? 0 : 1 ),
                                        },
                            'where' => {
                                         'RegionName' => $RegionDatas->{ 'RegionName' },
                                       },
                            'table'  => 'Region',
                            'select' => 'RegionID',
                          }
                        ) ;

        $result = $result->[ 0 ]->{ 'RegionID' } ;
    } ## end else

    return $result ;
} ## end sub add_new_region_to_RegionTable

#OK
sub add_item_to_table {
    my $self        = shift ;
    my $table_datas = shift ;
    my $data        = shift ;
    my $item_type   = shift ;

    my $where_param ;
    my $res ;

    $self->start_time( @{ [ caller( 0 ) ] }[ 3 ], $table_datas ) ;

    if ( defined $table_datas ) {
        my $table       = $table_datas->{ 'table' } ;
        my $row_name    = $table_datas->{ 'name' } ;
        my $row_id      = $table_datas->{ 'id' } ;
        my $id_on_c_s_t = $table_datas->{ 'id_on_c_s_t' } ;

        $where_param->{ $row_name } = $data ;

        if ( $item_type eq $scroll_name ) {
            $where_param->{ 'ItemTypeID' } = 2 ;
        } elsif ( $item_type eq $item_name ) {
            $where_param->{ 'ItemTypeID' } = 1 ;
        } ## end elsif ( $item_type eq $item_name)

        $res = $self->my_insert(
                                 {
                                   'insert' => $where_param,
                                   'table'  => $table,
                                   'select' => $row_id,
                                 }
                               ) ;
    } else {
        $res = $data ;
    } ## end else [ if ( defined $table_datas)]

    return $res ;
} ## end sub add_item_to_table

sub insert_path_to_screenshot {
    my $self = shift ;
    $self->start_time( @{ [ caller( 0 ) ] }[ 3 ], \@_ ) ;
    my $id ;
    my $screenshot_name = shift ;
    my $featureID       = shift ;

    my $screenshot_datas = {
                             'ScreenshotName' => $screenshot_name,
                             'isValid'        => 0,
                           } ;
    $screenshot_datas->{ 'FeatureID' } = $featureID if $featureID ;

    $self->start_time( @{ [ caller( 0 ) ] }[ 3 ], $screenshot_datas ) ;
    $id = $self->my_select(
                            {
                              'from'     => "Screenshot",
                              'select'   => "ScreenshotID",
                              'where'    => $screenshot_datas,
                              'relation' => 'and'
                            }
                          ) ;

    unless ( defined $id ) {

        $id = $self->my_insert(
                                {
                                  'insert' => $screenshot_datas,
                                  'table'  => "Screenshot",
                                  'select' => 'ScreenshotID',
                                }
                              ) ;
        return $id ;
    } else {
        return $id->[ 0 ]->{ 'ScreenshotID' } ;
    } ## end else
} ## end sub insert_path_to_screenshot

sub get_screenshot_sent_id {
    my $screenshot_name = "SCREENSHOT_NAME" ;
    my $sentences       = $_[ 0 ]->get_sentences() ;
    $_[ 0 ]->start_time( @{ [ caller( 0 ) ] }[ 3 ], $sentences ) ;
    return @{ [ grep ( $_->{ 'label' } =~ /$screenshot_name/, @{ $sentences } ) ] }[ 0 ]->{ 'value' } ;
} ## end sub get_screenshot_sent_id

#PARSE_FEATURE_FILE_TO_DB-BOL ATHUZVA
sub _add_ids_for_complete_sentence_table {
    my $self                 = shift ;
    my $cmplete_sentence_ids = shift ;

    $self->start_time( @{ [ caller( 0 ) ] }[ 3 ], $cmplete_sentence_ids ) ;

    my $id ;
    if ( $cmplete_sentence_ids ) {
        $id = $self->my_select(
                                {
                                  'from'     => "Complete_sentence",
                                  'select'   => "CompleteSentenceID",
                                  'where'    => $cmplete_sentence_ids,
                                  "relation" => "and"
                                }
                              ) ;

        unless ( defined $id ) {
            my $complete_sentence = $self->my_insert(
                                                      {
                                                        'insert' => $cmplete_sentence_ids,
                                                        'table'  => 'Complete_sentence',
                                                        'select' => 'CompleteSentenceID',
                                                      }
                                                    ) ;
            return $complete_sentence ;
        } else {
            return $id->[ 0 ]->{ 'CompleteSentenceID' } ;
        } ## end else
    } ## end if ( $cmplete_sentence_ids)
} ## end sub _add_ids_for_complete_sentence_table

#OK
sub get_gherkin_sentence_by_complete_sentence_id {
    my $self = shift ;

    my $item_name          = "ITEM_NAME" ;
    my $screen_name        = "SCREEN_NAME" ;
    my $scroll_name        = "SCROLLBAR_NAME" ;
    my $screenshot_name    = "SCREENSHOT_NAME" ;
    my $comunication_line  = "COMMUNICATIONLINE" ;
    my $gherkin            = "GHERKIN" ;
    my $sentence           = "SENTENCE" ;
    my $screenshot_sent_id = 0 ;
    my $path_prefix        = "feature_" ;
    my $gherkin_words ;
    my $str ;
    my $ITEM_TYPE_TO_TABLE = {
                               $item_name => {
                                               'table'       => 'Item',
                                               'id'          => 'ItemID',
                                               'name'        => 'ItemName',
                                               'id_in_c_s_t' => 'ItemID',
                                             },
                               $scroll_name => {
                                                 'table'       => 'Item',
                                                 'id'          => 'ItemID',
                                                 'name'        => 'ItemName',
                                                 'id_in_c_s_t' => 'ScrollbarID',
                                               },
                               $screen_name => {
                                                 'table'       => 'Screen',
                                                 'id'          => 'ScreenID',
                                                 'name'        => 'ScreenName',
                                                 'id_in_c_s_t' => 'ScreenID',
                                               },
                               $comunication_line => {
                                                       'table'       => 'CommunicationLine',
                                                       'id'          => 'CommunicationLineID',
                                                       'name'        => 'CommunicationLineText',
                                                       'id_in_c_s_t' => 'CommunicationLineID',
                                                     },
                               $screenshot_name => {
                                                     'table'       => 'Screenstate',
                                                     'id'          => 'ScreenstateID',
                                                     'name'        => 'ScreenStateName',
                                                     'id_in_c_s_t' => 'ScreenstateID',
                                                   },
                               $gherkin => {
                                             'table'       => 'Gherkin',
                                             'id'          => 'GherkinID',
                                             'name'        => 'GherkinText',
                                             'id_in_c_s_t' => 'GherkinID',
                                           },
                               $sentence => {
                                              'table'       => 'Sentence',
                                              'id'          => 'SentenceID',
                                              'name'        => 'SentenceText',
                                              'id_in_c_s_t' => 'SentenceID',
                                            }
                             } ;

    my $gherkin_sentence = "" ;

    my $complete_sentence_by_ids = $self->my_select(
                                                     {
                                                       'from'   => 'Complete_sentence',
                                                       'select' => "ALL",
                                                       'where'  => {
                                                              "CompleteSentenceID" => $_[ 0 ]->{ 'CompleteSentenceID' },
                                                       },
                                                     }
                                                   ) ;

    $complete_sentence_by_ids = $complete_sentence_by_ids->[ 0 ] ;

    while ( my ( $key, $value ) = each %{ $ITEM_TYPE_TO_TABLE } ) {
        if ( defined $complete_sentence_by_ids->{ $value->{ 'id' } } ) {
            $value->{ 'data' } = $self->get_name_from_table( $value->{ 'table' },
                                                            $value->{ 'id' },
                                                            $value->{ 'name' },
                                                            $complete_sentence_by_ids->{ $value->{ 'id_in_c_s_t' } } ) ;
            $value->{ 'data' } = $value->{ 'data' }->{ $value->{ 'name' } } if $value->{ 'data' } ;
        } ## end if ( defined $complete_sentence_by_ids...)
    } ## end while ( my ( $key, $value...))

    my $num_of_spaces = length( "given" ) + 1 - length( $ITEM_TYPE_TO_TABLE->{ $gherkin }->{ 'data' } ) ;
    $gherkin_sentence = "    " . $ITEM_TYPE_TO_TABLE->{ $gherkin }->{ 'data' } ;
    $gherkin_sentence .= " " x ( $num_of_spaces ) ;
    $gherkin_sentence .= $ITEM_TYPE_TO_TABLE->{ $sentence }->{ 'data' } ;
    my $dquoted ;

    while ( my ( $key, $value ) = each %{ $ITEM_TYPE_TO_TABLE } ) {
        if ( defined $value->{ 'data' } ) {
            $dquoted = '"' . $value->{ 'data' } . '"' ;
            $gherkin_sentence =~ s/$key/$dquoted/ ;
        } ## end if ( defined $value->{...})
    } ## end while ( my ( $key, $value...))

    my $VALUE_with_dqoute = '"' . "VALUE" . '"' ;
    $self->start_time( @{ [ caller( 0 ) ] }[ 3 ], $gherkin_sentence ) ;
    $gherkin_sentence =~ s/VALUE/$VALUE_with_dqoute/ ;
    $self->start_time( @{ [ caller( 0 ) ] }[ 3 ], $gherkin_sentence ) ;
    $gherkin_sentence =~ s/VALUE/$complete_sentence_by_ids->{ 'Value' }/ ;
    $self->start_time( @{ [ caller( 0 ) ] }[ 3 ], $complete_sentence_by_ids->{ 'Value' } ) ;
    $self->start_time( @{ [ caller( 0 ) ] }[ 3 ], $gherkin_sentence ) ;

    return $gherkin_sentence . "\n" ;

} ## end sub get_gherkin_sentence_by_complete_sentence_id

#OK
sub get_name_from_table {
    my $self     = shift ;
    my $table    = shift ;
    my $id       = shift ;
    my $row_name = shift ;
    my $value    = shift ;
    my $new_id   = undef ;

    return undef unless $value ;

    my $res = $self->my_select(
                                {
                                  'from'   => $table,
                                  'select' => $row_name,
                                  'where'  => {
                                               $id => $value,
                                             },
                                }
                              ) ;

    if ( defined $res ) {
        return $res->[ 0 ] ;
    } else {
        return undef ;
    } ## end else [ if ( defined $res ) ]
} ## end sub get_name_from_table

sub set_double_qoute {
    my $self = shift ;

    my $with_double_quote = "\"" ;
    $with_double_quote .= $self ;
    $with_double_quote .= "\"" ;

    return $with_double_quote ;
} ## end sub set_double_qoute

sub add_complete_sentence_with_item_id {

    my $self = shift ;
    my $scollbar_id_exist ;

    my $sentence_id = $_[ 0 ]->{ 'SentenceID' } ;

    #print Dumper $sentence_id;

    my $complete_sentence_by_ids = $self->my_select(
        {
           'from'   => 'Complete_sentence AS cs',
           'select' => [
                         'cs.CompleteSentenceID AS CompleteSentenceID',
                         'sent.SentenceText AS Sentence',
                         'gher.GherkinText  AS Gherkin',
                         'scr.ScreenName    AS Screen',
                       ],

           'join' => 'JOIN Sentence      AS sent ON ( cs.SentenceID = sent.SentenceID )
                         JOIN Gherkin       AS gher ON ( cs.GherkinID  = gher.GherkinID)
                         LEFT JOIN Screen   AS scr  ON ( cs.ScreenID   = scr.ScreenID )
                         LEFT JOIN Item     AS item ON ( cs.ItemID     = item.ItemID )',
        }
    ) ;

    #$complete_sentence_by_ids = $complete_sentence_by_ids->[ 0 ] ;
    #print Dumper $complete_sentence_by_ids ;
    #print Dumper $complete_sentence_by_ids ->{ 'ScrollbarID'} ;

    my $complete_sentence = $self->my_insert(
                                              {
                                                'insert' => {
                                                              'GherkinID'  => $_[ 0 ]->{ 'GherkinID' },
                                                              'SentenceID' => $_[ 0 ]->{ 'SentenceID' },
                                                              'ItemID'     => $_[ 0 ]->{ 'ItemID' },
                                                            },
                                                'table'  => 'Complete_sentence',
                                                'select' => 'CompleteSentenceID',
                                              }
                                            ) ;
} ## end sub add_complete_sentence_with_item_id

sub add_complete_sentence_with_item_id_and_value {

    my $self = shift ;
    my $scollbar_id_exist ;

    my $sentence_id = $_[ 0 ]->{ 'SentenceID' } ;

    #print Dumper $sentence_id;

    my $complete_sentence_by_ids = $self->my_select(
        {
           'from'   => 'Complete_sentence AS cs',
           'select' => [
                         'cs.CompleteSentenceID AS CompleteSentenceID',
                         'sent.SentenceText AS Sentence',
                         'gher.GherkinText  AS Gherkin',
                         'scr.ScreenName    AS Screen',
                       ],

           'join' => 'JOIN Sentence      AS sent ON ( cs.SentenceID = sent.SentenceID )
                         JOIN Gherkin       AS gher ON ( cs.GherkinID  = gher.GherkinID)
                         LEFT JOIN Screen   AS scr  ON ( cs.ScreenID   = scr.ScreenID )
                         LEFT JOIN Item     AS item ON ( cs.ItemID     = item.ItemID )',
        }
    ) ;

    #$complete_sentence_by_ids = $complete_sentence_by_ids->[ 0 ] ;
    #print Dumper $complete_sentence_by_ids ;
    #print Dumper $complete_sentence_by_ids ->{ 'ScrollbarID'} ;

    my $complete_sentence = $self->my_insert(
                                              {
                                                'insert' => {
                                                              'GherkinID'  => $_[ 0 ]->{ 'GherkinID' },
                                                              'SentenceID' => $_[ 0 ]->{ 'SentenceID' },
                                                              'ItemID'     => $_[ 0 ]->{ 'ItemID' },
                                                              'Value'      => $_[ 0 ]->{ 'Value' },
                                                            },
                                                'table'  => 'Complete_sentence',
                                                'select' => 'CompleteSentenceID',
                                              }
                                            ) ;
} ## end sub add_complete_sentence_with_item_id_and_value

sub update_item_id_and_value_in_complete_sentence_table {
    my $self = shift ;
    my $result->{ 'VERDICT' } = 1 ;

    $result->{ 'VERDICT' } = $self->my_update(
                                               {
                                                 'update' => {
                                                               "Value" => $_[ 0 ]->{ 'Value' },
                                                             },
                                                 "relation" => "and",
                                                 'where'    => {
                                                              'CompleteSentenceID' => $_[ 0 ]->{ 'CompleteSentenceID' }
                                                            },
                                                 'table'  => 'Complete_sentence',
                                                 'select' => 'CompleteSentenceID',
                                               }
                                             ) ;

    $result->{ 'VERDICT' } = $self->my_update(
                                               {
                                                 'update' => {
                                                               "ItemID" => $_[ 0 ]->{ 'ItemID' },
                                                             },
                                                 "relation" => "and",
                                                 'where'    => {
                                                              'CompleteSentenceID' => $_[ 0 ]->{ 'CompleteSentenceID' }
                                                            },
                                                 'table'  => 'Complete_sentence',
                                                 'select' => 'CompleteSentenceID',
                                               }
                                             ) ;

    return $result ;
} ## end sub update_item_id_and_value_in_complete_sentence_table

sub update_screen_id_in_complete_sentence_table {
    my $self = shift ;
    my $result->{ 'VERDICT' } = 1 ;

    $result->{ 'VERDICT' } = $self->my_update(
                                               {
                                                 'update' => { 'ScreenID' => $_[ 0 ]->{ 'ScreenID' } },
                                                 'where'  => {
                                                              'CompleteSentenceID' => $_[ 0 ]->{ 'CompleteSentenceID' }
                                                            },
                                                 'table'  => 'Complete_sentence',
                                                 'select' => 'CompleteSentenceID',
                                               }
                                             ) ;

    return $result ;
} ## end sub update_screen_id_in_complete_sentence_table

sub update_comm_line_id_in_complete_sentence_table {
    my $self = shift ;
    my $result->{ 'VERDICT' } = 1 ;

    $result->{ 'VERDICT' } = $self->my_update(
                                         {
                                           'update' => { 'CommunicationLineID' => $_[ 0 ]->{ 'CommunicationLineID' } },
                                           'where'  => {
                                                        'CompleteSentenceID' => $_[ 0 ]->{ 'CompleteSentenceID' }
                                                      },
                                           'table'  => 'Complete_sentence',
                                           'select' => 'CompleteSentenceID',
                                         }
    ) ;

    return $result ;
} ## end sub update_comm_line_id_in_complete_sentence_table

sub update_item_id_in_complete_sentence_table {
    my $self = shift ;
    my $result->{ 'VERDICT' } = 1 ;

    $result->{ 'VERDICT' } = $self->my_update(
                                               {
                                                 'update' => { 'ItemID' => $_[ 0 ]->{ 'ItemID' } },
                                                 'where'  => {
                                                              'CompleteSentenceID' => $_[ 0 ]->{ 'CompleteSentenceID' }
                                                            },
                                                 'table'  => 'Complete_sentence',
                                                 'select' => 'CompleteSentenceID',
                                               }
                                             ) ;

    return $result ;
} ## end sub update_item_id_in_complete_sentence_table

sub add_complete_sentence_with_screen_id {

    my $self = shift ;
    my $scollbar_id_exist ;

    my $sentence_id = $_[ 0 ]->{ 'SentenceID' } ;

    #print Dumper $sentence_id;

    my $complete_sentence_by_ids = $self->my_select(
        {
           'from'   => 'Complete_sentence AS cs',
           'select' => [
                         'cs.CompleteSentenceID AS CompleteSentenceID',
                         'sent.SentenceText AS Sentence',
                         'gher.GherkinText  AS Gherkin',
                         'scr.ScreenName    AS Screen',
                       ],

           'join' => 'JOIN Sentence      AS sent ON ( cs.SentenceID = sent.SentenceID )
                         JOIN Gherkin       AS gher ON ( cs.GherkinID  = gher.GherkinID)
                         LEFT JOIN Screen   AS scr  ON ( cs.ScreenID   = scr.ScreenID )',
        }
    ) ;

    $complete_sentence_by_ids = $complete_sentence_by_ids->[ 0 ] ;

    #print Dumper $complete_sentence_by_ids ;

    return
      my $complete_sentence = $self->my_insert(
                                                {
                                                  'insert' => {
                                                                'GherkinID'  => $_[ 0 ]->{ 'GherkinID' },
                                                                'SentenceID' => $_[ 0 ]->{ 'SentenceID' },
                                                                'ScreenID'   => $_[ 0 ]->{ 'ScreenID' },
                                                              },
                                                  'table'  => 'Complete_sentence',
                                                  'select' => 'CompleteSentenceID',
                                                }
                                              ) ;
} ## end sub add_complete_sentence_with_screen_id

sub add_complete_sentence__with_comm_line {

    my $self = shift ;
    my $scollbar_id_exist ;

    my $sentence_id = $_[ 0 ]->{ 'SentenceID' } ;
    my $complete_sentence_by_ids = $self->my_select(
        {
           'from'   => 'Complete_sentence AS cs',
           'select' => [
                         'cs.CompleteSentenceID AS CompleteSentenceID',
                         'sent.SentenceText                  AS Sentence',
                         'gher.GherkinText                   AS Gherkin',
                         'comm_mode.CommunicationLineText    AS Screen',
                       ],

           'join' => 'JOIN Sentence                 AS sent       ON ( cs.SentenceID            = sent.SentenceID )
                        JOIN Gherkin                  AS gher       ON ( cs.GherkinID             = gher.GherkinID)
                        LEFT JOIN CommunicationLine   AS comm_mode  ON ( cs.CommunicationLineID   = comm_mode.CommunicationLineID )',
        }
    ) ;

    $complete_sentence_by_ids = $complete_sentence_by_ids->[ 0 ] ;

    return
      my $complete_sentence = $self->my_insert(
                                                {
                                                  'insert' => {
                                                            'GherkinID'           => $_[ 0 ]->{ 'GherkinID' },
                                                            'SentenceID'          => $_[ 0 ]->{ 'SentenceID' },
                                                            'CommunicationLineID' => $_[ 0 ]->{ 'CommunicationLineID' },
                                                  },
                                                  'table'  => 'Complete_sentence',
                                                  'select' => 'CompleteSentenceID',
                                                }
                                              ) ;
} ## end sub add_complete_sentence__with_comm_line

sub add_complete_sentence_with_screenshot_id {

    my $self = shift ;
    my $scollbar_id_exist ;

    my $sentence_id = $_[ 0 ]->{ 'SentenceID' } ;

    #print Dumper $sentence_id;

    my $complete_sentence_by_ids = $self->my_select(
        {
           'from'   => 'Complete_sentence AS cs',
           'select' => [
                         'cs.CompleteSentenceID AS CompleteSentenceID',
                         'sent.SentenceText     AS Sentence',
                         'gher.GherkinText      AS Gherkin',
                         'scr.ScreenshotName    AS Screenshot',
                       ],

           'join' => 'JOIN Sentence      AS sent ON ( cs.SentenceID     = sent.SentenceID )
                         JOIN Gherkin       AS gher ON ( cs.GherkinID      = gher.GherkinID)
                         LEFT JOIN Screen   AS scr  ON ( cs.ScreenshotID   = scr.ScreenshotID )',
        }
    ) ;

    $complete_sentence_by_ids = $complete_sentence_by_ids->[ 0 ] ;

    #print Dumper $complete_sentence_by_ids ;

    return
      my $complete_sentence = $self->my_insert(
                                                {
                                                  'insert' => {
                                                                'GherkinID'    => $_[ 0 ]->{ 'GherkinID' },
                                                                'SentenceID'   => $_[ 0 ]->{ 'SentenceID' },
                                                                'ScreenshotID' => $_[ 0 ]->{ 'ScreenshotID' },
                                                              },
                                                  'table'  => 'Complete_sentence',
                                                  'select' => 'CompleteSentenceID',
                                                }
                                              ) ;
} ## end sub add_complete_sentence_with_screenshot_id

sub add_compl_sentence_with_value {

    my $self = shift ;
    my $scollbar_id_exist ;

    my $sentence_id = $_[ 0 ]->{ 'SentenceID' } ;

    #print Dumper $sentence_id;

    my $complete_sentence_by_ids = $self->my_select(
        {
           'from'   => 'Complete_sentence AS cs',
           'select' => [
                         'cs.CompleteSentenceID AS CompleteSentenceID',
                         'sent.SentenceText AS Sentence',
                         'gher.GherkinText  AS Gherkin',
                         'scr.ScreenName    AS Screen',
                       ],

           'join' => 'JOIN Sentence      AS sent ON ( cs.SentenceID = sent.SentenceID )
                         JOIN Gherkin       AS gher ON ( cs.GherkinID  = gher.GherkinID)
                         LEFT JOIN Screen   AS scr  ON ( cs.ScreenID   = scr.ScreenID )',
        }
    ) ;

    $complete_sentence_by_ids = $complete_sentence_by_ids->[ 0 ] ;

    #print Dumper $complete_sentence_by_ids ;

    return
      my $complete_sentence = $self->my_insert(
                                                {
                                                  'insert' => {
                                                                'GherkinID'  => $_[ 0 ]->{ 'GherkinID' },
                                                                'SentenceID' => $_[ 0 ]->{ 'SentenceID' },
                                                                'Value'      => $_[ 0 ]->{ 'Value' },
                                                              },
                                                  'table'  => 'Complete_sentence',
                                                  'select' => 'CompleteSentenceID',
                                                }
                                              ) ;
} ## end sub add_compl_sentence_with_value

sub check_input_data_for_add_complete_sentence {
    my $self = shift ;

    if (     $_[ 0 ]->{ 'GherkinID' }
         and $_[ 0 ]->{ 'SentenceID' } )
    {
        return 1 ;
    } else {
        return 0 ;
    } ## end else [ if ( $_[ 0 ]->{ 'GherkinID'...})]
} ## end sub check_input_data_for_add_complete_sentence

sub add_compl_sentence_given_without_parameter {

    my $self = shift ;
    my $scollbar_id_exist ;

    my $sentence_id  = $_[ 0 ]->{ 'SentenceID' } ;
    my $scrollbar_id = $_[ 0 ]->{ 'GherkinID' } ;

    #print Dumper $sentence_id;

    my $complete_sentence_by_ids = $self->my_select(
        {
           'from'   => 'Complete_sentence AS cs',
           'select' => [
                         'cs.CompleteSentenceID AS CompleteSentenceID',
                         'sent.SentenceText AS Sentence',
                         'gher.GherkinText  AS Gherkin',
                       ],

           'join' => 'JOIN Sentence      AS sent ON ( cs.SentenceID = sent.SentenceID )
                         JOIN Gherkin       AS gher ON ( cs.GherkinID  = gher.GherkinID)
                         ',
        }
    ) ;

    return
      my $complete_sentence = $self->my_insert(
                                                {
                                                  'insert' => {
                                                                'GherkinID'  => $_[ 0 ]->{ 'GherkinID' },
                                                                'SentenceID' => $_[ 0 ]->{ 'SentenceID' },
                                                              },
                                                  'table'  => 'Complete_sentence',
                                                  'select' => 'CompleteSentenceID',
                                                }
                                              ) ;
} ## end sub add_compl_sentence_given_without_parameter

# MONDAT LETREHOZASA, LEGALSO SZINT

#ITEM

sub get_ItemOnScreens_by_screenID {
    my $self = shift ;
    my $result = $self->my_select(
                                   {
                                     'from'   => 'ItemOnScreen',
                                     'select' => 'ItemID',
                                     'where'  => {
                                                  "ScreenID" => $_[ 0 ]->{ 'ScreenID' },
                                                }
                                   }
                                 ) ;

    if ( !$result ) {
        $self->add_error( 'DB_ITEMONSCREEN' ) ;

    } ## end if ( !$result )
    return $result ;
} ## end sub get_ItemOnScreens_by_screenID

#just Item table
sub get_buttonname_list {
    my $self = shift ;
    my $result = $self->my_select(
                                   {
                                     'from'   => 'Item',
                                     'format' => 'ItemID as value, ItemName as label',
                                     'where'  => {
                                                  'ItemTypeID' => 1
                                                }
                                   }
                                 ) ;

    if ( !$result ) {
        $self->add_error( 'DB_ITEMNAME' ) ;

    } ## end if ( !$result )
    return $result ;
} ## end sub get_buttonname_list

#SQL View; Item, ItemOnScreen, Screen tables
sub get_buttonname_list_with_screens {
    my $self = shift ;

    my $result = $self->my_select(
        {
           'from'   => 'Item AS item',
           'select' => [
                         'item.ItemID               AS ItemID',
                         'item.ItemName             AS ItemName',
                         'item_on_screen.PositionID AS PositionID',
                         'screen.ScreenName         AS ScreenName',
                         'screen.ScreenID           AS ScreenID',
                       ],

           'join' => 'JOIN ItemOnScreen AS item_on_screen ON ( item.ItemID = item_on_screen.ItemID      )
                         JOIN Screen       AS screen         ON ( item_on_screen.ScreenID = screen.ScreenID)
                         ',
        }
    ) ;

    return $result ;
} ## end sub get_buttonname_list_with_screens

sub get_values_from_CompleteSentence_table {
    my $self = shift ;
    my $result = $self->my_select(
                                   {
                                     'from'     => 'Complete_sentence',
                                     'select'   => 'Value',
                                     'group_by' => 'Value',
                                   }
                                 ) ;

    if ( defined $result ) {
        return $result ;
    } else {
        return 'DB_VALUES' ;
    } ## end else [ if ( defined $result )]
} ## end sub get_values_from_CompleteSentence_table

sub get_scrollname_list {
    my $self = shift ;
    my $result = $self->my_select(
                                   {
                                     'from'   => 'Item',
                                     'format' => 'ItemID as value, ItemName as label',
                                     'where'  => {
                                                  'ItemTypeID' => 2
                                                }
                                   }
                                 ) ;

    if ( !$result ) {
        $self->add_error( 'DB_ITEMNAME' ) ;

    } ## end if ( !$result )
    return $result ;
} ## end sub get_scrollname_list

sub get_itemname_by_id {
    my $self = shift ;
    my $item_name = $self->my_select(
                                      {
                                        'from'   => 'Item',
                                        'select' => 'ItemName',
                                        'where'  => {
                                                     "ItemID" => $_[ 0 ]->{ 'ItemID' },
                                                   }
                                      }
                                    ) ;

    if ( defined $item_name ) {
        if ( scalar @{ $item_name } > 1 ) {
            return $item_name ;
        } else {
            return $item_name->[ 0 ] ;
        } ## end else [ if ( scalar @{ $item_name...})]
    } else {
        return undef ;
    } ## end else [ if ( defined $item_name)]
} ## end sub get_itemname_by_id

sub get_itemid_by_name {
    my $self = shift ;
    my $item_name = $self->my_select(
                                      {
                                        'from'   => 'Item',
                                        'select' => 'ItemID',
                                        'where'  => {
                                                     "ItemName" => $_[ 0 ]->{ 'ItemName' },
                                                   }
                                      }
                                    ) ;

    if ( defined $item_name ) {
        if ( scalar @{ $item_name } > 1 ) {
            return $item_name ;
        } else {
            return $item_name->[ 0 ] ;
        } ## end else [ if ( scalar @{ $item_name...})]
    } else {
        return undef ;
    } ## end else [ if ( defined $item_name)]
} ## end sub get_itemid_by_name

sub get_ItemNames_by_ScreenID {
    my $self     = shift ;
    my $ScreenID = shift ;
    my $Buttons ;

    my $ItemOnScreenInfos = $self->my_select(
        {
           'from'   => 'Item AS item',
           'select' => [ 'item.ItemName       AS  ItemName', ],

           'join' => 'JOIN ItemOnScreen AS item_on_screen ON ( item.ItemID       = item_on_screen.ItemID )
                         JOIN Screen       AS screen         ON ( item_on_screen.ScreenID = screen.ScreenID )
                         ',
           'where' => {
                        "screen.ScreenID" => $ScreenID->{ 'ScreenID' },
                      }
        }
    ) ;

    foreach my $ItemOnScreenData ( @{ $ItemOnScreenInfos } ) {
        my $Button = $ItemOnScreenData->{ 'ItemName' } ;
        push @{ $Buttons }, $Button ;
    } ## end foreach my $ItemOnScreenData...

    if ( defined $Buttons ) {
        return $Buttons ;
    } else {
        return 'DB_ITEM_ON_SCREEN' ;
    } ## end else [ if ( defined $Buttons )]
} ## end sub get_ItemNames_by_ScreenID

#SCROLLBAR

sub get_scrollbar_list {
    my $self                = shift ;
    my $item_type_scrollbar = 2 ;
    return
      $self->my_select(
                        {
                          'from'   => 'Item',
                          'select' => 'ItemName',
                          'where'  => {
                                       "ItemTypeID" => $item_type_scrollbar,
                                       "ItemID"     => $_[ 0 ]->{ 'ItemID' },
                                     }
                        }
                      ) ;
} ## end sub get_scrollbar_list

sub get_scrollbar_name_from_item_table_by_complete_sentence_id {
    my $self                = shift ;
    my $item_type_scrollbar = 2 ;
    my $scrollbar_ID        = 0 ;

    my $scrollbar_id = $self->my_select(
                                         {
                                           'from'   => 'Item',
                                           'select' => 'ItemName',
                                           'where'  => {
                                                        "ItemTypeID" => $item_type_scrollbar,
                                                        "ItemID"     => $_[ 0 ]->{ 'ScrollbarID' },
                                                      },
                                           "relation" => "and",
                                         }
                                       ) ;

    if ( defined $scrollbar_id ) {
        if ( scalar @{ $scrollbar_id } > 1 ) {
            return $scrollbar_id ;
        } else {
            return $scrollbar_id->[ 0 ] ;
        } ## end else [ if ( scalar @{ $scrollbar_id...})]
    } else {
        return undef ;
    } ## end else [ if ( defined $scrollbar_id)]

} ## end sub get_scrollbar_name_from_item_table_by_complete_sentence_id

sub get_screenshot_name_from_screenshot_table_by_complete_sentence_id {
    my $self = shift ;

    my $screenshot_id = $self->my_select(
                                          {
                                            'from'   => 'Screenshot',
                                            'select' => 'ScreenshotName',
                                            'where'  => {
                                                         "ScreenshotID" => $_[ 0 ]->{ 'ScreenshotID' },
                                                       },
                                          }
                                        ) ;

    if ( defined $screenshot_id ) {
        return $screenshot_id->[ 0 ] ;
    } else {
        return 'SCREENSHOT_FAILURE' ;
    } ## end else [ if ( defined $screenshot_id)]
} ## end sub get_screenshot_name_from_screenshot_table_by_complete_sentence_id

sub get_comm_line_name_from_comm_line_table_by_complete_sentence_id {
    my $self = shift ;

    my $comm_mode_id = $self->my_select(
                                         {
                                           'from'   => 'CommunicationLine',
                                           'select' => 'CommunicationLineText',
                                           'where'  => {
                                                        "CommunicationLineID" => $_[ 0 ]->{ 'CommunicationLineID' },
                                                      },
                                         }
                                       ) ;

    if ( defined $comm_mode_id ) {
        if ( scalar @{ $comm_mode_id } > 1 ) {
            return $comm_mode_id ;
        } else {
            return $comm_mode_id->[ 0 ] ;
        } ## end else [ if ( scalar @{ $comm_mode_id...})]
    } else {
        return undef ;
    } ## end else [ if ( defined $comm_mode_id)]

} ## end sub get_comm_line_name_from_comm_line_table_by_complete_sentence_id

#SCREEN

sub get_screenname_list {
    my $self = shift ;
    my $result = $self->my_select(
                                   {
                                     'from'   => 'Screen',
                                     'format' => 'ScreenID as value, ScreenName as label',
                                   }
                                 ) ;

    if ( !defined $result ) {
        $self->add_error( 'DB_SCREENNAME' ) ;
    } ## end if ( !defined $result )
    return $result ;
} ## end sub get_screenname_list

sub get_screenname_by_id {
    my $self = shift ;
    my $screen_name = $self->my_select(
                                        {
                                          'from'   => 'Screen',
                                          'select' => 'ScreenName',
                                          'where'  => {
                                                       "ScreenID" => $_[ 0 ]->{ 'ScreenID' },
                                                     }
                                        }
                                      ) ;

    if ( defined $screen_name ) {
        if ( scalar @{ $screen_name } > 1 ) {
            return $screen_name ;
        } else {
            return $screen_name->[ 0 ] ;
        } ## end else [ if ( scalar @{ $screen_name...})]
    } else {
        return undef ;
    } ## end else [ if ( defined $screen_name)]
} ## end sub get_screenname_by_id

sub get_screenid_by_name {
    my $self = shift ;
    my $screen_name = $self->my_select(
                                        {
                                          'from'   => 'Screen',
                                          'select' => 'ScreenID',
                                          'where'  => {
                                                       "ScreenName" => $_[ 0 ]->{ 'ScreenName' },
                                                     }
                                        }
                                      ) ;

    if ( defined $screen_name ) {
        if ( scalar @{ $screen_name } > 1 ) {
            return $screen_name ;
        } else {
            return $screen_name->[ 0 ] ;
        } ## end else [ if ( scalar @{ $screen_name...})]
    } else {
        return undef ;
    } ## end else [ if ( defined $screen_name)]
} ## end sub get_screenid_by_name

sub add_new_screen_to_screenshot_table {
    my $self = shift ;
    my $screen_name = $self->my_select(
                                        {
                                          'from'   => 'Screenshot',
                                          'select' => 'ScreenshotID',
                                          'where'  => {
                                                       "ScreenshotName" => $_[ 0 ]->{ 'ScreenshotName' },
                                                       'FeatureID'      => $_[ 0 ]->{ 'FeatureID' },
                                                     }
                                        }
                                      ) ;

    return
      my $screenshot = $self->my_insert(
                                         {
                                           'insert' => {
                                                         'ScreenshotName' => $_[ 0 ]->{ 'ScreenshotName' },
                                                         'FeatureID'      => $_[ 0 ]->{ 'FeatureID' },
                                                       },
                                           'table'  => 'Screenshot',
                                           'select' => 'ScreenshotID',
                                         }
                                       ) ;
} ## end sub add_new_screen_to_screenshot_table

sub add_new_screen {
    my $self = shift ;

    unless (
             $self->my_select(
                               {
                                 'from'   => 'Screen',
                                 'select' => 'ScreenID',
                                 'where'  => {
                                              "ScreenName" => $_[ 0 ]->{ 'ScreenName' },
                                            }
                               }
                             )
           )
    {
        return
          my $screenshot = $self->my_insert(
                                             {
                                               'insert' => {
                                                             'ScreenName' => $_[ 0 ]->{ 'ScreenName' },
                                                           },
                                               'table'  => 'Screen',
                                               'select' => 'ScreenID',
                                             }
                                           ) ;
    } ## end unless ( $self->my_select(...))
} ## end sub add_new_screen

#REFIMAGES

sub get_screenshot_name_by_id {
    my $id = shift ;
    my $DBH = new DBH( { "DB_HANDLE" => $DB } ) ;

    my $screenshot_name = $DBH->my_select(
                                           {
                                             'from'   => 'Screenshot',
                                             'select' => 'ScreenshotName',
                                             'where'  => {
                                                          "ScreenshotID" => $id,
                                                        },
                                           }
                                         ) ;

    foreach my $name ( @{ $screenshot_name } ) {
        return $name->{ 'ScreenshotName' } ;
    } ## end foreach my $name ( @{ $screenshot_name...})
} ## end sub get_screenshot_name_by_id

sub screenshot_is_valid {
    my $self = shift ;
    $self->start_time( @{ [ caller( 0 ) ] }[ 3 ], \@_ ) ;

    #    $self->update_timestamps( $_[ 0 ]->{ 'FeatureID' }, -1 ) ;

    my $result = $self->my_update(
                                   {
                                     'update' => { 'IsValid' => "1" },
                                     'where'  => {
                                                  'ScreenshotID' => $_[ 0 ]->{ 'ScreenshotID' }
                                                },
                                     'table' => 'Screenshot',
                                   }
                                 ) ;

    if ( !$result ) {
        $self->add_error( 'IsValid_1' ) ;

    } ## end if ( !$result )
    return $result ;
} ## end sub screenshot_is_valid

sub screenshot_is_not_valid {
    my $self = shift ;
    $self->start_time( @{ [ caller( 0 ) ] }[ 3 ], \@_ ) ;
    my $result = $self->my_update(
                                   {
                                     'update' => { 'IsValid' => "0" },
                                     'where'  => {
                                                  'ScreenshotID' => $_[ 0 ]->{ 'ScreenshotID' }
                                                },
                                     'table' => 'Screenshot',
                                   }
                                 ) ;

    if ( !$result ) {
        $self->add_error( 'IsValid_0' ) ;

    } ## end if ( !$result )
    return $result ;
} ## end sub screenshot_is_not_valid

sub get_isvalid_status {
    my $self = shift ;

    my @result = $self->my_select(
                                   {
                                     'from'   => 'Screenshot',
                                     'select' => 'IsValid',
                                     'where'  => {
                                                  'FeatureID'    => $_[ 0 ]->{ 'FeatureID' },
                                                  'ScreenshotID' => $_[ 0 ]->{ 'ScreenshotID' }
                                                },
                                     "relation" => "and",
                                     "sort"     => "ScreenshotID",
                                   }
                                 ) ;

    if ( !@result ) {
        $self->add_error( 'SCREENSHOT_FAILURE' ) ;
    } ## end if ( !@result )
    return $result[ 0 ] ;
} ## end sub get_isvalid_status

sub get_screenshot_names {
    my $self   = shift ;
    my $result = undef ;

    $result = $self->my_select(
                                {
                                  'from'   => 'Screenstate',
                                  'format' => 'ScreenstateID as value, ScreenStateName as label',
                                }
                              ) ;

    if ( !$result ) {
        $self->add_error( 'REFIMAGES_BY_FEA' ) ;
    } ## end if ( !$result )
    return $result ;
} ## end sub get_screenshot_names

sub get_refimages_by_fea {
    my $self   = shift ;
    my $result = undef ;

    $result = $self->my_select(
        {
           'from'   => 'Screenshot AS screenshot',
           'select' => [
                         'screenshot.FeatureID      AS FeatureID',
                         'screenshot.IsValid        AS IsValid',
                         'screenshot.Path           AS Path',
                         'screenshot.ScreenshotID   AS ScreenshotID',
                         'screenshot.Screenshot_cnt AS Screenshot_cnt',
                         'screenshot.ScreenstateID  AS ScreenstateID',
                         'screenstate.ScreenStateName AS ScreenshotName',
                       ],

           'join' => 'JOIN Screenstate AS screenstate ON ( screenshot.ScreenstateID = screenstate.ScreenstateID )',

           'where' => { "FeatureID" => $_[ 0 ]->{ 'FeatureID' }, },
        }
    ) ;

    if ( !$result ) {
        $self->add_error( 'REFIMAGES_BY_FEA' ) ;
    } ## end if ( !$result )
    return $result ;
} ## end sub get_refimages_by_fea

sub insert_path {
    my $screenshotID     = shift ;
    my $featureID        = shift ;
    my $screenshotnumber = shift ;

    my $path_proba = 'feature_' . $featureID . '/refimages/' . $screenshotnumber . '.png' ;

    my $result ;

    my $DBH = new DBH( { "DB_HANDLE" => $DB } ) ;

    #print Dumper \@_ ;
    #if( $DBH->check_input_data_for_add_path( @_ ) ){
    #   unless( $DBH->my_select({
    #        'from'   => 'Screenshot',
    #        'select' => 'ScreenshotID',
    #        'where'  => {
    #            "Path" => $_[ 0 ]->{ 'Path' } ,
    #        }
    #   }) )
    #   {
    $result = $DBH->my_update(
                               {
                                 'update' => { 'Path' => $path_proba },
                                 'where'  => {
                                              'ScreenshotID' => $screenshotID
                                            },
                                 'table'  => 'Screenshot',
                                 'select' => 'ScreenshotID',
                               }
                             ) ;

    return $result ;

    # }
    # } else {
    #     #print "add path - FAILED parameter\n" ;
    #     $result = "Failed parameter";
    # }
    return $result ;
} ## end sub insert_path

sub check_input_data_for_add_path {
    my $self = shift ;
    if ( $_[ 0 ]->{ 'FeatureID' } or $_[ 0 ]->{ 'Path' } or $_[ 0 ]->{ 'IsValid' } or $_[ 0 ]->{ 'ScreenshotName' } ) {
        return 1 ;
    } else {
        return 0 ;
    } ## end else [ if ( $_[ 0 ]->{ 'FeatureID'...})]
} ## end sub check_input_data_for_add_path

#COMMUNICATION LINE
#OK
sub get_commmode_list {
    my $self   = shift ;
    my $result = undef ;

    $result = $self->my_select(
                                {
                                  'from'   => 'CommunicationLine',
                                  'format' => 'CommunicationLineID as value, CommunicationLineText as label',
                                }
                              ) ;

    if ( !$result ) {
        $self->add_error( 'COMM_LIST' ) ;

    } ## end if ( !$result )
    return $result ;
} ## end sub get_commmode_list

#SENTENCE

sub get_sentences {
    my $self = shift ;
    my $sentence_texts = $self->my_select(
                                           {
                                             'from'   => 'Sentence',
                                             'format' => 'SentenceID as value, SentenceText as label',
                                           }
                                         ) ;
    return $sentence_texts ;
} ## end sub get_sentences

sub get_sentence_table {
    my $self = shift ;
    $self->my_select(
                      {
                        'from'   => 'Sentence',
                        'select' => 'ALL',
                      }
                    ) ;
} ## end sub get_sentence_table

#OK
sub get_sentence_by_id {
    my $self = shift ;
    my $sentence_name = $self->my_select(
                                          {
                                            'from'   => 'Sentence',
                                            'select' => 'SentenceText',
                                            'where'  => {
                                                         "SentenceID" => $_[ 0 ]->{ 'SentenceID' },
                                                       },
                                            'limit' => 1,
                                          }
                                        ) ;

    if ( defined $sentence_name ) {
        return $sentence_name->[ 0 ] ;
    } else {
        return undef ;
    } ## end else [ if ( defined $sentence_name)]
} ## end sub get_sentence_by_id

sub get_sentenceid_by_name {
    my $self = shift ;
    my $sentence_name = $self->my_select(
                                          {
                                            'from'   => 'Sentence',
                                            'select' => 'SentenceID',
                                            'where'  => {
                                                         "SentenceText" => $_[ 0 ]->{ 'SentenceText' },
                                                       }
                                          }
                                        ) ;

    if ( defined $sentence_name ) {
        if ( scalar @{ $sentence_name } > 1 ) {
            return $sentence_name ;
        } else {
            return $sentence_name->[ 0 ] ;
        } ## end else [ if ( scalar @{ $sentence_name...})]
    } else {
        return undef ;
    } ## end else [ if ( defined $sentence_name)]
} ## end sub get_sentenceid_by_name

#GHERKIN
sub get_gherkin_keywords {
    my $self   = shift ;
    my $result = undef ;

    $result = $self->my_select(
                                {
                                  'from'   => 'Gherkin',
                                  'format' => 'GherkinID as value, GherkinText as label',
                                }
                              ) ;

    if ( !$result ) {
        $self->add_error( 'GHERKIN_WORDS' ) ;

    } ## end if ( !$result )
    return $result ;
} ## end sub get_gherkin_keywords

sub get_actual_testinfos {
    my $self   = shift ;
    my $result = undef ;

    $result = $self->my_select(
                                {
                                  'from'   => 'Actual_Test',
                                  'select' => 'ALL',
                                }
                              ) ;

    if ( !$result ) {
        $self->add_error( 'ACT_INFOS' ) ;

    } ## end if ( !$result )
    return $result->[ 0 ] ;
} ## end sub get_actual_testinfos

sub get_ScreenshotMode {
    my $self   = shift ;
    my $result = undef ;

    $result = $self->my_select(
                                {
                                  'from'   => 'ScreenshotMode',
                                  'format' => 'ScreenshotModeID as value, ScreenshotModeName as label',
                                }
                              ) ;

    if ( !$result ) {
        $self->add_error( 'SCREENSHOTMODE' ) ;

    } ## end if ( !$result )
    return $result ;
} ## end sub get_ScreenshotMode

sub get_gherkin_keyword_by_id {
    my $self = shift ;
    my $gherkin_word = $self->my_select(
                                         {
                                           'from'   => 'Gherkin',
                                           'select' => 'GherkinText',
                                           'where'  => {
                                                        "GherkinID" => $_[ 0 ]->{ 'GherkinID' },
                                                      }
                                         }
                                       ) ;

    if ( defined $gherkin_word ) {
        if ( scalar @{ $gherkin_word } > 1 ) {
            return $gherkin_word ;
        } else {
            return $gherkin_word->[ 0 ] ;
        } ## end else [ if ( scalar @{ $gherkin_word...})]
    } else {
        return undef ;
    } ## end else [ if ( defined $gherkin_word)]
} ## end sub get_gherkin_keyword_by_id

sub get_gherkinid_by_name {
    my $self = shift ;
    my $gherkin_word = $self->my_select(
                                         {
                                           'from'   => 'Gherkin',
                                           'select' => 'GherkinID',
                                           'where'  => {
                                                        "GherkinText" => $_[ 0 ]->{ 'GherkinText' },
                                                      }
                                         }
                                       ) ;

    if ( defined $gherkin_word ) {
        if ( scalar @{ $gherkin_word } > 1 ) {
            return $gherkin_word ;
        } else {
            return $gherkin_word->[ 0 ] ;
        } ## end else [ if ( scalar @{ $gherkin_word...})]
    } else {
        return undef ;
    } ## end else [ if ( defined $gherkin_word)]
} ## end sub get_gherkinid_by_name

sub get_FeatureID_by_name {
    my $self = shift ;
    my $FeatureID = $self->my_select(
                                      {
                                        'from'   => 'Feature',
                                        'select' => 'FeatureID',
                                        'where'  => {
                                                     "Title" => $_[ 0 ]->{ 'Title' },
                                                   }
                                      }
                                    ) ;

    if ( defined $FeatureID ) {
        if ( scalar @{ $FeatureID } > 1 ) {
            return $FeatureID ;
        } else {
            return $FeatureID->[ 0 ]->{ 'FeatureID' } ;
        } ## end else [ if ( scalar @{ $FeatureID...})]
    } else {
        return undef ;
    } ## end else [ if ( defined $FeatureID)]
} ## end sub get_FeatureID_by_name

sub ScreenshotModeUpdate {
    my $self   = shift ;
    my $result = undef ;

    $result = $self->my_update(
                                {
                                  'update' => { 'ScreenshotModeID' => $_[ 0 ]->{ 'ScreenshotModeID' } },
                                  'where'  => {
                                               'FeatureID' => $_[ 0 ]->{ 'FeatureID' }
                                             },
                                  'table'  => 'Feature',
                                  'select' => 'FeatureID',
                                }
                              ) ;

    return $result ;
} ## end sub ScreenshotModeUpdate

sub update_screenshotname_by_screenshot_id {
    my $self = shift ;
    my $result->{ 'VERDICT' } = 1 ;

    $result->{ 'VERDICT' } = $self->my_update(
        {

            'update' => { 'ScreenshotName' => $_[ 0 ]->{ 'ScreenshotName' } },
            'where'  => {
                         'ScreenshotID' => $_[ 0 ]->{ 'ScreenshotID' }
                       },
            'table'  => 'Screenshot',
            'select' => 'ScreenshotID',
        }
    ) ;

    return $result ;
} ## end sub update_screenshotname_by_screenshot_id

sub update_value_in_complete_sentence_table {
    my $self = shift ;
    my $result->{ 'VERDICT' } = 1 ;

    $result->{ 'VERDICT' } = $self->my_update(
                                               {
                                                 'update' => { 'Value' => $_[ 0 ]->{ 'Value' } },
                                                 'where'  => {
                                                              'CompleteSentenceID' => $_[ 0 ]->{ 'CompleteSentenceID' }
                                                            },
                                                 'table'  => 'Complete_sentence',
                                                 'select' => 'CompleteSentenceID',
                                               }
                                             ) ;

    return $result ;
} ## end sub update_value_in_complete_sentence_table

sub add_scrshotName_to_screenshots {
    my $self = shift ;
    my $screen_name = $self->my_select(
        {
           'from'   => 'Screenshot AS scrshot',
           'select' => [ 'scrshot.Path           AS  GeneratedFile', 'scrshot.ScreenshotName AS  ScreenshotName', ],

           'join' => 'JOIN Screenshot AS scrshot2 ON ( scrshot.ScreenshotName = scrshot2.ScreenshotName )',
        }
    ) ;

    $screen_name = $screen_name->[ 22 ] ;
    my $path           = $screen_name->{ 'GeneratedFile' } ;
    my $screenshotname = $screen_name->{ 'ScreenshotName' } ;

    my $link          = '/home/deveushu/OmniBB/TESTS/SYSTEM_TEST/' ;
    my $old_file_path = $link ;

    my $act_number  = "022" ;
    my $act_number_ = $act_number ;
    $act_number_ .= '_' ;
    my $scrshot_with_number = $act_number_ ;
    $scrshot_with_number .= $screenshotname ;
    my $new_file_path = $link ;
    $old_file_path .= $path ;
    $path =~ s/$act_number/$scrshot_with_number/ ;
    $new_file_path .= $path ;
    rename( $old_file_path, $new_file_path || die( "Error in renaming" ) ) ;
} ## end sub add_scrshotName_to_screenshots

sub delele_CompleteSentenceTable {
    my $self = shift ;
    $self->my_delete(
                      {
                        'from'   => 'Complete_sentence',
                        'select' => '',
                      }
                    ) ;

    $self->my_delete(
                      {
                        'from'   => 'Complete_sentence',
                        'select' => '',
                      }
                    ) ;

} ## end sub delele_CompleteSentenceTable

sub get_Coordinates_and_RegionType_by_ScreenstateID {
    my $self   = shift ;
    my $result = undef ;

    $result = $self->my_select(
        {
           'from'   => 'Region AS region',
           'select' => [
                         'region.Multi AS Multi',
                         'region.RegionName AS RegionName',
                         'reg_type.RegionTypeName AS type',
                         'pos.X AS x',
                         'pos.Y AS y',
                         'pos.Height AS height',
                         'pos.Width AS width',
                       ],

           'join' => 'JOIN Screenstate AS screenstate ON ( screenshot.ScreenstateID = screenstate.ScreenstateID )',

           'join' => 'RIGHT JOIN RegionOnScreenstate AS region_on_scr ON ( region.RegionID = region_on_scr.RegionID )
                          LEFT JOIN Positions AS pos ON ( region.PositionID = pos.PositionID )
                          LEFT JOIN RegionType AS reg_type ON ( region.RegionTypeID = reg_type.RegionTypeID )',

           'where' => { "ScreenstateID" => $_[ 0 ]->{ 'ScreenstateID' }, },
        }
    ) ;

    if ( !$result ) {
        $result = 0 ;
    } ## end if ( !$result )
    return $result ;
} ## end sub get_Coordinates_and_RegionType_by_ScreenstateID

sub clear_Actual_Test {
    my $self   = shift ;
    my $result = undef ;

    $result = $self->my_delete(
                                {
                                  'from'   => 'Actual_Test',
                                  'select' => 'ALL',
                                }
                              ) ;

    return $result ;
} ## end sub clear_Actual_Test

sub get_screenstatename_from_path {
    my $self   = shift ;
    my $params = shift ;
    my $result = undef ;
    $self->start_time( @{ [ caller( 0 ) ] }[ 3 ], $params->{ 'Path' } ) ;

    $result = $self->my_select(
        {
           'from'   => 'Screenshot AS screenshot',
           'select' => [ 'screenstate.ScreenStateName AS ScreenshotName', ],

           'join' => 'JOIN Screenstate AS screenstate ON ( screenshot.ScreenstateID = screenstate.ScreenstateID )',

           'where' => { "screenshot.Path" => $params->{ 'Path' } },
        }
    ) ;
    $result = $result->[ 0 ]->{ 'ScreenshotName' } ;
    $self->start_time( @{ [ caller( 0 ) ] }[ 3 ], $result ) ;

    return $result ;
} ## end sub get_screenstatename_from_path


sub get_project_list {
    my $self   = shift ;
    my $result = undef ;

    $result = $self->my_select(
                                {
                                  'from'   => 'project',
                                  'select' => 'ALL',
                                  "sort"   => "Title",
                                }
                              ) ;
	#TODO Project_list
    if ( !$result ) {
        $self->add_error( 'SCENARIO_LIST' ) ;

    } ## end if ( !$result )

    if($result){
    	foreach(@{$result}){
    		$_->{Cnt} = 0;
    	}
    }

    return $result || [] ;

} ## end sub get_scen_list

#TODO add_error
sub get_template_list_by_projectid {
    my $self   = shift ;
	my $params = shift ;
    my $result = undef ;

	
    $result = $self->my_select(
        {
           'from'   => 'project_template as project_temp',
           'select' => [ 'proj.Title AS ProjectName',
                         'sent_temp.SentenceTemplate AS Title'],
    
           'join' => 'JOIN project as proj ON (project_temp.ProjectID = proj.ProjectID)
		              JOIN sentencetemplate as sent_temp ON (project_temp.SentenceTemplateID = sent_temp.SentenceTemplateID ) ' ,
    
           'where' => { "proj.Title" => $params->{ 'ProjectName' } }
        }
    ) ;
							  
    $self->start_time( @{ [ caller( 0 ) ] }[ 3 ], $result ) ;
						  
	#TODO Project_list
    if ( !$result ) {
        $self->add_error( 'SCENARIO_LIST' ) ;
    
    } ## end if ( !$result )
    
    if($result){
    	foreach(@{$result}){
    		$_->{Cnt} = 0;
    	}
    }
    
    return $result || [] ;

} 





1;