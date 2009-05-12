package VDOM::Util;

use strict;
use warnings;

use JSON::XS ();

use base 'Exporter';
our $JsonXs = JSON::XS->new->utf8->allow_nonref;

our @EXPORT_OK = qw(
    safe_json_decode
);

sub safe_json_decode {
    (my $val = $_[0]) =~ s/[[:cntrl:]]+//g;
    #my $val = shift;
    $JsonXs->decode($val);
}

1;
