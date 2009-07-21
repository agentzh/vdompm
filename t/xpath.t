use strict;
use warnings;

use lib 'lib';
use Test::More 'no_plan';
BEGIN { use_ok('VDOM::Node') }
BEGIN { use_ok('VDOM::Element') }
BEGIN { use_ok('VDOM::Text') }
BEGIN { use_ok('VDOM::Window') }

use Scalar::Util qw( refaddr );

my $src = <<'_EOC_';
window location="http://www.yahoo.com/\"" innerHeight=27 {
document width=600 height=800 title="Human & Machine" {
BODY id="mybody" {
    DIV id="foo-bar" className="a b" {
        P className="c d" {
            DIV id="hello" {
            }
        }
        P className="d" {
            A {
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

my $doc = $win->ownerDocument;
my $p = $win->document->body->firstChild->firstChild->firstChild;

my $xpath = $p->xpath;
is $xpath, '/document/BODY/DIV/P/DIV', 'xpath ok';
is refaddr($p->getNodeByXpath($xpath)), refaddr($p), 'get node by xpath ok';

$p = $win->document->body->firstChild->firstChild->nextSibling->firstChild;

$xpath = $p->xpath;
is $xpath, '/document/BODY/DIV/P[1]/A', 'xpath ok';
is refaddr($p->getNodeByXpath($xpath)), refaddr($p), 'get node by xpath ok';

is refaddr($p->getNodeByXpath('/HTML/BODY/DIV/P[1]/A')), refaddr($p), 'get node by xpath ok';

ok !$p->getNodeByXpath('/HTML/BODY/DIV/P[2]/A'), 'get node by xpath ok';

my $div = $p->getNodeByXpath('/HTML/BODY/div/');
ok $div, 'get div ok';
is $div->tagName, 'DIV', 'get div tagname ok';

is refaddr($div->getNodeByXpath('P[1]/A/')), refaddr($p), 'get node by relative xpath ok';
