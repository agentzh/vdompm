#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";
use VDOM;

my $json_xs = JSON::XS->new;

my $infile = shift or
    die "Usage: $0 <infile>\n";

#while (1) {

open my $in, $infile or
    die "Can't open $infile for reading: $!\n";
my $begin = time;
my $win = VDOM::Window->new->parse_file($in);
close $in;

my @texts = get_text_nodes($win->document->body);
my $text_node_count = @texts;

my @groups;
my $text_run_count = 0;
for my $text (@texts) {
    if (!$text->childNodes) {
        push @groups, [
            { x => $text->offsetX,
              y => $text->offsetY,
              w => $text->offsetWidth,
              h => $text->offsetHeight,
              borderColor => 'green',
              desc => $text->nodeValue,
              title => 'TEXT NODE',
          }];
        $text_run_count++;
        next;
    }
    my @group;
    for my $child ($text->childNodes) {
        push @group, {
            x => $child->offsetX,
            y => $child->offsetY,
            w => $child->offsetWidth,
            h => $child->offsetHeight,
            borderColor => 'green',
            desc => $child->nodeValue,
            title => 'TEXT RUN',
        };
        $text_run_count++;
    }
    push @groups, \@group;
}

my $summary = <<_EOC_;
Text node count: $text_node_count
Text run count: $text_run_count
_EOC_

my $annotate_res = {
    summary => $summary,
    groups => \@groups,
    program => "Mark Text Runs",
};

my $outfile = $infile . '.res';
open my $out, ">$outfile" or
    die "Cannot open $outfile for writing: $!\n";
print $out Encode::encode('utf8', $json_xs->encode($annotate_res));
close $out;

sub get_text_nodes {
    my $node = shift;
    if ($node->nodeType == $VDOM::Node::TEXT_NODE) {
        return $node;
    } else {
        my @ret;
        for my $child ($node->childNodes) {
            push @ret, get_text_nodes($child);
        }
        return @ret;
    }
}

