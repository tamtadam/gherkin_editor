use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;


my $path = "..";

GetOptions (
            "path=s"  => \$path
) or die("Missing argument");


print qx{perlcritic -3 $path};

