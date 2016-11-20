use strict;
use DBH;
use Data::Dumper;
use Log;
use JSON;
use utf8 ;
use Controller_ajax;
use DBConnHandler qw( $DB );
use File::Find;

my $item_name          = "ITEM_NAME"         ;
my $scroll_name        = "SCROLLBAR_NAME"    ;
my $screen_name        = "SCREEN_NAME"       ;
my $screenshot_name    = "SCREENSHOT_NAME"   ;
my $comunication_line  = "COMMUNICATIONLINE" ;
my $screenshot_sent_id = 0 ;
my $path_prefix        = "feature_"   ;
my $gherkin_words ;
my $ITEM_TYPE_TO_TABLE = {
    $item_name        => {
                            'table' => 'Item',
                            'id'    => 'ItemID',
                            'name'  => 'ItemName',  
                            'id_on_c_s_t'  => 'ItemID',                                      
    },
    $scroll_name      => {
                            'table' => 'Item',
                            'id'    => 'ItemID',
                            'name'  => 'ItemName',      
                            'id_on_c_s_t'  => 'ScrollbarID',  
    },
    $screen_name       => {
                            'table' => 'Screen',
                            'id'    => 'ScreenID',
                            'name'  => 'ScreenName',      
                            'id_on_c_s_t'  => 'ScreenID',  
    },
    $comunication_line => {
                            'table' => 'CommunicationLine',
                            'id'    => 'CommunicationLineID',
                            'name'  => 'CommunicationLineText',      
                            'id_on_c_s_t'  => 'CommunicationLineID',  
    },
} ;

&Server_spec_datas::init( "test" ) ;
my $DBH        = new DBH( { "DB_HANDLE" => $DB } ) ;

$gherkin_words           = &get_gherkin_words() ;
my $sentences_from_table = &get_sentences() ;
$screenshot_sent_id      = &get_screenshot_sent_id ( $sentences_from_table ) ;
&create_match( $sentences_from_table ) ;

my $struct;
my $data;
my $sentence_match;
my $names_for_searching_ids;

find({ wanted => \&parse_feature_file_to_db, follow => 1 }, $ARGV[ 0 ] ) ;

sub parse_feature_file_to_db{
	my $file_dir  = $File::Find::name ;
    my $actual_sentence;
    my $row            ;
    my $scenario_ids               = undef;
    my $actual_scenario_id         = undef;
    my $scenario_with_sentence_ids = [];
    my $act_scenarioID             = -1;
    my $prev_scenarioID            = -1;
    my $complete_sentence_id       = 0 ;
    my $order_cnt                  = 0 ;
    my $ids_to_complete_sentence_table ;
    my $num_of_screenshots         = 0 ;
    my $ids = {
        "FeatureID"      => {
                          "data"   => undef,
                          "RegExp" => 'Given Feature ID is (\\d+)' ,     
        },
        "ScenarioID"     => {
                          "data"   => undef,
                          "RegExp" => 'Given Scenario ID is (\\d+)' ,     
        },
        "FeatureTitle"   => {
                          "data"   => undef,
                          "RegExp" => 'Feature:\s*(.*)' ,   
        },
         "ScenarioTitle" => {
                          "data"   => undef,
                          "RegExp" => 'Scenario:\s*(.*)' ,   
        }
    };
    my $filename = $File::Find::fullname;
    return if ( $filename !~ /\.feature/ ) ;
    open(my $fh, '<:encoding(UTF-8)', $filename);
    print "*" x 4 . $filename . "\n";

    my $sentence_data = {
        "complete_sentence_ids" => {},
        "feature_rel_datas"     =>{
                                    'screenshot_number' => 0,            
        },
        'sentence_with_regexp' => undef ,
    } ;
    
    while ( $row = <$fh> )
    {   
        next if $row =~/(^\s*$)/ or $row =~/^\s*#/;
        $row =~s/^\s+(.*?)/$1/;
        $row =~s/check, that the actual screen is/check, that the actual screenshot is/;
        #print "\n". "$row";
        
        $sentence_data->{ 'complete_sentence_ids' } = {} ;
        foreach my $sentence_with_regexp( @{ $sentences_from_table } ){
            $sentence_data->{ 'sentence_with_regexp' } = $sentence_with_regexp ;
            $sentence_data->{ 'sentence_with_regexp' }->{ 'items' } = [] ;
            if ( $row =~/$sentence_with_regexp->{ 'RegExp' }/ ){
                push @{ $sentence_data->{ 'sentence_with_regexp' }->{ 'items' } }, $_ for ( $1, $2, $3, $4 );
      
                &get_ids_for_complete_sentence( $sentence_with_regexp, $row, $sentence_data->{ 'complete_sentence_ids' } );
      
                if ( $sentence_data and ( $sentence_data->{ 'complete_sentence_ids' } ->{ 'SentenceID' } == $screenshot_sent_id ) ){
                    &insert_path_to_screenshot( $sentence_data ) ;
                }

                $sentence_match = 1 ;
                last ;
            }
            
            $sentence_match = 0;
        }

        if( !$sentence_match ){
            $prev_scenarioID  = $sentence_data->{ 'feature_rel_datas' }->{'ScenarioID'};

            &no_db_spec_sent_on_row( $row, $ids ) ;
            $sentence_data->{ 'feature_rel_datas' }->{'FeatureID'}  = &add_feature( $ids->{'FeatureTitle'} ->{'data'} ) if $ids->{'FeatureID'}->{'data'};
            $sentence_data->{ 'feature_rel_datas' }->{'ScenarioID'} = &add_scenario( $ids->{'ScenarioTitle'} ->{'data'}  ) if $ids->{'ScenarioID'}->{'data'};
            $act_scenarioID =  $sentence_data->{ 'feature_rel_datas' }->{'ScenarioID'};
            &add_scen_to_fea( { 'FeatureID' => $sentence_data->{ 'feature_rel_datas' }->{'FeatureID'} , 
                                'ScenarioID' => $act_scenarioID }, \$order_cnt );   


            if( $act_scenarioID ne $prev_scenarioID )
            {
                &add_complete_scentence_to_scenario( $scenario_with_sentence_ids, $prev_scenarioID );       
                $scenario_with_sentence_ids = [] ;
                $sentence_data->{ 'sentence_with_regexp' }->{ 'items' } = [] ;

                $prev_scenarioID = $act_scenarioID ;
            }
        }
        # COMPLETE SENTENCE TABLE 
        if( $sentence_match )
        {
            my $compl_sent_id = &add_ids_for_complete_sentence_table( $sentence_data->{ 'complete_sentence_ids' } ) ;
            print Dumper { 'add_ids_for_complete_sentence_table' => $sentence_data } if !defined $compl_sent_id;
            push @{ $scenario_with_sentence_ids }, $compl_sent_id ;
        }
    }
    &add_complete_scentence_to_scenario( $scenario_with_sentence_ids, $act_scenarioID ) if scalar @{ $scenario_with_sentence_ids };     
}

