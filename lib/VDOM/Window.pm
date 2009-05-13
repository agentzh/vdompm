package VDOM::Window;

use strict;
use warnings;

#use Smart::Comments;
use VDOM::Document;
use VDOM::Element;

use base 'VDOM::Element';

__PACKAGE__->mk_accessors(qw{
    location scrollMaxX scrollMaxY innerWidth innerHeight
    outerWidth outerHeight
});

sub new {
    my $proto = ref $_[0] ? ref shift : shift;
    bless {
    }, $proto;
}

sub parse {
    my ($self, $rsrc) = @_;
    open my $in, '<', $rsrc;
    $self->parse_file($in);
    $self;
}

sub parse_line {
    my ($self, $rsrc) = @_;
    my $win = VDOM::Element->new->parse_line($rsrc);
    if ($win->tagName ne 'window') {
        die "window node must be the root.\n";
    }

=begin comment

    while (my ($key, $val) = each %$win) {
        if (substr($key, 0, 1) ne '_') {
            #warn "KEY: $key\n";
            $self->{$key} = $val;
        }
    }

=cut

    %$self = %$win;
    #undef $self->{_parentNode};
    $self;
}

sub document {
    my $self = shift;
    if (@_) {
        $self->{_doc} = shift;
    } else {
        return $self->{_doc};
    }
}

sub parse_file {
    my ($self, $in) = @_;
    my $line;
    while ($line = <$in>) {
        last if ($line !~ /^\s*$/);
    }
    if (!$line) {
        die "Syntax error: input empty.\n";
    }
    $self->parse_line(\$line);

    while ($line = <$in>) {
        last if ($line !~ /^\s*$/);
    }
    if (!$line) {
        die "No document node specified.\n";
    }

    my $doc = VDOM::Document->new->parse_line(\$line);
    $doc->parentNode($self);
    $self->document($doc);
    #warn "exiting...\n"; return $self;

    my @parent = ($doc, $self);
    my @children = ([], $self->{_childNodes});
    while (<$in>) {
        my $node;
        chomp;
        s/^\s+//;
        next if $_ eq '';
        my $first = substr($_, 0, 1);

        ### parsing: $_
        if ($first eq '"') {
            ### Found text node...

            my $lastNode;
            if ($children[0] and $lastNode = $children[0][-1] and
                    $lastNode->nodeType == $VDOM::Node::TEXT_NODE) {
                $lastNode->parse_one_more_line(\$_);
            } else {
                my $child_index = @{ $children[0] };
                push @{ $children[0] },
                    VDOM::Text->new($parent[0], $child_index, $doc)
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
            $parent[0]->childNodes(@$children);
            shift @children;
            shift @parent;
            ### @children
            ### @parent
        } else { # must be an element
            ### found an element node...
            my $child_index = @{ $children[0] };
            my $node = VDOM::Element->new($parent[0], $child_index, $doc)
                    ->parse_line(\$_);
            push @{ $children[0] }, $node;
            unshift @parent, $node;
            unshift @children, [];
            ### @children
            ### @parent
        }
    }
    $self;
}

sub DESTROY {
    my $self = $_[0];
    #cleanup($self->document->body);
    #cleanup($self->document);
    #cleanup($self->{_document});
    #cleanup($self);
}

sub delete {
    my $self = shift;
    $self->document->delete;
    $self->SUPER::delete;
}

1;
