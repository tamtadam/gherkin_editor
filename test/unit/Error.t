use strict;
use warnings;
use Data::Dumper;

use FindBin ;
use lib $FindBin::RealBin;
use lib $FindBin::RealBin . "../../../../common/cgi-bin/" ;
use lib $FindBin::RealBin . "../../../cgi-bin/" ;

use Test::More tests => 3;

use TestMock;
use Errormsg;

my $error = Errormsg->new();

sub BEGIN {
}

sub END {
}


subtest 'get_error_text' => sub {
    my $res = $error->get_error_text( Errormsg::SESSIONREQ );
    ok( $res eq 'You are not logged in', 'session req' );
    
    $res = $error->get_error_text( 'not exist' );
    ok( $res eq 'not exist does not found', 'not exist' );
};


subtest 'add_error' => sub {
    #my $error_mock = TestMock->new( 'Errormsg' );
    #   $error_mock->mock( 'new' );
    #   $error_mock->mock( 'get_error_text' );
    #$error_mock->get_error_text(1);
    my $res = $error->add_error( Errormsg::DB_SELECT );
    ok( $res, 'session req' );
    
    #$error_mock->unmock( 'get_error_text' );
};

subtest 'get_errors' => sub {
    my $res = $error->get_errors();
    is_deeply($res, [
        'Selection from db. does not response'
    ], 'only one error');
};