sub add_feature{
    
    my $feature_data = {
        'Title'            => $_[ 0 ],
        'ScreenshotModeID' => 1
    } ;
    my $res ;
    my $id = $DBH->my_select({
                    'from'   => "Feature"     ,
                    'select' => "FeatureID"   ,   
                    'where'  => $feature_data,
                    'relation' => 'and'
    }) ;

    unless ( defined $id ){

        $id = $DBH->my_insert({
           'insert' => $feature_data  ,
           'table'  => "Feature"       ,
           'select' => 'FeatureID'     ,
        })  ;
        $res = $id ;
    } else {
        $res = $id->[ 0 ]->{ 'FeatureID' } ;
    }

    return $res ;
}

sub add_scenario{
    
    my $feature_data = {
        'Description' => $_[ 0 ],
    } ;
    my $res ;
    my $id = $DBH->my_select({
                    'from'   => "Scenario"     ,
                    'select' => "ScenarioID"   ,   
                    'where'  => $feature_data,
    }) ;
    unless ( defined $id ){

        $id = $DBH->my_insert({
           'insert' => $feature_data    ,
           'table'  => "Scenario"       ,
           'select' => 'ScenarioID'     ,
        })  ;
        $res = $id ;
    } else {
        $res = $id->[ 0 ]->{ 'ScenarioID' } ;
    }
    return $res ;
}

sub no_db_spec_sent_on_row
{
    my $row = shift ;
    my $ids = shift ;
    while ( my ($key, $value) = each %{ $ids } ){
        if( $row =~/$value->{ 'RegExp' }/ ){
            $value->{ 'data' } = $1 ;
        }
    }
}


sub create_match{
    foreach my $sentence ( @{ $_[ 0 ] } ){
        $sentence->{ 'RegExp' } = $sentence->{ 'SentenceText' } ;
        $sentence->{ 'items'  }     = [] ;
        while( $sentence->{ 'RegExp' } =~/([A-Z]+(_[A-Z]+)*)(\s+|$)/g ){
            push @{ $sentence->{ 'item_type' } }, $1 ;
        }
        $sentence->{ 'RegExp' }  =~s/([A-Z]+(_[A-Z]+)*)/\(\.\*\)\?/g ;
    } 
}

