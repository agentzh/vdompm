package VDOM::Window;

use strict;
use warnings;

#use Smart::Comments;
use VDOM::Document;
use VDOM::Element;

use base 'VDOM::Element';

use Class::XSAccessor
    accessors => {
        location => 'location',
        scrollMaxX => 'scrollMaxX',
        scrollMaxY => 'scrollMaxY',
        innerWidth => 'innerWidth',
        innerHeight => 'innerHeight',
        outerWidth => 'outerWidth',
        outerHeight => 'outerHeight',
    };

#__PACKAGE__->mk_accessors(qw{
#location scrollMaxX scrollMaxY innerWidth innerHeight
#outerWidth outerHeight
#});

sub new {
    my $proto = ref $_[0] ? ref shift : shift;
    bless {
    }, $proto;
}

*fromVdom = \&parse;

sub parse {
    my ($self, $rsrc) = @_;
    open my $in, '<', $rsrc;
    $self->parse_file($in);
    $self;
}

sub parse_line {
    my ($self, $rsrc) = @_;
    my $win = VDOM::Element->new->parse_line($rsrc);
    if ($win->tagName ne 'window') {
        die "window node must be the root.\n";
    }

=begin comment

    while (my ($key, $val) = each %$win) {
        if (substr($key, 0, 1) ne '_') {
            #warn "KEY: $key\n";
            $self->{$key} = $val;
        }
    }

=cut

    %$self = %$win;
    #undef $self->{_parentNode};
    $self;
}

sub host {
    my ($self) = @_;
    if (exists $self->{host}) {
        return $self->{host};
    } else {
        my $loc = $self->location;
        if ($loc && $loc =~ m{^\w+://([^/:]+)}) {
            $self->{host} = $1;
            return $1;
        }
        $self->{host} = undef;
        undef;
    }
}

sub document {
    my $self = shift;
    if (@_) {
        $self->{_doc} = shift;
    } else {
        return $self->{_doc};
    }
}

sub parse_file {
    my ($self, $in) = @_;
    my $line;
    while ($line = <$in>) {
        last if ($line !~ /^\s*$/);
    }
    if (!$line) {
        die "Syntax error: input empty.\n";
    }
    $self->parse_line(\$line);

    while ($line = <$in>) {
        last if ($line !~ /^\s*$/);
    }
    if (!$line) {
        die "No document node specified.\n";
    }

    my $doc = VDOM::Document->new($self)->parse_line(\$line);
    $doc->parentNode($self);
    $self->document($doc);
    #warn "exiting...\n"; return $self;

    my @parent = ($doc, $self);
    my @children = ([], $self->{_childNodes});
    VDOM::Element->fromVdom($in, $self, $doc, \@parent, \@children);
    $self;
}

sub DESTROY {
    my $self = $_[0];
    #cleanup($self->document->body);
    #cleanup($self->document);
    #cleanup($self->{_document});
    #cleanup($self);
}

sub delete {
    my $self = shift;
    $self->document->delete;
    $self->SUPER::delete;
}

1;
