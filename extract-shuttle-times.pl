#!/usr/bin/env perl
use 5.014;
use strict;
use warnings;
use Digest::SHA qw(sha1_hex);
use utf8;
use Mojo::File;
use Mojo::DOM;
use File::Path qw(make_path);
use lib 'lib';
use Taustation qw(extract_station_name);

my %short = (
    'PARIS SPATIALE'            => 'PS',
    'ALPHA CENTAURI JUMP GATE'  => 'ACJG',
    'BORDEAUX STATION'          => 'BDX',
    'CIRQUE CENTAURI'           => 'CC',
    'MOISSAN STATION'           => 'MOI',
    'SPIRIT OF BOTSWANA'        => 'SOB',
    'THE GHOST OF MALI'         => 'GOM',
    'YARDS OF GADANI'           => 'YOG',
);

my $output_dir = 'DATA-shuttles';
my $input_dir = 'shuttles';
for my $filename (glob "$input_dir/*") {
    say STDOUT $filename;
    process_file($filename);
}

sub process_file {
    my $filename = shift;
    my ($checksum, $data) = data_from_file($filename);
    my $output = "$output_dir/$checksum.csv";
    for my $from (sort keys %$data ) {
        my $from_short = $short{$from}
            or die "No shorthand known for $from\n";
        for my $to (sort keys %{ $data->{$from} }) {
            my $to_short = $short{$to}
                or die "No shorthand known for $to\n";
            make_path("$output_dir/$from_short-$to_short");
            my $out_fn = "$output_dir/$from_short-$to_short/$checksum.csv";
            open my $FH, '>', $out_fn
                or die "Cannot open $out_fn for writing: $!";
            say $FH join ' ', @$_
                for @{ $data->{$from}{$to} };
        }
    }
}

sub data_from_file {
    my $filename = shift;
    my $from = uc extract_station_name($filename);
    my $contents = do {
        local $/;
        open my $FH, '<', $filename
            or die "Cannot read '$filename': $!";
        <$FH>;
    };
    my $checksum = sha1_hex($contents);

    my $dom = Mojo::DOM->new( $contents );

    my %from_to;

    my $all_dests = $dom->find('ul.area-table')->[0];
    $all_dests->find('li')->each( sub {
        my $d = shift;
        my $station = station_name($d);
        return unless $station;
        $d->find('li.ticket-schedule-row')->each( sub {
            my $row = shift;
            my $dds = $row->find('dd');
            return unless $dds->[0];
            push @{ $from_to{$from}{$station} }, [
                numify($dds->[0]->text),
                sqrt(numify($dds->[2]->text)),
            ]
        });
    });
    return ($checksum, \%from_to);
}


sub numify {
    $_[0] =~ s/[^\d]//gr;
}

sub station_name {
    my $dom = shift;
    my $heading =  $dom->find('h3.area-table-title span')->[0];
    return unless $heading;
    return $heading->text;
}

