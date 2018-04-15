#!/usr/bin/env perl
use 5.020;
use strict;
use warnings;
use utf8;
use autodie;
use JSON qw(decode_json);
use Text::CSV_XS;
use Text::Table;
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

my @armor = grep { lc($_->{type}) eq 'armor' } values %all_items;
my @damages = qw(piercing impact energy);

sub classify {
    my $item = shift;

    return join '/', $item->{tier}, grep { $item->{$_} } @damages;
}
my %grouped;
for my $item (@armor) {
    push @{ $grouped{classify($item)} }, $item;
}

my $comparison_table = Text::Table->new('tier', 'worse', 'better');

for my $items (sort { $a->[0]{tier} <=> $b->[0]{tier} } values %grouped) {
    next if @$items <= 1;
    say "\n\n";

    my $t = Text::Table->new("Name", 'Mass', @damages);
    my @items = reverse sort {$b->{mass} <=> $a->{mass}} @$items;
    for my $w (@items)  {
        $t->add($w->{name}, $w->{mass}, @{$w}{@damages});
    }
    say $t;
    
    for my $idx (1..$#items) {
        my $w = $items[$idx];
        for my $comp (@items[0...$idx-1]) {
            if (
                    $w->{piercing} <= $comp->{piercing}
                 && $w->{impact} <= $comp->{impact}
                 && $w->{energy} <= $comp->{energy}
            ) {
                say $w->{name}, "\t is worse than ", $comp->{name};
                $comparison_table->add($w->{tier}, $w->{name}, $comp->{name});
                last;
            }
        }

    }
}

say "\n";
say $comparison_table;

# use Data::Dumper; warn Dumper \%grouped;


