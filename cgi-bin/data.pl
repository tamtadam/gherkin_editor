use strict;
use warnings;

use lib "/home/deveushu/workspace/OmniBB/PERL_MODULES";
use Server_spec_datas qw( $DB SESS_REQED $LOG ); 
use CGI;
use View_ajax;
use Controller_ajax;
use Data::Dumper ;

print Dumper my $DB = &Server_spec_datas::init( "omni_V1.40.00.00" );

my $data = {
          'get_versions'    => { 
                  'get' => 1,
                       } ,    
};

print Dumper my $controller = Controller_ajax->new( { 'DB_HANDLE' => $DB, 
                                         'LOG_DIR'   => "/home/deveushu/web_log/test_results/",
                                         "MODEL"     => "Modell_ajax"
                                        });

print Dumper my $struct = $controller->start_action( $data );