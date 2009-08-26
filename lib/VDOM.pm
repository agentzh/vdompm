package VDOM;

use strict;
use warnings;

use VDOM::Element;
use VDOM::Document;
use VDOM::Window;
use VDOM::Text;
use VDOM::CollectionNode;
use VDOM::Color;

our $VERSION = '0.010';

1;
__END__

=encoding utf8

=head1 NAME

VDOM - Visual DOM client library for Perl

=head1 SYNOPSIS

    use VDOM;

    open my $in, 'a.vdom' or
        die "Can't open a.vdom for reading: $!\n";
    my $win = VDOM::Window->new->parse_file($in);

    warn "Analyzing webpage ", $win->location;
    my $doc = $win->document;
    warn $doc->width, "x", $doc->height;
    my $body = $doc->body;
    my @text_nodes = get_all_text_nodes($body);
    print map { $_->textContent } @text_nodes;
    for my $node (@text_nodes) {
        print $node->x, " ",
              $node->y, " ",
              $node->w, " ",
              $node->h, " ",
              $node->color, " ",
              $node->fontWeight, " ";
        for my $text_run ($node->childNodes) {
            # extended DOM API for textruns
            print $text_run->x, " ",
                  $text_run->y, " ",
                  $text_run->w, " ",
                  $text_run->h, "\n";
        }
    }

    sub get_all_text_nodes {
        my $node = shift;

        if ($node->nodeType == $VDOM::Node::TEXT_NODE) {
            return ($node);
        }
        my @res;
        for my $child ($node->childNodes) {
            push @res, get_all_text_nodes($child);
        }
    }

=head1 AUTHOR

agentzh (章亦春) C<< <agentzh@yahoo.cn> >>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2009 by Yahoo! China EEEE Works, Alibaba Inc.



