#!/usr/bin/env perl
use 5.020;
use strict;
use warnings;
use utf8;
use autodie;
use JSON qw(decode_json);
use lib 'lib';

use Taustation qw(extract_storage_from_html merge_inventory);
binmode STDOUT, ':encoding(UTF-8)';

my %all_items;

unless (@ARGV) {
    die "Usage: $0 files+\n";
}

for my $file (@ARGV) {
    my $inventory = extract_storage_from_html($file)->{carried};
    merge_inventory(\%all_items, $inventory);
}

my $total_mass = 0;
my $total_value = 0;

for my $item (values %all_items) {
    $total_mass += $item->{quantity} * $item->{mass};
    $total_value += $item->{quantity} * $item->{value};
}

printf "Total mass: %d kg\n", int($total_mass);
printf "Total value: %d (sells for %d)\n", int($total_value), int($total_value/3);
