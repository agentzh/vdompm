use strict;
use warnings;

use encoding 'utf8';
use lib 'lib';

BEGIN {
    binmode \*STDOUT, ":utf8";
    binmode \*STDERR, ":utf8";
}

use Test::More tests => 172;
#use Test::More 'no_plan';

#use Devel::Leak::Object qw( GLOBAL_bless );
BEGIN { use_ok('VDOM::Node') }
BEGIN { use_ok('VDOM::Element') }
BEGIN { use_ok('VDOM::Text') }
BEGIN { use_ok('VDOM::Window') }

my $elem = VDOM::Element->new;
ok $elem, 'VDOM::Element obj ok';
isa_ok $elem, 'VDOM::Element', 'ref ok';
$elem->parse_line(\'BODY x=0 y=0 w=914 h=3361 fontFamily="Arial,Helvetica,sans-serif" fontSize="12px" fontStyle="normal" fontWeight="400" color="rgb(51, 51, 51)" backgroundColor="transparent" {');
is $elem->tagName, 'BODY', 'tagName ok';
is $elem->x, 0, 'x';
is $elem->y, 0, 'y';
is $elem->w, 914, 'w';
is $elem->h, 3361, 'h';
is $elem->fontFamily, 'Arial,Helvetica,sans-serif', 'font family';
is $elem->fontSize, '12px', 'fontSize ok';
is $elem->fontStyle, 'normal', 'fontStyle ok';
is $elem->fontWeight, '400', 'fontWeight ok';
is $elem->color, 'rgb(51, 51, 51)', 'color ok';
my @child = $elem->childNodes;
is scalar @child, 0, 'childNodes ok';

$elem = VDOM::Element->new($elem);
is $elem->tagName, 'BODY', 'tagName ok';
is $elem->x, 0, 'x';
is $elem->y, 0, 'y';
is $elem->w, 914, 'w';
is $elem->h, 3361, 'h';
is $elem->fontFamily, 'Arial,Helvetica,sans-serif', 'font family';
is $elem->fontSize, '12px', 'fontSize ok';
is $elem->fontStyle, 'normal', 'fontStyle ok';
is $elem->fontWeight, '400', 'fontWeight ok';
is $elem->color, 'rgb(51, 51, 51)', 'color ok';
is $elem->nodeType, $VDOM::Node::ELEMENT_NODE, 'elem nodeType ok';

my $text = VDOM::Text->new->parse_line(\'"华北东北:\t"');
is($text->nodeValue, "华北东北:\t", 'nodeValue works');
is $text->nodeType, $VDOM::Node::TEXT_NODE, 'elem nodeType ok';

my $doc = VDOM::Document->new;
ok $doc, 'doc ok';
isa_ok $doc, 'VDOM::Document', 'doc ref ok';
$doc->parse_line(\"document width=914 height=3361 {\n");
is $doc->width, 914, 'doc width ok';
is $doc->height, 3361, 'doc height ok';
is $doc->color, undef, 'doc color not set';
is $doc->tagName, 'document', 'doc tagName ok';
is $doc->title, undef, 'title undefined';

my $win = VDOM::Window->new;
ok $win, 'VDOM::Window obj ok';
isa_ok $win, 'VDOM::Window', 'ref ok';
is $win->color, undef, 'win color not set';
$win->document($doc);
is($win->document, $doc, 'doc get/set okay');

$win->parse_line(\'window location="http://www.dianping.com/shop/553911" scrollMaxX=50 scrollMaxY=2574 innerHeight=802 innerWidth=929 outerHeight=943 outerWidth=1272 {');
is $win->tagName, 'window', 'win tagName ok';
is $win->location, 'http://www.dianping.com/shop/553911', 'location ok';
is $win->scrollMaxX, 50, 'win scrollMaxX ok';
is $win->scrollMaxY, 2574, 'win scrollMaxY ok';
is $win->innerHeight, 802, 'win innerHeight ok';
is $win->innerWidth, 929, 'win innerWidth ok';
is $win->outerWidth, 1272, 'win outerWidth ok';

my $src = <<'_EOC_';
window location="http://www.yahoo.com/\"" innerHeight=27 {
document width=600 height=800 title="Human & Machine" {
BODY id="mybody" {
"hello, world\n"
}
}
}
_EOC_

