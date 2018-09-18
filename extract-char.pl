#!/usr/bin/env perl
use 5.014;
use strict;
use warnings;
use lib 'lib';
use Taustation::Character qw(data_from_file);
use Mojo::DOM;
use JSON::XS qw(encode_json);
use File::Path qw(make_path);
use Getopt::Long;
use Data::Dumper;

GetOptions(
    'move!'         => \my $Move,
    'input-dir=s'   => \(my $Input_dir = 'character'),
    'output-dir=s'  => \(my $Output_dir = 'DATA-character'),
) or die "Usage: $0 [--move]";

make_path($Output_dir);

for my $filename (glob "$Input_dir/*") {
    say STDOUT $filename;
    process_file($filename);
}

sub process_file {
    my $filename = shift;
    my ($date, $rest) = data_from_file($filename);


    my $json_file = "$Output_dir/$date.json";
    open my $json_fh, '>', $json_file
        or die "Cannot open $json_file for writing: $!\n";
    say $json_fh encode_json($rest)
        or die "Cannot write to $json_file: $!\n";

    close $json_fh
        or die "Cannot write to $json_file: $!\n";

    if ($Move) {
        my $target = "$Output_dir/$date.html";
        say "    renaming to $target";
        rename $filename, $target
            or die $!;
    }
}


