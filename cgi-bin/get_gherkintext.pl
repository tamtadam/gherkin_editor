use strict;
use warnings;
use lib '/home/deveushu/OmniBB/PERL_MODULES' ;

use Server_spec_datas qw( $DB SESS_REQED $LOG ); 
use CGI;
use View_ajax;
use Controller_ajax;
use Data::Dumper ;

#perl get_gherkin_text.pl get_gherkintext_by_scen ScenarioID 10208
#perl get_gherkin_text.pl get_gherkintext_by_fea FeatureID 33

my $ajax  = View_ajax->new()      ;
my $struct;
my $data;          
my $function_name = $ARGV[0];
my $column_name   = $ARGV[1];
my $property      = $ARGV[2];

$data = {
    $function_name => { 
        $column_name => $property,
    }    
};

$DB = &Server_spec_datas::init( "omni" );

my $controller = Controller_ajax->new( { 'DB_HANDLE' => $DB, 
                                         'LOG_DIR'   => "/home/deveushu/web_log/test_editor/",
                                        });

$struct = $controller->start_action( $data );
print Dumper $struct->{$function_name};
