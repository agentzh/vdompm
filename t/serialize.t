use strict;
use warnings;

use encoding 'utf8';
use lib 'lib';

#use Test::More tests => 172;
use Test::More 'no_plan';

#use Devel::Leak::Object qw( GLOBAL_bless );
BEGIN { use_ok('VDOM::Node') }
BEGIN { use_ok('VDOM::Element') }
BEGIN { use_ok('VDOM::Text') }
BEGIN { use_ok('VDOM::Window') }

{
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
my $p = $win->document->body->firstChild;
is $p->asVdom, <<'_EOC_', 'vdom first child';
DIV width=600 height=800 className="a b" id="foo-bar" {
P width=600 height=800 className="c d" {
P width=600 height=800 id="hello" {
}
}
P width=600 height=800 className="d" {
A width=600 height=800 {
}
}
}
_EOC_
}

{
my $src = <<'_EOC_';
window location="http://www.yahoo.com/\"" innerHeight=27 {
document width=600 height=800 title="Human & Machine" {
BODY id="mybody" x=0 y=0 w=200 h=300 {
    "\n\n\n >> " x=260 y=33 w=28 h=14 {
    "" pos=0 len=1 w=7
    "" pos=4 len=3 x=267 w=21
    }
    "Hello, world!"
}
}
}
_EOC_
my $win = VDOM::Window->new;
ok $win, 'VDOM::Window obj ok';
isa_ok $win, 'VDOM::Window', 'ref ok';
$win->parse(\$src);
my $body = $win->document->body;
my $t1 = $body->firstChild;  # being a text node with text runs
is $t1->asVdom, <<'_EOC_', 'text node with text run ok';
"\n\n\n >> " x=260 y=33 w=28 h=14 {
"" pos=0 len=1 x=260 y=33 w=7 h=14
"" pos=4 len=3 x=267 y=33 w=21 h=14
}
_EOC_

my $t2 = $body->lastChild;  # being a text node with text runs
is $t2->asVdom, <<'_EOC_', 'text node without text run ok';
"Hello, world!" x=0 y=0 w=200 h=300 {
}
_EOC_

my $t3 = VDOM::Element->fromVdom($t2->asVdom);
ok $t3, 'fromVdom returns something';
ok ref $t3, 'fromVdom returns a ref';
isa_ok $t3, 'VDOM::Element', 'fromVdom returns an element';

}

