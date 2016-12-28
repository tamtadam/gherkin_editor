use strict;
use warnings;
use Data::Dumper;use File::Spec::Functions qw(rel2abs abs2rel);
use FindBin;
use Cwd qw(cwd realpath);

use File::Basename qw(dirname);

my $cwd = cwd();

my $dir = dirname(__FILE__) . '/../cgi-bin/';

print qx{perlcritic -3 $dir};