$win->parse(\$src);

is $win->tagName, 'window', 'tagName still okay';
is $win->document->title, 'Human & Machine', 'title ok';
is $win->scrollMaxX, undef, 'scrollMaxX cleared already';
is $win->scrollMaxY, undef, 'scrollMaxY cleared already';
is $win->location, 'http://www.yahoo.com/"', 'new win.loc ok';
is $win->innerHeight, 27, 'new win.innerHeight ok';
is $win->innerWidth, undef, 'new win.innerWidth cleared';
isnt $win->document, $doc, 'document changed';
is $win->document->width, 600, 'new doc.width ok';
is $win->document->height, 800, 'new doc.height ok';

my $body = $win->document->body;
ok $body, 'body found';
isa_ok $body, 'VDOM::Element', 'body ref ok';
is $body->tagName, 'BODY', 'body tagName ok';
is $body->id, 'mybody', 'body id ok';
@child = $body->childNodes;
is @child, 1, 'found 1 child';
my $node = $child[0];
ok $node, 'text node ok';
isa_ok $node, 'VDOM::Text', 'text node ref ok';
is $node->nodeValue, "hello, world\n", 'nodeValue ok';
is $win->document->parentNode, $win, 'parentNode works';

$src = <<'_EOC_';
window location="http://www.yahoo.com/\"" innerHeight=27 {
document width=600 height=800 {
HEAD {
    "blah"
    }
BODY id="mybody" {
"hello, world\n"
}
}
}
_EOC_

$win->parse(\$src);
$doc  = $win->document;
$body = $win->document->body;
is $body->textContent, "hello, world\n", 'elem textContent works';
is $body->firstChild->textContent, "hello, world\n", 'elem textContent works';
is $doc->firstChild->textContent, "blah", 'elem textContent works';
is $doc->textContent, "blahhello, world\n", 'doc textContent works';
#my $head = $win->document->firstChild;
## $body
ok $body->previousSibling, 'previousSibling found';
is $body->previousSibling->tagName, 'HEAD', 'previousSibling tagName ok';
is $body->previousSibling->textContent, 'blah', 'previousSibling textContent ok';

ok !$body->nextSibling, 'nextSibling not found';

ok $body->previousElementSibling, 'previousElementSibling found';
is $body->previousElementSibling->tagName, 'HEAD', 'previousElementSibling tagName ok';
is $body->previousElementSibling->textContent, 'blah', 'previousElementSibling textContent ok';

ok !$body->previousSibling->previousSibling,
    "previousSibling's previousSibling not found as expected";

### _childNodes: $doc->{_childNodes}
ok $doc->firstChild, 'doc firstChild found';
is $doc->firstChild->tagName, 'HEAD', 'doc firstChild tagName ok';

ok $doc->lastChild, 'doc lastChild found';
is $doc->lastChild->tagName, 'BODY', 'lastChild tagName ok';

ok $body->lastChild, 'body lastChild found';
is $body->lastChild->nodeType, $VDOM::Node::TEXT_NODE, 'lastChild tagName ok';

ok $body->firstChild, 'body firstChild found';
is $body->firstChild->nodeType, $VDOM::Node::TEXT_NODE, 'firstChild tagName ok';
is $body->firstChild, $body->lastChild, 'firstChild tagName ok';
is $body->firstChild->firstChild, undef, 'text node has no firstChild';

is $doc->ownerDocument, undef, 'doc has no ownerDocument';
is $doc->body->ownerDocument, $doc, 'body ownerDocument ok';
is $doc->body->firstChild->ownerDocument, $doc, 'firstChild ownerDocument ok';

#is $win->ownerWindow, undef, 'window has no ownerWindow';
is $doc->ownerWindow, $win, 'doc ownerWindow ok';
is $doc->body->ownerWindow, $win, 'body ownerWindow';
is $doc->body->firstChild->ownerWindow, $win, 'firstChild ownerDocument ok';


# Test getElementsByTagName
my @elem = $doc->getElementsByTagName("BODY");
is scalar(@elem), 1, 'found 1 BODY';
is $elem[0], $doc->body, 'indeed that body';

@elem = $doc->getElementsByTagName("bOdY");
is scalar(@elem), 1, 'found 1 bOdY';
is $elem[0], $doc->body, 'indeed that body';

