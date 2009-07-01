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
            P id="hello" {
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
my $p = $win->document->body->firstChild->firstChild->firstChild;
ok defined $p, 'the P#hello found';
is $p->simpleSelector, 'BODY>DIV>P>P', 'simple selector ok';
is $p->selector, 'BODY#mybody>DIV#foo-bar>P.c>P#hello', 'full selector ok';
ok $p->matchSelector({tag => 'P', id => 'hello'}), 'P#hello matched';
ok $p->matchSelector({tag => 'P'}), 'P#hello matched';
ok !$p->matchSelector({tag => 'B'}), 'P#hello not matched';
ok !$p->matchSelector({tag => 'P', id => 'hello2'}), 'P#hello not matched';
ok !$p->matchSelector({tag => 'P', id => 'hello', class=>'abc'}), 'P#hello not matched';

ok !$p->parentNode->matchSelector({tag => 'P', id => 'hello'}), 'P#hello not matched';
ok $p->parentNode->matchSelector({tag => 'P'}), 'P.c .d matched';
ok $p->parentNode->matchSelector({tag => 'P', class=>'c'}), 'P.c .d matched';
ok !$p->parentNode->matchSelector({tag => 'P', class=>'cd'}), 'P.c .d not matched';
ok $p->parentNode->matchSelector({tag => 'P', class=>'d'}), 'P.c .d matched';

{
    my @res = $p->parentNode->getElementsBySelector('P>P');
    is scalar(@res), 1, 'found one elem';
    is $res[0]->id, 'hello', 'found the right elem';
}

{
    my @res = $p->parentNode->getElementsBySelector('P.d>P#hello');
    is scalar(@res), 1, 'found one elem';
    is $res[0]->id, 'hello', 'found the right elem';
}

{
    my @res = $p->parentNode->getElementsBySelector('P');
    is scalar(@res), 1, 'found one elem';
    is $res[0]->className, 'c d', 'found the right elem';
}

{
    my @res = $p->parentNode->getElementsBySelector('P.c');
    is scalar(@res), 1, 'found one elem';
    is $res[0]->className, 'c d', 'found the right elem';
}

{
    my ($a) = $win->document->getElementsByTagName("A");
    ok $a, 'found tag a';
    is $a->selector, 'BODY#mybody>DIV#foo-bar>P.d>A', "a's selector looks good";
    my @res = $win->document->body->getElementsBySelector($a->selector);
    is scalar(@res), 1, 'found 1 elem as expected';
    is refaddr($res[0]), refaddr($a), 'exactly the same <A> found';

    is $a->simpleSelector, 'BODY>DIV>P>A', "a's simpleSelector looks good";
    @res = $win->document->body->getElementsBySelector($a->simpleSelector);
    is scalar(@res), 1, 'found 1 elem as expected';
    is refaddr($res[0]), refaddr($a), 'exactly the same <A> found';
}

{
    my $selector = "BODY>DIV>P";
    my @res = $win->document->body->getElementsBySelector($selector);
    is scalar(@res), 2, 'found 2 elem as expected';
    for my $elem (@res) {
        is $elem->simpleSelector, $selector, 'simplSelector as expected';
    }
}

