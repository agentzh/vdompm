package VDOM::Element;

use strict;
use warnings;

use VDOM::Util qw( safe_json_decode );
use Scalar::Util qw( weaken );
use base 'VDOM::Node';

use Class::XSAccessor
    accessors => {
        id => 'id',
        className => 'className',
        href => 'href',
        name => 'name',
        title => 'title',
        alt => 'alt',
        src => 'src',
    };

#__PACKAGE__->mk_accessors(qw{
    #id className href name
    #title alt src
#});

sub getElementsByTagName {
    my ($self, $tagName) = @_;
    my @elem;
    for my $child (@{ $self->{_childNodes} }) {
        if ($child->nodeType == $VDOM::Node::ELEMENT_NODE) {
            if ($child->{tagName} eq uc($tagName)) {
                push @elem, $child;
            }
            push @elem, $child->getElementsByTagName($tagName);
        }
    }
    @elem;
}

sub parse_line {
    my ($self, $rsrc) = @_;
    local *_ = $rsrc;
    #Encode::_utf8_off($_);
    if (!/^\s*(\S+)/gc) {
        die "Syntax error found while parsing element: line $.: tag names expected at the beginning: $_\n";
    }
    $self->{tagName} = $1;
    while (1) {
        if (/\G \s* (\w+) \s* = \s* ( -? \d+ | " (?: \\. | [^"] )* " )/gcx) {
            #warn "$1 => [$2]";
            my ($key, $json_val) = ($1, $2);
            if ($json_val =~ /^"/) {
                $self->{$key} = safe_json_decode($json_val);
            } else {
                $self->{$key} = $json_val;
            }
        } elsif (/\G \s* { \s* $/gcx) {
            last;
        } elsif (/\G \s* (.+) /gcx) {
            die "Syntax error found while parsing element: line $.: $&\n";
            last;
        } else {
            die "Unexpected end of line: line $.: $_\n";
        }
    }
    $self;
}

sub nodeType {
    $VDOM::Node::ELEMENT_NODE;
}

sub _getElementById {
    my ($self, $id) = @_;
    my @elem;
    for my $child (@{ $self->{_childNodes} }) {
        if ($child->nodeType == $VDOM::Node::ELEMENT_NODE) {
            if (defined $child->{id} && $child->{id} eq $id) {
                return $child;
            }
            if (my $elem = $child->_getElementById($id)) {
                return $elem;
            }
        }
    }
    @elem;
}

sub fromVdom {
    my ($class, $src, $win, $doc, $parents, $children) = @_;
    my $in;
    if (ref $src) {
        $in = $src;
    } else {
        #warn "Found handle: $in\n";
        open $in, '<', \$src;
    }
    my @parent = defined $parents ? @$parents : ();
    my @children = defined $children ? @$children : ([]);
    while (<$in>) {
        my $node;
        chomp;
        s/^\s+//;
        next if $_ eq '';
        my $first = substr($_, 0, 1);

        ### parsing: $_
        if ($first eq '"') {
            ### Found text node...

            if (/{\s*$/) {
                my $child_index = @{ $children[0] };
                my $node = VDOM::Text->new($parent[0], $child_index, $win, $doc)
                        ->parse_line(\$_);
                push @{ $children[0] }, $node;
                unshift @parent, $node;
                unshift @children, [];
            } else {
                my $child_index = @{ $children[0] };
                push @{ $children[0] },
                    VDOM::Text->new($parent[0], $child_index, $win, $doc)
                        ->parse_line(\$_);
            }
            ### @children
            ### @parent
        } elsif ($first eq '}') {
            ### closing node...
            if (!@parent) {
                die "Syntax error in VDOM: Line $.: Unexpected } found.\n";
            }
            my $children = $children[0];
            if (defined $parent[0]) {
                $parent[0]->childNodes(@$children);
            }
            shift @children;
            shift @parent;
            ### @children
            ### @parent
        } else { # must be an element
            ### found an element node...
            my $child_index = @{ $children[0] };
            my $node = VDOM::Element->new($parent[0], $child_index, $win, $doc)
                    ->parse_line(\$_);
            push @{ $children[0] }, $node;
            unshift @parent, $node;
            unshift @children, [];
            ### @children
            ### @parent
        }
    }

}

1;
