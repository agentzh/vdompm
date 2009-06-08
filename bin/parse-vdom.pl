use strict;
use warnings;

use encoding 'utf8';
use lib 'lib';
use VDOM;

my $infile = shift or
    die "No input file specified.\n";
open my $in, $infile or
    die "Cannot open $infile for reading: $!\n";
my $win = VDOM::Window->new;
$win->parse_file($in);
close $in;
print "Parse done!\n";

