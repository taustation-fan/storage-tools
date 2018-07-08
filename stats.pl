#!/usr/bin/env perl
use 5.020;
use strict;
use warnings;
use utf8;
use autodie;
use JSON qw(decode_json);
use Encode qw(decode_utf8);
use lib 'lib';

use Taustation qw(extract_storage_from_html merge_inventory extract_station_name) ;
binmode STDOUT, ':encoding(UTF-8)';

my %all_items;

unless (@ARGV) {
    die "Usage: $0 files+\n";
}

sub storage_usage {
    my $filename = shift;
    open my $in, '<', $filename
        or die "Cannot open $filename for reading: $!";
    while (<$in>) {
        return $1 if /(\d+)%"?\s+of it is being used/;
    }
    return undef;
}

my %usage;
for my $file (@ARGV) {
    my $inventory = extract_storage_from_html($file)->{carried};
    my $station = extract_station_name($file);
    merge_inventory(\%all_items, $inventory, $station);
    $usage{$station} = storage_usage($file);
}

my $total_mass = 0;
my $total_value = 0;
my $total_days_vip = 0;
my %mass_by_station;

for my $item (values %all_items) {
    $total_mass += $item->{quantity} * ($item->{mass} // 0);
    $total_value += $item->{quantity} * ($item->{value} // 0);
    if (my $d = $item->{days}) {
        $total_days_vip += $d * $item->{quantity};
    }
    while (my ($station, $qty) = each  %{ $item->{by_station} } ) {
        $mass_by_station{$station} += ($item->{mass} // 0) * $qty;
    }
}

printf "Total value: %d (sells for %d)\n", int($total_value), int($total_value*0.3);
for my $station (sort keys %mass_by_station) {
    my $usage = $usage{$station};
    printf "    %20s: % 5d kg   (%s%%)%s\n", 
        decode_utf8($station),
        $mass_by_station{$station},
        $usage,
        $usage > 90 ? '   ALMOST FULL' : '',
        ;
}
printf "              TOTAL MASS: % 5d kg\n", int($total_mass);
printf "             Days of VIP: % 5d\n", $total_days_vip;
