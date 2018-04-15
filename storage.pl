#!/usr/bin/env perl
use 5.020;
use strict;
use warnings;
use utf8;
use autodie;
use JSON qw(decode_json);
use Text::CSV_XS;
use Data::Dumper;
use lib 'lib';

use Taustation qw(extract_storage_from_html merge_inventory extract_station_name);
binmode STDOUT, ':encoding(UTF-8)';

my $csv = Text::CSV_XS->new({binary => 1});
my %all_items;

unless (@ARGV) {
    @ARGV = glob 'storage-*.html';
}

my @stations;
for my $file (@ARGV) {
    my $inventory = extract_storage_from_html($file)->{carried};
    my $station = extract_station_name($file);
    push @stations, $station if $station;
    merge_inventory(\%all_items, $inventory, $station);
}

@stations = sort @stations;

# removed: 
# bonds
my @attrs = qw(quantity type name description tier rarity mass value hand_to_hand accuracy piercing impact energy);


$csv->say(*STDOUT, [@attrs, @stations]);

my @sorted = sort { 
    0
    || $a->{type} cmp $b->{type}
    || $a->{tier} <=> $b->{tier}
    || $a->{name} cmp $b->{name}
} values %all_items;

for my $item (@sorted) {
    my @quantity_at_stations = map $_ // 0, @{$item->{by_station}}{@stations};
    $csv->say(*STDOUT, [(map $_ // '', @{$item}{@attrs}), @quantity_at_stations]);
}
