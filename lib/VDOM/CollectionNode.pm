package VDOM::CollectionNode;

use strict;
use warnings;
use base 'VDOM::Node';

#use Smart::Comments::JSON '##';
#use base qw( Class::Accessor::Fast );
use List::MoreUtils qw( uniq );
use Class::XSAccessor
    accessors => {
        x => 'x',
        y => 'y',
        w => 'w',
        h => 'h',
   };


sub VDOM::CollectionNode::offsetX;
sub VDOM::CollectionNode::offsetY;
sub VDOM::CollectionNode::offsetWidth;
sub VDOM::CollectionNode::offsetHeight;

*VDOM::CollectionNode::offsetX = \&x;
*VDOM::CollectionNode::offsetY = \&y;
*VDOM::CollectionNode::offsetWidth = \&w;
*VDOM::CollectionNode::offsetHeight = \&h;

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
    my $self = shift;
    push @{ $self->{_elems} }, @_;
    $self->compute_box;
}

sub nodeType {
    $VDOM::Node::COLLECTION_NODE;
}

sub inflated {
    my $self = shift;
    my ($min_left, $min_top, $max_right, $max_bottom);
    #if ($self->size == 0) {
        #die "0 size!\n";
        #}
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

sub color {
    my $self = shift;
    my @color;
    for my $elem ($self->elems) {
        push @color, $elem;
    }
    return uniq @color;
}

sub compute_box {
    my $self = shift;

    my $elems = $self->elems;
    my ($min_left, $min_top, $max_right, $max_bottom);
    for my $elem (@$elems) {
        if (!defined $min_top || $elem->x < $min_left) {
            $min_left = $elem->x;
        }
        if (!defined $min_top || $elem->y < $min_top) {
            $min_top = $elem->y;
        }
        if (!defined $max_right || $elem->x + $elem->w > $max_right) {
            $max_right = $elem->x + $elem->w;
        }
        if (!defined $max_bottom || $elem->y + $elem->h > $max_bottom) {
            $max_bottom = $elem->y + $elem->h;
        }
    }

    $self->{x} = $min_left;
    $self->{y} = $min_top,
    $self->{w} = $max_right ? $max_right - $min_left : 0,
    $self->{h} = $max_bottom ? $max_bottom - $min_top : 0,
}

sub parentNode {
    my $self = shift;

    my $first = $self->first;
    return $first ? $first->parentNode : undef;
}

sub getElementsByTagName {
}

sub nextElementSibling {
}

sub childNodes {
    my $elems = $_[0]->{_elems};
    wantarray ? @$elems : $elems;
}

sub ownerDocument {
    my $self = shift;

    my $first = $self->first;
    return $first ? $first->ownerDocument : undef;
}

sub ownerWindow {
    my $self = shift;

    my $first = $self->first;
    return $first ? $first->ownerWindow : undef;
}

sub textContent {
    my ($self) = @_;
    return join '', map { $_->textContent } @{ $self->{_elems} };
}

1;
