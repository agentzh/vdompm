package VDOM::Text;

use strict;
use warnings;
use base 'VDOM::Node';
use Encode qw( _utf8_off );
use JSON::XS ();

our $JsonXs = JSON::XS->new->utf8->allow_nonref;

sub parse_line {
    my ($self, $rsrc) = @_;
    local *_ = $rsrc;
    Encode::_utf8_off($_);
    $self->{nodeValue} = $JsonXs->decode($_);
    $self;
}

sub parse_one_more_line {
    my ($self, $rsrc) = @_;
    local *_ = $rsrc;
    Encode::_utf8_off($_);
    $self->{nodeValue} .= $JsonXs->decode($_);
    $self;
}

sub nodeType {
    $VDOM::Node::TEXT_NODE;
}

1;
