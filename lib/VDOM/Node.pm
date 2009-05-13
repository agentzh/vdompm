package VDOM::Node;

#use Smart::Comments;
use strict;
use warnings;

use vars qw($AUTOLOAD);
use base qw( Class::Accessor::Fast );

__PACKAGE__->mk_accessors(qw{
    offsetX offsetY offsetWidth offsetHeight color backgroundColor
    fontSize fontWidth fontStyle fontWeight tagName fontFamily
    nodeValue
});

our $ELEMENT_NODE  = 1;
our $TEXT_NODE     = 3;
our $DOCUMENT_NODE = 9;
our $CacheTextContent = 0;

use Scalar::Util;

sub new {
    my $proto = ref $_[0] ? ref shift : shift;
    my $self = bless {
    }, $proto;
    if (@_) {
        my $parent = shift;
        if (defined $parent) {
            $self->parentNode($parent);
            $self->{_child_ind} = shift;
            if (@_) {
                Scalar::Util::weaken(
                    $self->{_ownerDocument} = $_[0] )
            }
        }
    }
    $self;
}

sub ownerDocument {
    my $self = shift;
    if (@_) {
        Scalar::Util::weaken(
            $self->{_ownerDocument} = shift
        );
        $self;
    } else {
        return $self->{_ownerDocument};
    }
}

sub firstElementChild {
    my $self = shift;
    for my $child (@{ $self->{_childNodes} }) {
        if ($child->nodeType == $VDOM::Node::ELEMENT_NODE) {
            return $child;
        }
    }
    return undef;
}

sub firstChild {
    $_[0]->{_childNodes}->[0];
}

sub lastElementChild {
    my $self = shift;
    for my $child (reverse @{ $self->{_childNodes} }) {
        if ($child->nodeType == $VDOM::Node::ELEMENT_NODE) {
            return $child;
        }
    }
    return undef;
}

sub lastChild {
    $_[0]->{_childNodes}->[-1];
}

sub previousSibling {
    my $self = shift;
    my $ind = $self->{_child_ind};
    ### $ind
    if (defined $ind) {
        if ($ind <= 0) {
            return undef;
        }
        $self->{_parentNode}->{_childNodes}->[$ind - 1];
    } else {
        die "ERROR: No child index defined.\n";
        #m$self->{_parentNode}->{_childNodes}
    }
}

sub nextSibling {
    my ($self) = @_;
    my $ind = $self->{_child_ind};
    if (defined $ind) {
        $self->{_parentNode}->{_childNodes}->[$ind + 1];
    } else {
        die "ERROR: No child index defined.\n";
        #m$self->{_parentNode}->{_childNodes}
    }
}

sub nextElementSibling {
    my ($self) = @_;
    my $ind = $self->{_child_ind};
    if (defined $ind) {
        my $childNodes = $self->{_parentNode}->{_childNodes};
        my $len = @$childNodes;
        my $child;
        while ($ind < $len && defined($child = $childNodes->[$ind + 1])) {
            #warn "Getting child node with index $ind + 1...\n";
            if ($child->nodeType == $VDOM::Node::ELEMENT_NODE) {
                return $child;
            }
            $ind++;
        }
        return undef;
    } else {
        die "ERROR: No child index defined.\n";
        #m$self->{_parentNode}->{_childNodes}
    }
}

sub previousElementSibling {
    my ($self) = @_;
    my $ind = $self->{_child_ind};
    if (defined $ind) {
        my $childNodes = $self->{_parentNode}->{_childNodes};
        my $child;
        while ($ind > 0 && defined($child = $childNodes->[$ind - 1])) {
            #warn "HERE! $ind";
            if ($child->nodeType == $VDOM::Node::ELEMENT_NODE) {
                return $child;
            }
            $ind--;
        }
        return undef;
    } else {
        die "ERROR: No child index defined.\n";
        #m$self->{_parentNode}->{_childNodes}
    }
}

sub textContent {
    my ($self) = @_;
    if ( $CacheTextContent && exists $self->{_cached_text_content} ) {
        return $self->{_cached_text_content};
    }
    if ($self->nodeType == $VDOM::Node::TEXT_NODE) {
        return $self->{nodeValue};
    }
    local *_ = \(join '', map { $_->textContent } @{ $self->{_childNodes} });
    if ($CacheTextContent) {
        $self->{_cached_text_content} = $_;
    }
    return $_;
}

sub textContentWithImgAlt {
    my ($self) = @_;
    if ( $CacheTextContent && exists $self->{_cached_text_content} ) {
        return $self->{_cached_text_content};
    }
    if ($self->nodeType == $VDOM::Node::TEXT_NODE) {
        return $self->{nodeValue};
    }
    if ($self->{tagName} eq 'IMG') {
        my $alt = $self->{alt};
        return defined $alt ? $alt : '';
    }
    local *_ = \(join '', map { $_->textContentWithImgAlt } @{ $self->{_childNodes} });
    if ($CacheTextContent) {
        $self->{_cached_text_content} = $_;
    }
    return $_;
}

# Just like textContent but excluding link texts
sub pureTextContent {
    my ($self) = @_;
    if ($self->nodeType == $VDOM::Node::TEXT_NODE) {
        return $self->nodeValue;
    } elsif ($self->tagName eq 'A' && $self->offsetHeight < 100) {
        return '';
    } else {
        return join '', map { $_->pureTextContent } @{ $self->{_childNodes} };
    }
}

sub parentNode {
    my $self = shift;
    if (@_) {
        my $parent = shift;
        #warn "HERE~~~...\n";
        Scalar::Util::weaken($self->{_parentNode} = $parent);
        $self;
    } else {
        return $self->{_parentNode};
    }
}

sub setAttribute {
    my ($self, $attr, $val) = @_;
    $self->{$attr} = $val;
}

sub getAttribute {
    my ($self, $attr) = @_;
    return $self->{$attr};
}


=pod
sub AUTOLOAD {
    my $self = shift;
    my $meth = $AUTOLOAD;
    if ($meth =~ s/.*:://) {
        #return if $meth eq 'DESTROY';
        if (@_ > 1) {
            die "Property $meth is read-only.\n";
        }
        return $self->{$meth};
    }
}

sub delete {
    my $self = shift;
    if ($self && ref $self) {
        while (my ($key, $val) = each %$self) {
            if (ref $val eq 'ARRAY') {
                for my $n (@$val) {
                    if (defined $n && ref $n && $n->can('delete')) {
                        $n->delete;
                    }
                }
            }
            undef $val;
        }
    }
}
=cut

1;