@elem = $doc->getElementsByTagName("head");
is scalar(@elem), 1, 'found 1 head';
is $elem[0]->tagName, 'HEAD', 'indeed that head';

@elem = $body->getElementsByTagName("BODY");
is scalar(@elem), 0, 'no BODY found on BODY';

$body->setAttribute('foo', 32);
is $body->getAttribute('foo'), 32, 'set/getAttribute ok';
is $body->attr('foo'), 32, 'attr read ok';
$body->attr('foo', 47);
is $body->attr('foo'), 47, 'attr write ok';

# Test getElementById

$node = $doc->getElementById('mybody');
ok $node, 'found elem with "mybody" id';
is $node->id, 'mybody', 'getElementById works';

$node = $doc->getElementById('MYBODY');
ok ! $node, 'found no elem with id "MYBODY"';

$src = <<'_EOC_';
window location="http://www.yahoo.com/\"" abc=-1 innerHeight=27 {
document width=600 height=800 {
BODY id="mybody" {
"hello, world\n"
"\n!"
"..."
}
}
}
_EOC_

$win->parse(\$src);
is $win->document->body->firstChild->nodeValue, "hello, world\n",
    'adjacent text nodes merged';

$src = <<'_EOC_';
window location="http://www.yahoo.com/\"" abc=-1 innerHeight=27 {
document width=600 height=800 {
BODY id="mybody" {
P id="a" {
}
"hello, world\n"
P id="b" {
}
P id="c" {
}
"\n!"
"..."
}
}
}
_EOC_

$win->parse(\$src);
$doc = $win->document;
$node = $doc->getElementById('c');
ok $node, 'found p#c';
is $node->id, 'c', 'p#c id ok';
is $node->tagName, 'P', 'p#c tagName ok';

my $n2 = $node->nextElementSibling;
ok !defined $n2, 'nextElementSibling not found';

$n2 = $node->nextSibling;
ok $n2, 'p#c has nextSibling (a text node)';
is $n2->nodeType, $VDOM::Node::TEXT_NODE, 'node Type is indeed text';
is $n2->nodeValue, "\n!", 'nodeValue ok';
is $n2->textContent, "\n!", 'textContent ok';

my $n3 = $n2->previousElementSibling;
ok $n3, 'found p#c';
is $n3, $node, 'it is indeed p#c';
$n2 = $node->previousElementSibling;
ok $n2, "found p#c's previousElementSibling";
is $n2->id, 'b', 'it is indeed p#b (id ok)';
is $n2->tagName, 'P', 'it is indeed p#b (tagName ok)';

$n2 = $n2->previousElementSibling;
ok $n2, "found p#b's previousElementSibling";
is $n2->id, 'a', 'it is p#a (id ok)';
is $n2->tagName, 'P', 'it is p#a (tagName ok)';

$n3 = $n2->previousElementSibling;
ok ! $n3, "p#a has no previous element sibling";

$n2 = $n2->nextElementSibling;
ok $n2, "found p#b";
is $n2->id, 'b', 'it is indeed p#b (id ok)';
is $n2->tagName, 'P', 'it is indeed p#b (tagName ok)';

$n2 = $n2->nextElementSibling;
ok $n2, "found p#c";
is $n2->id, 'c', 'it is indeed p#c (id ok)';
is $n2->tagName, 'P', 'it is indeed p#c (tagName ok)';

$n3 = $n2->nextElementSibling;
ok ! $n3, "p#c has no next element sibling";

$body = $doc->body;
$node = $body->firstElementChild;
is $node->tagName, 'P', 'it is p#a (tagName ok)';
is $node->id, 'a', 'it is p#a (id ok)';

$node = $body->lastElementChild;
is $node->tagName, 'P', 'it is p#c (tagName ok)';
is $node->id, 'c', 'it is p#c (id ok)';

# XXX test *ElementSibling methods more thoroughly :)

# XXX test *ElementSibling methods more thoroughly :)

