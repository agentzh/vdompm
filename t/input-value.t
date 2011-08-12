use strict;
use warnings;

use encoding 'utf8';
use lib 'lib';

use Test::More tests => 6;

BEGIN { use_ok('VDOM::Node') }
BEGIN { use_ok('VDOM::Element') }
BEGIN { use_ok('VDOM::Text') }
BEGIN { use_ok('VDOM::Window') }

my $elem = VDOM::Element->new;
$elem->parse_line(\'INPUT id="keywords" value="请输入关键字" w=470 h=24 fontSize="14px" color="rgb(170, 170, 170)" backgroundColor="rgb(255, 255, 255)" {');

is $elem->tagName, 'INPUT', 'tagName okay';
is $elem->value, "请输入关键字", 'value okay';