sub check_actual_sentence_if_contains_VALUE
{
    my $sentence_datas = shift;
    my $sentence_with_number = ${ $sentence_datas->{ 'items' }->[ 1 ] };
       
    if( $sentence_with_number =~/\"(.*?)\"/ ){
        $sentence_with_number = $1 ;
    }

    return $sentence_with_number;
}

sub get_ids_for_complete_sentence
{
    my $names_for_searching_ids       = shift ;
    my $row                           = shift ;
    my $ids_for_comp_sent             = shift ;
    my $gherkin_id                    = undef ;

    my $item_cnt = 0 ;
    my $table    = "" ;
    my $row_name = "" ;
    my $row_id   = "" ;
    my $id_on_c_s_t = "" ;
    my $data     = "" ;
    my $id       = 0  ;
    my $where_param ;
    
    foreach my $item_type ( @{ $names_for_searching_ids->{ 'item_type' } } ){
        $where_param = {}; 
        $table       = $ITEM_TYPE_TO_TABLE->{ $item_type }->{ 'table' } ;
        $row_name    = $ITEM_TYPE_TO_TABLE->{ $item_type }->{ 'name' }  ;
        $row_id      = $ITEM_TYPE_TO_TABLE->{ $item_type }->{ 'id' }    ;
        $id_on_c_s_t = $ITEM_TYPE_TO_TABLE->{ $item_type }->{ 'id_on_c_s_t' } ;
        
        $data     = &throw_double_quote_off( $names_for_searching_ids->{ "items" }->[ $item_cnt ] ) ;
        if( defined $table ){
            $where_param->{ $row_name } = $data ;
            
            if( $item_type eq $scroll_name ){
                $where_param->{ 'ItemTypeID' } = 2 ;
            } elsif( $item_type eq $item_name ){
                $where_param->{ 'ItemTypeID' } = 1 ;  
            }

            $id = $DBH->my_select({
                            'from'   => $table  ,
                            'select' => $row_id , 
                            'where'  => $where_param,
                            'relation' => 'and'
            }) ;

            unless ( defined $id ){
                $id = $DBH->my_insert({
                    'insert'   => $where_param,
                    'table'    => $table, 
                }) ;
                $ids_for_comp_sent->{ $id_on_c_s_t } = $id ;
            } else {
                $ids_for_comp_sent->{ $id_on_c_s_t } = $id->[ 0 ]->{ $row_id } ;    
            }
            

        } elsif ( $item_type ne $screenshot_name ) {
            $ids_for_comp_sent->{ 'Value' } = $data;
        }           
        $item_cnt++ ;
    }
    $ids_for_comp_sent->{ 'GherkinID' }    = &get_gherkin_id( $row ) ;
    $ids_for_comp_sent->{ 'SentenceID' }   = $names_for_searching_ids->{ 'SentenceID' } ;
    $ids_for_comp_sent->{ 'ScreenshotID' } = $names_for_searching_ids->{ 'ScreenshotID' } if $names_for_searching_ids->{ 'ScreenshotID' } ;
    return $ids_for_comp_sent ;
}

sub throw_double_quote_off
{
    my $actual_value = shift;
    if ( $actual_value =~/\"(.*?)\"/ ){
        $actual_value = $1 ;
    }
    return $actual_value;
}


sub get_sentences
{
    return $DBH->my_select({
         'from'   => 'Sentence'    ,
         'select' => 'ALL',
    });
}

sub get_screenshot_sent_id{
    return @{ [ grep ( $_->{ 'SentenceText' } =~/$screenshot_name/, @{ $_[ 0 ] } ) ] }[ 0 ]->{ 'SentenceID' } ;
}

sub get_gherkin_words
{
    return $DBH->my_select({
         'from'   => 'Gherkin'    ,
         'select' => 'ALL',
    });
}

sub get_gherkin_id
{
    foreach my $gherkin_word ( @{ $gherkin_words } ){
        if( $_[ 0 ] =~/$gherkin_word->{ 'GherkinText' }/ )
        {
            return $gherkin_word->{ 'GherkinID' };        
        }
    }
}

