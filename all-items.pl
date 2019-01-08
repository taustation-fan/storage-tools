#!/usr/bin/env perl
use 5.020;
use strict;
use warnings;
use utf8;
use autodie;
use JSON qw(encode_json);
use Text::CSV_XS;
use Data::Dumper;
use lib 'lib';

use Taustation qw(extract_storage_from_html merge_inventory extract_item_from_html);
binmode STDOUT, ':encoding(UTF-8)';

my $csv = Text::CSV_XS->new({binary => 1});
my %storage_items;

unless (@ARGV) {
    @ARGV = reverse glob 'storage/storage-*.html';
}

for my $file (@ARGV) {
    my $inventory = extract_storage_from_html($file)->{carried};
    merge_inventory(\%storage_items, $inventory);
}
my @other_items;

for my $filename (glob 'items/*.html') {
    push @other_items, extract_item_from_html($filename);

}


# removed: 
# bonds
my @attrs = qw(type name description tier rarity mass value weapon_type is_long_range accuracy piercing impact energy);

$csv->say(*STDOUT, \@attrs);

my @sorted = sort { 
    0
    || $a->{type} cmp $b->{type}
    || $a->{tier} <=> $b->{tier}
    || $a->{name} cmp $b->{name}
} grep { state $seen; !$seen->{$_->{name}}++ } values(%storage_items), @other_items;

{
    my %slug_to_name;
    $slug_to_name{$_->{slug}} = $_->{name} for @sorted;
    open my $OUT, '>:', '_items.json'
        or die "Cannot write _items.json: $!";
    print $OUT encode_json(\%slug_to_name);
    close $OUT;
}

for my $item (@sorted) {
    $csv->say(*STDOUT, [(map $_ // '', @{$item}{@attrs})]);
}
