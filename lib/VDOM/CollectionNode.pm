package VDOM::CollectionNode;

use strict;
use warnings;
use base 'VDOM::Node';

#use Smart::Comments::JSON '##';
use base qw( Class::Accessor::Fast );

sub new {
    my $class = ref $_[0] ? ref shift : shift;
    return bless {
        _elems => [],
    }, $class;
}

sub first {
    $_[0]->{_elems}->[0];
}

sub last {
    $_[0]->{_elems}->[-1];
}

sub size {
    scalar @{ $_[0]->{_elems} };
}

sub elems {
    my $elems = $_[0]->{_elems};
    wantarray ? @$elems : $elems;
}

sub add {
    push @{ shift->{_elems} }, @_;
}

sub nodeType {
    $VDOM::Node::COLLECTION_NODE;
}

sub inflated {
    my $self = shift;
    my ($min_left, $min_top, $max_right, $max_bottom);
    for my $elem ($self->elems) {
        my $inflated = $elem->inflated;
        ## $inflated
        if (!defined $min_left || $inflated->{x} < $min_left) {
            $min_left = $inflated->{x};
        }
        if (!defined $min_top || $elem->{y} < $min_top) {
            $min_top = $inflated->{y};
        }
        if (!defined $max_right || $inflated->{x} + $inflated->{w} > $max_right) {
            $max_right = $inflated->{x} + $inflated->{w};
        }
        if (!defined $max_bottom || $inflated->{y} + $inflated->{h} > $max_bottom) {
            $max_bottom = $inflated->{y} + $inflated->{h};
        }
    }
    return {
        x => $min_left,
        y => $min_top,
        w => $max_right - $min_left,
        h => $max_bottom - $min_top,
    };
}

sub textContent {
    my $self = shift;
    my $txt;
    for my $elem ($self->elems) {
        #warn "HERE!";
        $txt .= $elem->textContent;
    }
    $txt;
}

1;
