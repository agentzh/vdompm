package VDOM::Element;

use strict;
use warnings;

use VDOM::Util qw( safe_json_decode );
use Scalar::Util qw( weaken );

use base 'VDOM::Node';
__PACKAGE__->mk_accessors(qw{
    id className href name
    title alt src
    numericFontSize numericFontWeight
});

our %NumericFontWeight = (
    bolder  => 900,
    bold    => 700,
    normal  => 400,
    lighter => 100,
);

sub new {
    my $class = ref $_[0] ? ref shift : shift;
    #$self->{_childNodes} = [];
    my $self = bless {
    }, $class;
    if (@_) {
        my $parent = shift;
        if (defined $parent) {

=begin comment
            while (my ($key, $val) = each %$parent) {
                if ($key !~ /^_/) {
                    #warn "KEY: $key\n";
                    $self->{$key} = $val;
                }
            }
=cut

            %$self = %$parent;
            $self->parentNode($parent);
            $self->{_child_ind} = shift;
            if (@_) {
                Scalar::Util::weaken(
                    $self->{_ownerWindow} = $_[0] )
            }
            if (@_) {
                Scalar::Util::weaken(
                    $self->{_ownerDocument} = $_[1] )
            }
        }
    }
    $self;
}

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

sub childNodes {
    my $self = shift;
    if (@_) {
        #warn $self;
        #for my $ref (@_) {
        #weaken($ref);
        #}
        $self->{_childNodes} = [@_];
    } else {
        my $val = $self->{_childNodes};
        return $val ? @$val : ();
    }
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

sub numericFontWeight {
    my $self = shift;
    my $fontWeight = $self->{fontWeight};
    if ($fontWeight =~ /\d+/) {
        return $&;
    } else {
        return $NumericFontWeight{$fontWeight} || 0;
    }
}

sub numericFontSize {
    my $self = shift;
    my $fontSize = $self->{fontSize};
    if ($fontSize =~ /\d+/) {
        return $&;
    } else {
        die "fontSize not numerical: $fontSize\n";
    }
}

1;
