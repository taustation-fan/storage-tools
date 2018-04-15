package Taustation;

use strict;
use warnings;
use 5.014;
use utf8;
use JSON qw(decode_json);

use Exporter qw(import);

our @EXPORT_OK = qw(extract_storage_from_html merge_inventory extract_station_name);

sub extract_station_name {
    my $filename = shift;
    open my $fh, '<:encoding(UTF-8)', $filename
        or die "Cannot open '$filename' for reading: $!\n";
    my $content = do { local $/; <$fh> };
    if ($content =~ m!<span class="station">\s*(.+?)\s*</span>!) {
        my $station = (split /, /, "$1")[0];
        return $station;
    }
    return undef;
}

sub extract_storage_from_html {
    my $filename = shift;
    open my $IN, '<:encoding(UTF-8)', $filename
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
                $all_items->{ $slug }{ quantity } += $elem->{quantity};
                $all_items->{ $slug }{ by_station }{ $station_name } = $elem->{quantity}
                    if $station_name;
                next;
            }
            my %new;
            if ($category eq 'weapon' || $category eq 'armor') {
                my %type_specific = %{ $elem->{item}{"item_component_$category"} };
                while (my ($k, $v) = each %type_specific) {
                    $new{ $k =~ s/_damage//r } = $v;
                }
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

1;
