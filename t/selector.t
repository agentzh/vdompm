use strict;
use warnings;

use lib 'lib';
use Test::More 'no_plan';
BEGIN { use_ok('VDOM::Node') }
BEGIN { use_ok('VDOM::Element') }
BEGIN { use_ok('VDOM::Text') }
BEGIN { use_ok('VDOM::Window') }

my $src = <<'_EOC_';
window location="http://www.yahoo.com/\"" innerHeight=27 {
document width=600 height=800 title="Human & Machine" {
BODY id="mybody" {
    DIV id="foo-bar" className="a b" {
        P className="c d" {
            P id="hello" {
            }
        }
    }
}
}
}
_EOC_

my $win = VDOM::Window->new;
ok $win, 'VDOM::Window obj ok';
isa_ok $win, 'VDOM::Window', 'ref ok';
$win->parse(\$src);
my $p = $win->document->body->firstChild->firstChild->firstChild;
ok defined $p, 'the P#hello found';
is $p->simple_selector, 'BODY>DIV>P>P', 'simple selector ok';
is $p->selector, 'BODY#mybody>DIV#foo-bar>P.c>P#hello', 'simple selector ok';

