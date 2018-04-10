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

use Taustation qw(extract_storage_from_html merge_inventory);
binmode STDOUT, ':encoding(UTF-8)';

my $csv = Text::CSV_XS->new({binary => 1});
my %all_items;

unless (@ARGV) {
    die "Usage: $0 files+\n";
}

for my $file (@ARGV) {
    my $inventory = extract_storage_from_html($file)->{carried};
    merge_inventory(\%all_items, $inventory);
}

# removed: 
# bonds
my @attrs = qw(quantity type name description tier rarity mass value hand_to_hand accuracy piercing impact energy);


$csv->say(*STDOUT, \@attrs);

my @sorted = sort { 
    0
    || $a->{type} cmp $b->{type}
    || $a->{tier} <=> $b->{tier}
    || $a->{name} cmp $b->{name}
} values %all_items;

for my $item (@sorted) {
    $csv->say(*STDOUT, [map $_ // '', @{$item}{@attrs}]);
}