$src = <<'_EOC_';
  window location="http://www.yahoo.com/\"" abc=-1 innerHeight=27 {
    document width=600 height=800 {
        BODY id="mybody" {
            "Hello, "
        }
        "world"
    }
}
_EOC_
$win->parse(\$src);
$doc = $win->document;
$body = $doc->body;
ok ! $VDOM::Node::CacheTextContent, 'cache text content default off';
is $doc->textContent, 'Hello, world', 'text content works';
$body->nextSibling->nodeValue('DOMs');
is $doc->textContent, 'Hello, DOMs', 'text content changes w/o caching';
$VDOM::Node::CacheTextContent = 1;
is $doc->textContent, 'Hello, DOMs', 'text content should be cached now';
$body->nextSibling->nodeValue('world');
is $doc->textContent, 'Hello, DOMs', 'text content should return the cached version';
$VDOM::Node::CacheTextContent = 0;
is $doc->textContent, 'Hello, world', 'disable the cache now';

$src = <<'_EOC_';
window {
    document {
        BODY {
            "hello, "
            IMG src="foo.bar" alt="world" {
            }
        }
    }
}
_EOC_
$win->parse(\$src);
$doc = $win->document;
$body = $doc->body;
is $body->textContent, "hello, ", 'alt is not part of the textContent';
is $body->textContentWithImgAlt, "hello, world", 'alt is also part of the textContent';

$src = <<'_EOC_';
window {
    document {
        BODY fontSize="12px" fontWeight="400" {
            P fontWeight="bold" {
            }
        }
    }
}
_EOC_
$win->parse(\$src);
$doc = $win->document;
$body = $doc->body;
is $body->fontSize, "12px", 'body font size okay';
is $body->numericFontSize, "12", 'body num font size okay';
is $body->fontWeight, "400", 'body font size okay';
is $body->numericFontWeight, "400", 'body num font size okay';
is $body->numericFontWeight, "400", 'body num font size okay (2)';
is $body->firstChild->fontWeight, "bold", 'P font weight okay';
is $body->firstChild->numericFontWeight, "700", 'P num font weight okay';
is $body->firstChild->numericFontWeight, "700", 'P num font weight okay (2)';

{
my $src = <<'_EOC_';
window {
    document {
        BODY fontSize="12px" fontWeight="400" {
A href="http://api.eeeeworks.org/=/feed/Comment/_user/agentzh.Public" x=166 y=546 w=116 h=41 fontWeight="bold" color="rgb(51, 153, 204)" {
    "Subscribe to the comment feed" x=12 y=1 {
        "" pos=0 len=16 h=19
        "" pos=17 len=12 y=23 w=104 h=19
    }
        }
    }
}
_EOC_
my $win = VDOM::Window->new;
$win->parse(\$src);
ok $win, 'built win';
my ($A) = $win->document->getElementsByTagName("A");
ok $A, 'found tag A';
my $text = $A->firstChild;
ok $text, 'found the Text Node';
is $text->x, 12, 'x okay';
is $text->offsetX, 12, 'offsetX okay';

is $text->y, 1, 'y okay';
is $text->offsetY, 1, 'offsetY okay';

is $text->w, 116, 'w okay';
is $text->h, 41, 'h okay';
isa_ok $text, 'VDOM::Text';

is scalar($text->childNodes), 2, 'two text run';
my $first_run = $text->firstChild;
is $first_run->nodeValue, "Subscribe to the", 'first text run ok';
is $first_run->x, 12, 'x okay';
is $first_run->y, 1, 'y okay';
is $first_run->w, 116, 'w okay';
is $first_run->h, 19, 'h okay';
#warn "Done.";
}

{
my $src = <<'_EOC_';
window {
document {
"\n設計不錯，鍵盤手感也不錯。屏幕如很多蛋友所說，容易有指紋印子，在可以當鏡子的界面上，我想這個很難避免。。。\n系統速度也可以，比較實用。\n不過E66的耳機設計非常糟糕，和N73比起來，耳機竟然不能控制音量，不如N73的方便；另外白色的套子很漂亮，可惜，當戴上耳機和繩子后使用皮套非常不便捷。。。敗筆。。\n" w=999 h=50 {
    "" pos=1 len=74 h=16
    "" pos=75 len=72 y=17 w=974 h=16
    "" pos=147 len=4 y=34 w=56 h=16
}
}
_EOC_
my $win = VDOM::Window->new;
$win->parse(\$src);
ok $win, 'built win';
my $doc = $win->document;
my $text = $doc->firstChild;
isa_ok $text, 'VDOM::Text';
is $text->lastChild->nodeValue, '敗筆。。';
}

