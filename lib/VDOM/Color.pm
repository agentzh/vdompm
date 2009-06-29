package VDOM::Color;

use strict;
use warnings;

use Carp qw( croak );
use Class::XSAccessor
    getters => {
        r => 'r',
        g => 'g',
        b => 'b',
    };

sub new {
    my $class = ref $_[0] ? ref shift : shift;
    my $color = shift or
        die "No color rgb string specified.\n";
    my ($r, $g, $b);
    if ($color =~ m{^
            \s* rgb \s* \(
                \s* (\d+) \s* , \s* (\d+) \s* , \s* (\d+) \s*
                \) \s* $}xi) {
        ($r, $g, $b) = ($1, $2, $3);
    } else {
        croak "Invalid RGB color: $color\n";
    }
    bless {
        r => $r,
        g => $g,
        b => $b,
    }, $class;
}

sub like_grey {
    my $self = shift;
    return $self->{r} == $self->{g} && $self->{g} == $self->{b} &&
            $self->{r} >= 100 && $self->{r} <= 200;
}

sub like_red {
}

sub to_string {
    my $self = shift;
    'rgb(' . $self->r . ', ' . $self->g . ', ' . $self->b . ')';
}

1;

