#!/usr/bin/env perl
use 5.020;
use strict;
use warnings;
use utf8;
use autodie;
use JSON qw(decode_json);
use Data::Dumper;
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

# removed: 
# bonds
my @attrs = qw(quantity type name description tier rarity mass value hand_to_hand accuracy piercing impact energy);


my %wanted = (armor => 1, weapon => 1);

my @sorted = sort { 
    0
    || $a->{type} cmp $b->{type}
    || fc($a->{name}) cmp fc($b->{name})
} grep { $wanted{ lc($_->{type}) } } values %all_items;

for my $item (@sorted) {
    say join "\t", $item->{type}, $item->{name};
}
