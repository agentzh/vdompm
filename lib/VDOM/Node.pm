package VDOM::Node;

#use Smart::Comments::JSON '##sel';
use strict;
use warnings;

use vars qw($AUTOLOAD);
#use base qw( Class::Accessor::Fast );

use Scalar::Util qw( refaddr );
use List::MoreUtils qw( firstidx );
use List::Util qw( first );

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
        elem => $parent,
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

sub simpleSelector {
    my ($self, $root) = @_;
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
        last if $tag eq 'BODY' ||
            (defined $root && refaddr $self == refaddr $root);
        $self = $self->parentNode;
    }
    return $selector;
}

sub selector {
    my ($self, $root) = @_;
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
            my @class_names = grep { /^[-A-Za-z_]+$/ }
                split /\s+/, $class_name;
            $class_name = shift @class_names;
        }
        my $locator = $tag;
        if (defined $id && $id =~ /^[-A-Za-z_]+$/) {
            $locator .= "#$id";
        } elsif (defined $class_name) {
            $locator .= ".$class_name";
        }
        if (defined $selector) {
            $selector = $locator . '>' . $selector;
        } else {
            $selector = $locator;
        }
        last if $tag eq 'BODY' ||
            (defined $root && refaddr $self == refaddr $root);
        $self = $self->parentNode;
    }
    return $selector;
}

sub getElementsBySelector {
    my ($self, $selector) = @_;
    $selector =~ s/\s+//g;
    my @pats = split />/, $selector;
    for my $pat (@pats) {
        if ($pat =~ /^(\w+)$/) {
            $pat = {
                tag => $1,
            };
        } elsif ($pat =~ /^(\w+)\#([-\w]+)$/) {
            $pat = {
                tag => $1,
                id => $2,
            };
        } elsif ($pat =~ /^(\w+)\.([-\w]+)$/) {
            $pat = {
                tag => $1,
                class => $2,
            };
        } else {
            die "Syntax error found in the selector: $pat\n";
        }
    }
    ##sel @pats
    return $self->getElementsBySelectorHelper(\@pats);
}

sub getElementsBySelectorHelper {
    my ($self, $pats) = @_;
    if (!@$pats || $self->nodeType == $VDOM::Node::TEXT_NODE) {
        return ();
    }
    if ($self->matchSelector($pats->[0])) {
        ##sel matched elem: $self->tagName
        my ($pat, @sub_pats) = @$pats;
        if (!@sub_pats) {
            return ($self);
        }
        my @res;
        for my $child ($self->childNodes) {
            push @res, $child->getElementsBySelectorHelper(\@sub_pats);
        }
        return @res;
    }
    return ();
}

sub matchSelector {
    my ($self, $pat) = @_;
    return 0 if defined $pat->{tag} && $self->tagName ne $pat->{tag} ||
        defined $pat->{id} &&
            (!defined $self->id || $self->id ne $pat->{id}) ||
        defined $pat->{class} &&
            (!defined $self->className || $self->className !~ /\b\Q$pat->{class}\E\b/);
    return 1;
}

sub xpath {
    my ($self) = @_;

    if (exists $self->{xpath}) {
        return $self->{xpath};
    } else {
        # compute
        my $xpath = '';
        my $curr = $self;
        my $parent = $self->parentNode;
        while ($parent) {
            my $tag = $curr->tagName;
            my $curr_xpath = '/' . $tag;

            my $idx = firstidx { $_ == $curr } grep {$_->tagName eq $tag} $parent->childNodes;
            if ($idx > 0) {
                $curr_xpath .= "[$idx]";
            }
            $xpath = $curr_xpath . $xpath;

            $curr = $parent;
            $parent = $parent->parentNode;
        }
        $self->{xpath} = $xpath;
        $xpath
    }
}

sub getNodeByXpath {
    my ($self, $xpath) = @_;

    my $node;
    my $rel_xpath;
    if ($xpath =~ /^\/(?:document|html)\/(.*)/i) {
        $node = $self->ownerDocument;
        $rel_xpath = $1;
    } else { # relative
        $node = $self;
        $rel_xpath = $xpath;
    }

    my @paths = split /\//, $rel_xpath;
    for my $path (@paths) {
        next if !$path;

        my ($tag, $idx) = split /[\[\]]/, $path;
        $tag = uc $tag;

        $node = first {$_->tagName eq $tag &&
                    (!$idx || $idx-- == 0) }
                $node->childNodes;
        return $node if !$node;
    }

    return $node;
}

1;
