#!/usr/bin/env perl
use 5.014;
use strict;
use warnings;
use lib 'lib';
use Taustation::Character qw(data_from_file);
use Mojo::DOM;
use JSON::XS qw(encode_json);
use File::Path qw(make_path);
use List::Util qw(sum);
use Data::Dumper;

my %all_data;
my %dates;

for my $filename (glob "syndicate/characters/*/*.html") {
    my $character;
    if ($filename =~ m{.*/(.+?)\.html}) {
        $character = "$1";
    }
    else {
        warn "Don't know what to do with file name '$character'\n";
        break;
    }
    my ($date, $data) = data_from_file($filename);
    $dates{$date}++;
    my %extracted = %{ $data->{extracted} };
    my $stats = sum values %{ $extracted{stats} };
    $all_data{$character}{$date} = {
        stats   => $stats,
        level   => $extracted{level},
        bonds   => $extracted{bonds},
        credits => $extracted{credits},
        course_count    => $extracted{course_count},
    };
}

my @keys = qw(stats level bonds credits course_count);
my %headers = (
    'stats'         => 'st',
    'level'         => 'lvl',
    'bonds'         => 'b',
    'credits'       => 'cr',
    'course_count'  => 'uni',
);
my @players = sort keys %all_data;
my @columns = ('Player');
push @columns, sort keys %dates;
say join "\t", @columns;

my %previous;

for my $player(@players) {
    my @row = ($player);
    for my $date (sort keys %dates) {
        my $content = '';
        for my $key (@keys) {
            my $value = $all_data{$player}{$date}{$key};
            my $previous = $previous{$player}{$key};
            if (defined $value){
                if (defined $previous) {
                    my $diff = $value - $previous;
                    $content .= $headers{$key}.'Δ='.( $diff ? (sprintf '%.3f', $diff) : 'NONE' )."\n";
                } else {
                    $content .= $headers{$key}.'='.$value."\n";
                }
                $previous{$player}{$key} = $value;
            } else {
                delete $previous{$player}{$key};
            }
        }
        $content =~ s/\s+$//;
        push @row, '"'.$content.'"';
    }
    say join "\t", @row;
}

