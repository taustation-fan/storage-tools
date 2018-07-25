package Taustation;

use strict;
use warnings;
use 5.014;
use utf8;
use JSON qw(decode_json);
use Encode qw(encode_utf8);
use HTML::Entities qw(decode_entities);
use Mojo::DOM;

use Exporter qw(import);

our @EXPORT_OK = qw(extract_storage_from_html merge_inventory extract_station_name extract_item_from_html);

sub extract_station_name {
    my $filename = shift;
    open my $fh, '<:encoding(UTF-8)', $filename
        or die "Cannot open '$filename' for reading: $!\n";
    my $content = do { local $/; <$fh> };
    if ($content =~ m!<span class="station">\s*(.+?)\s*</span>!) {
        my $extracted = encode_utf8 decode_entities("$1");
        if (wantarray) {
            my ($station, $system) = split /, /, $extracted;
            $system =~ s/\s*system\s*$//i;
            return ($station, $system);
        }
        my $station = (split /, /, $extracted)[0];
        return $station;
    }
    return undef;
}

sub extract_storage_from_html {
    my $filename = shift;
    open my $IN, '<', $filename
        or die "Cannot open '$filename' for reading: $!\n";
    while (<$IN>) {
        if ( m/^\s*items: (\{.*\}),?\s*$/) {
            my $json = "$1";
            return decode_json($json);
        }
    }
    die "Cannot extract storage JSON from file '$filename' (not found in file)\n";
}

sub merge_inventory {
    my ($all_items, $to_merge, $station_name) = @_;

    while ( my ($category, $elems) = each %$to_merge ) {
        for my $elem (@$elems) {
            my $slug = $elem->{item}{slug};
            if ($all_items->{ $slug }) {
                $all_items->{ $slug }{ by_station }{ $station_name } += $elem->{quantity}
                    if $station_name;
                $all_items->{ $slug }{ quantity } += $elem->{quantity};
                next;
            }
            my %new;
            if ($category eq 'weapon' || $category eq 'armor') {
                my %type_specific = %{ $elem->{item}{"item_component_$category"} };
                while (my ($k, $v) = each %type_specific) {
                    $new{ $k =~ s/_damage//r } = $v;
                }
                if (defined $new{weapon_type}) {
                    $new{is_long_range} = $new{weapon_type}{is_long_range};
                    $new{weapon_type}   = $new{weapon_type}{name};
                }
            }
            elsif ($category eq 'vip') {
                my $slug = $elem->{item}{slug};
                $new{days} = +(split /-/, $slug)[1];
            }
            $new{quantity} = $elem->{quantity};
            for my $attr (qw(name tier description mass value bonds rarity description)) {
                $new{$attr} = $elem->{item}{$attr}
            }
            $new{type} = $elem->{item}{item_type}{name};
            $new{by_station} = { $station_name => $new{quantity} } if $station_name;
            $all_items->{$slug} = \%new;
        }
    }
}

sub extract_item_from_html {
    my $filename = shift;
    open my $IN, '<:encoding(UTF-8)', $filename
        or die "Cannot open '$filename' for reading: $!\n";
    my $dom = Mojo::DOM->new(do { local $/; <$IN> });
    close $IN;
    my $item_dom = $dom->at('section.item-detailed');
    die "$filename does not seem to be an item detail page\n." unless $item_dom;
    my %item;
    $item{name} = $item_dom->at('h1.name')->text;
    $item{description} = $item_dom->at('p.item-detailed-description')->text;

    $item_dom = $item_dom->at('.item-detailed-stats');
    
    for (qw(rarity type tier accuracy value range weapon_type)) {
        if (my $d = $item_dom->at("li.$_ span")) {
            $item{$_} =  $d->text;
        }
    }
    if ( $item{range} ) {
        $item{is_long_range} = delete($item{range}) eq 'Long' ? 1 : 0;
    }
    for my $damage (qw(impact piercing energy)) {
        if (my $d = $item_dom->at("li.$damage-damage span")) {
            $item{$damage} = $d->text;
        }
    }
    $item{mass} = $item_dom->at('li.weight span')->text =~ s/\s*kg//r;

    return \%item;
}

1;
