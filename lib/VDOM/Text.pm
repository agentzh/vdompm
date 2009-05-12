package VDOM::Text;

use strict;
use warnings;

use base 'VDOM::Node';

use VDOM::Util qw( safe_json_decode );
use Encode qw( _utf8_off );

sub parse_line {
    my ($self, $rsrc) = @_;
    local *_ = $rsrc;
    Encode::_utf8_off($_);
    $self->{nodeValue} = safe_json_decode($_);
    $self;
}

sub parse_one_more_line {
    my ($self, $rsrc) = @_;
    local *_ = $rsrc;
    Encode::_utf8_off($_);
    $self->{nodeValue} .= safe_json_decode($_);
    $self;
}

sub nodeType {
    $VDOM::Node::TEXT_NODE;
}

1;