sub insert_path_to_screenshot{
    my $sentence_data    = shift;
    my $id;
    my $path = "" ;
    my $screenshot_name = ${ [ grep ( defined $_ , @{ $sentence_data->{ 'sentence_with_regexp' }->{ 'items' } } ) ] }[ 0 ] ;

    $screenshot_name = &throw_double_quote_off( $screenshot_name ) ;
    my $screenshot_number = sprintf("%03d", $sentence_data->{ 'feature_rel_datas' }->{ 'screenshot_number' } ) ;
    
    $path = $path_prefix . $sentence_data->{ 'feature_rel_datas' }->{'FeatureID'} . "/refimages/" . $screenshot_number . ".png" ;

    my $screenshot_datas = {
        'FeatureID'       => $sentence_data->{ 'feature_rel_datas' }->{'FeatureID'}       ,
        'ScreenshotName'  => $screenshot_name ,
        'Path'            => $path            ,
        'isValid'         => 0                ,    
    };
    
    
    $id = $DBH->my_select({
                    'from'   => "Screenshot"     ,
                    'select' => "ScreenshotID"   ,   
                    'where'  => $screenshot_datas,
                    'relation' => 'and'
    }) ;

    unless ( defined $id ){

        $id = $DBH->my_insert({
           'insert' => $screenshot_datas  ,
           'table'  => "Screenshot"       ,
           'select' => 'ScreenshotID'     ,
        })  ;
        $sentence_data->{ 'complete_sentence_ids' }->{ 'ScreenshotID' } = $id ;
    } else {
        $sentence_data->{ 'complete_sentence_ids' }->{ 'ScreenshotID' } = $id->[ 0 ]->{ 'ScreenshotID' } ;
    }
    $sentence_data->{ 'feature_rel_datas' }->{ 'screenshot_number' }++ ;
}


#COMPLETE SENTENCE 
sub add_ids_for_complete_sentence_table{
    my $cmplete_sentence_ids = shift;

    my $id ;
    if( $cmplete_sentence_ids )
    {
            $id = $DBH->my_select({
                            'from'   => "Complete_sentence"  ,
                            'select' => "CompleteSentenceID" , 
                            'where'  => $cmplete_sentence_ids,
                            "relation" => "and"
            }) ;
    
            unless ( defined $id ){
                my $complete_sentence = $DBH->my_insert({
                   'insert' => $cmplete_sentence_ids,
                   'table'  => 'Complete_sentence'  ,
                   'select' => 'CompleteSentenceID' ,
                })  ;
                return $complete_sentence ; ;
            } else {
                return $id->[ 0 ]->{ 'CompleteSentenceID' } ;
            }
    }
    return undef ;
}

sub add_screenshot_to_feature{
    
    
}

#SCENARIO WITH SENTENCE
sub add_complete_scentence_to_scenario{
    my $scenario_with_sentence_ids = shift;
    my $scenario_id                = shift;
    my $order_cnt                  = 0    ;  

    foreach my $scenario_with_sentence_id( @{ $scenario_with_sentence_ids } ){
       
        my $id = $DBH->my_select({
                        'from'   => "Scenario_with_sentence"  ,
                        'select' => "CompleteSentenceID" , 
                        'where'  => { 
                           "ScenarioID"         => $scenario_id,
                           "CompleteSentenceID" => $scenario_with_sentence_id,  
                           "Position"           => $order_cnt,
                       },
                       "relation" => "and"
        }) ;

        unless ( defined $id ){
               my $result = $DBH->my_insert({
               'insert' => { 
                   "ScenarioID"         => $scenario_id,
                   "CompleteSentenceID" => $scenario_with_sentence_id,  
                   "Position"           => $order_cnt,
               },
               'table'  => 'Scenario_with_sentence',
               'select' => 'CompleteSentenceID'    ,
               });
        } else {

        }  
        $order_cnt++;    
    }
    $scenario_with_sentence_ids = [] ;     
} 

#FEATURE-SCENARIO
sub add_scen_to_fea{
    my $datas     = shift ;
    my $order_cnt = shift ;
    my $actual_scenarioID = undef;
    return unless $datas->{ 'ScenarioID' };

    my $id = $DBH->my_select({
                    'from'   => "FeatureScenario"  ,
                    'select' => "FeatureScenarioID" , 
                    'where'  => { 
                         "FeatureID"   => $datas->{ 'FeatureID' },
                         "ScenarioID"  => $datas->{ 'ScenarioID' } ,  
                         "Position"    => $order_cnt   ,
                     },
                   "relation" => "and"
    }) ;

    unless ( defined $id ){
            my $result = $DBH->my_insert({
                 'insert' => { 
                     "FeatureID"   => $datas->{ 'FeatureID' },
                     "ScenarioID"  => $datas->{ 'ScenarioID' },  
                     "Position"    => $order_cnt   ,
                 },
                 'table'  => 'FeatureScenario'     ,
                 'select' => 'FeatureScenarioID'   ,
            });
            print "\nFeatureID: $datas->{ 'FeatureID' } " . 
                  "ScenarioID: $datas->{ 'ScenarioID' }  order: ${ $order_cnt }\n" ;
            ${ $order_cnt }++;
    } else {

    }    

}





















    

        
       



