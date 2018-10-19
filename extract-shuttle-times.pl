#!/usr/bin/env perl
use 5.014;
use strict;
use warnings;
use Digest::SHA qw(sha1_hex);
use Mojo::DOM;
use File::Path qw(make_path);
use Getopt::Long;
use lib 'lib';
use Taustation qw(extract_station_name);

GetOptions(
    'move!'         => \my $Move,
    'input-dir=s'   => \(my $Input_dir = 'shuttles'),
    'output-dir=s'  => \(my $Output_dir = 'DATA-shuttles'),
) or die "Usage: $0 [--move]";

my %short = (
    'TAU STATION'               => 'TAU',
    'DAEDALUS'                  => 'DAE',
    'KØBENHAVN'                 => 'KOE',
    'KøBENHAVN'                 => 'KOE', # encoding shenenigans
    'NOUVEAU LIMOGES'           => 'NL',
    'SOL JUMP GATE'             => 'SJG',
    'TAUNGOO STATION'           => 'TNG',

    'PARIS SPATIALE'            => 'PS',
    'ALPHA CENTAURI JUMP GATE'  => 'ACJG',
    'BORDEAUX STATION'          => 'BDX',
    'CIRQUE CENTAURI'           => 'CC',
    'MOISSAN STATION'           => 'MOI',
    'SPIRIT OF BOTSWANA'        => 'SOB',
    'THE GHOST OF MALI'         => 'GOM',
    'YARDS OF GADANI'           => 'YOG',

    "BARNARD'S STAR JUMP GATE"  => 'BSJG',
    'CAEN STRONGHOLD'           => 'CSH',
    "HOPKINS' LEGACY"           => 'HOL',
    'ESTACIÓN DE AMAZON'        => 'AMZ',
    'ESTACIóN DE AMAZON'        => 'AMZ',
    'THE MAID OF ORLÉANS'       => 'MOO',
    'THE MAID OF ORLéANS'       => 'MOO',
);

for my $filename (glob "$Input_dir/*") {
    say STDOUT $filename;
    process_file($filename);
}

sub find_free_target_filename {
    my ($system, $short) = @_;
    my $dir = 'old-shuttles';
    my $postfix = 0;
    make_path("$dir/$system");
    while (1) {
        my $fn = sprintf "%s/%s/%s-%04d.html", $dir, $system, $short, $postfix;
        return $fn unless -e $fn;
        $postfix++;
    }
}

sub process_file {
    my $filename = shift;
    my ($checksum, $system, $from,  $data) = data_from_file($filename);
    my $output = "$Output_dir/$checksum.csv";
    my $from_short = $short{$from}
        or die "No shorthand known for $from\n";
    for my $to (sort keys %$data) {
        my $to_short = $short{$to}
            or die "No shorthand known for $to\n";
        my $key = join '-', sort $from_short, $to_short;
        make_path("$Output_dir/$system/$key");
        my $out_fn = "$Output_dir/$system/$key/$checksum.csv";
        open my $FH, '>', $out_fn
            or die "Cannot open $out_fn for writing: $!";
        say $FH join ' ', @$_
            for @{ $data->{$to} };
    }
    if ($Move) {
        my $target = find_free_target_filename($system, $from);
        say "    renaming to $target";
        rename $filename, $target
            or die $!;
    }
}

sub data_from_file {
    my $filename = shift;
    my ($from, $system) = map uc, extract_station_name($filename);
    $system =~ s/[^a-z ]//ig;
    my $contents = do {
        local $/;
        open my $FH, '<', $filename
            or die "Cannot read '$filename': $!";
        <$FH>;
    };
    my $checksum = sha1_hex($contents);

    my $dom = Mojo::DOM->new( $contents );

    my %to;

    my $all_dests = $dom->find('ul.area-table')->[0];
    $all_dests->find('li')->each( sub {
        my $d = shift;
        my $station = station_name($d);
        return unless $station;
        $d->find('li.ticket-schedule-row')->each( sub {
            my $row = shift;
            my $dds = $row->find('dd');
            return unless $dds->[0];
            push @{ $to{$station} }, [
                numify($dds->[0]->text),
                numify($dds->[3]->text),
            ]
        });
    });
    return ($checksum, $system, $from, \%to);
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

