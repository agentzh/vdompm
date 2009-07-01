package VDOM::Node;

#use Smart::Comments::JSON '##sel';
use strict;
use warnings;

use vars qw($AUTOLOAD);
#use base qw( Class::Accessor::Fast );

use Scalar::Util;
use Class::XSAccessor
    accessors => {
        x => 'x',
        y => 'y',
        w => 'w',
        h => 'h',
        color => 'color',
        backgroundColor => 'backgroundColor',
        fontSize => 'fontSize',
        fontWidth => 'fontWidth',
        fontStyle => 'fontStyle',
        fontWeight => 'fontWeight',
        tagName => 'tagName',
        fontFamily => 'fontFamily',
        nodeValue => 'nodeValue',
    };

#__PACKAGE__->mk_accessors(qw{
    #x y w h color backgroundColor
    #fontSize fontWidth fontStyle fontWeight tagName fontFamily
    #nodeValue
#});

sub VDOM::Node::offsetX;
sub VDOM::Node::offsetY;
sub VDOM::Node::offsetWidth;
sub VDOM::Node::offsetHeight;

# create aliases for (short-term) backward compatibility (these are deprecated now):
*VDOM::Node::offsetX = \&x;
*VDOM::Node::offsetY = \&y;
*VDOM::Node::offsetWidth = \&w;
*VDOM::Node::offsetHeight = \&h;

our $ELEMENT_NODE  = 1;
our $TEXT_NODE     = 3;
our $DOCUMENT_NODE = 9;
our $COLLECTION_NODE = 100;
our $CacheTextContent = 0;

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
            delete $self->{id};
            delete $self->{className};
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

sub ownerWindow {
    my $self = shift;
    if (@_) {
        Scalar::Util::weaken(
            $self->{_ownerWindow} = shift
        );
        $self;
    } else {
        return $self->{_ownerWindow};
    }
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

sub packedTextContent {
    my $self = shift;
    (my $txt = $self->textContent) =~ s/^\s+|\s+$//gs;
    $txt =~ s/\s\s+/ /g;
    $txt;
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
    } elsif ($self->tagName eq 'A' && $self->h < 100) {
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


sub attr {
    my $self = shift;
    if (@_ == 1) {
        return $self->getAttribute(@_);
    }
    return $self->setAttribute(@_);
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

sub inflated {
    my $self = shift;
    my $parent = $self;
    while ($parent) {
        my $new_parent = $parent->parentNode;
        if ($new_parent->childNodes != 1 ||
            $new_parent->x > $self->x ||
            $new_parent->y > $self->y ||
            $new_parent->h < $self->h ||
            $new_parent->w < $self->w) {
            last;
        }
        $parent = $new_parent;
    }
    return {
        x => $parent->x,
        y => $parent->y,
        w => $parent->w,
        h => $parent->h,
    };
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

sub simple_selector {
    my $self = shift;
    while (defined $self && $self->nodeType == $VDOM::Node::TEXT_NODE) {
        $self = $self->parentNode;
    }
    my $selector;
    while (1) {
        last if !defined $self;
        my $id = $self->id;
        my $tag = $self->tagName;
        my $locator = $tag;
        if (defined $selector) {
            $selector = $locator . '>' . $selector;
        } else {
            $selector = $locator;
        }
        last if $tag eq 'BODY';
        $self = $self->parentNode;
    }
    return $selector;
}

sub selector {
    my $self = shift;
    while (defined $self && $self->nodeType == $VDOM::Node::TEXT_NODE) {
        $self = $self->parentNode;
    }
    #warn "HERE!";
    my $selector;
    while (1) {
        last if !defined $self;
        my $id = $self->id;
        my $tag = $self->tagName;
        my $class_name = $self->className;
        ##sel $id $tag $class_name
        if (defined $class_name) {
            $class_name = (split /\s+/, $class_name)[0];
        }
        my $locator = $tag;
        if (defined $id && $id =~ /^[-\w]+$/) {
            $locator .= "#$id";
        } elsif (defined $class_name && $class_name =~ /^[-\w]+$/) {
            $locator .= ".$class_name";
        }
        if (defined $selector) {
            $selector = $locator . '>' . $selector;
        } else {
            $selector = $locator;
        }
        last if $tag eq 'BODY';
        $self = $self->parentNode;
    }
    return $selector;
}

1;
