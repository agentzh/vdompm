package VDOM::Document;

use strict;
use warnings;

use base 'VDOM::Element';
#__PACKAGE__->mk_accessors(qw{
#width height body title
#});
use Class::XSAccessor
    accessors => {
        width => 'width',
        height => 'height',
        body => 'body',
        title => 'title',
    };

sub new {
    my $proto = ref $_[0] ? ref shift : shift;
    my $self = bless {
    }, $proto;
    if (@_) {
        Scalar::Util::weaken(
            $self->{_ownerWindow} = $_[0] )
    }

    $self;
}

sub getElementById {
    shift->_getElementById(@_);
}

# "If this property is used on a node that is itself a document, the result is NULL."
sub ownerDocument {
    undef;
}

sub parse_line {
    my ($self, $rsrc) = @_;
    my $elem = VDOM::Element->new->parse_line($rsrc);
    if ($elem->tagName ne 'document') {
        die "Syntax error while parsing document node: Line $.: $$rsrc\n";
    }
    while (my ($key, $val) = each %$elem) {
        if ($key !~ /^_/) {
            $self->{$key} = $val;
        }
    }
    #%$self = %$win;
    $self;
}

sub childNodes {
    my $self = shift;
    for my $child (@_) {
        #warn "child: ", $child->tagName;
        if ($child->tagName eq 'BODY') {
            $self->{body} = $child;
            last;
        }
    }
    return $self->SUPER::childNodes(@_);
}

sub nodeType {
    $VDOM::Node::DOCUMENT_NODE;
}

1;
