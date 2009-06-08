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

    if (!/^\s*("(?:\\.|[^"])*")/gc) {
        die "Syntax error found while parsing text: line $.: string literals expected at the beginning: $_\n";
    }
    $self->{nodeValue} = safe_json_decode($1);
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
            die "Syntax error found while parsing text: line $.: $&\n";
            last;
        } else {
            last;
        }
    }
    $self;
}

sub nodeType {
    $VDOM::Node::TEXT_NODE;
}

1;
