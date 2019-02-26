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
use Statistics::Basic qw(stddev median);
use Date::Simple qw(today);

my %all_data;
my %dates;

my $today = today();
my $first = $today - 20;

my %weight = (
    bonds       => 20,
    level       => 1000,
    credits     => 0.2,
    stats       => 100,
    course_count => 500,
);

# whitelist players for which there is a data set today,
# to avoid grading players that have been removed already
my %whitelist;
for my $filename (glob "syndicate/characters/$today/*.html") {
    if ($filename =~ m{.*/(.+?)\.html}) {
        $whitelist{$1} = 1;
    }
}


for my $filename (glob "syndicate/characters/*/*.html") {
    my $character;
    my $date;
    if ($filename =~ m{.*/(\d\d\d\d-\d\d-\d\d)/(.+?)\.html}) {
        $date = $1;
        $character = "$2";
    }
    else {
        warn "Don't know what to do with file name '$character'\n";
        break;
    }
    next unless $whitelist{$character};
    next if $date lt $first;
    my (undef, $data) = data_from_file($filename);
    $dates{$date}++;
    my %extracted = %{ $data->{extracted} };
    my $stats = sum values %{ $extracted{stats} };
    my $physical_stats = $extracted{stats}->{Strength}
                       + $extracted{stats}->{Stamina}
                       + $extracted{stats}->{Agility};
    $all_data{$character}{$date} = {
        stats   => $stats,
        level   => $extracted{level},
        bonds   => $extracted{bonds},
        credits => $extracted{credits},
        physical_stats  => $physical_stats,
        course_count    => $extracted{course_count},
    };
}

for my $player (sort keys %all_data) {
    my @dates = sort keys %{$all_data{$player}};
    my $score = 0;
    my $days = 0;
    for my $idx (1..$#dates) {
        my ($d1, $d2) = @dates[$idx - 1, $idx];
        next unless $d1 && $d2;
        $score += score_diff($all_data{$player}{$d1}, $all_data{$player}{$d2});
        $days++;
    }
    $days ||= 1;
    $score = int($score / $days);
    my $inactivity = $score == 0 ? 'INACTIVE' :
                     $score < 500 ? 'little activity' : '';
    say $player, "\t", $score, "\t", $inactivity;
}

my %by_tier;
for my $pd (values %all_data) {
    my $data = $pd->{$today};
    my $level = int($data->{level});
    my $tier = int(($level + 4) / 5);
    push @{ $by_tier{$tier} }, $data->{physical_stats};
}

say "\nStats averages by tier";
say join "\t", "tier", "avg", "stddev", "median";
for my $tier (sort keys %by_tier) {
    my @values   = @{$by_tier{$tier}};
    my $avg      = sum(@values) / @values;
    my $stddev   = stddev(@values)->query;
    my $median   = median(@values);
    printf "%.d\t%.2f\t%.2f\t%.2f\n", $tier, $avg, $stddev, $median;
}

sub score_diff {
    my ($old, $new) = @_;
    my $score = 0;
    for my $k (sort keys %weight) {
        my $weight = $weight{$k};
        my $old_value = $old->{$k};
        my $new_value = $new->{$k};
        next unless defined($new_value) and defined($old);
        $score += $weight * abs($new_value - $old_value);
    }
    return $score;
}
