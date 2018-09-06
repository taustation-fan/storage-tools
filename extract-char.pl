#!/usr/bin/env perl
use 5.014;
use strict;
use warnings;
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

sub strip {
    my $s = shift;
    $s =~ s/^\s+//;
    $s =~ s/\s+\z//;
    $s =~ s/:$//;
    return $s;
}

sub transform {
    my $d = shift;

    # stats
    {
        my %stats;
        for my $s (@{ $d->{Stats} }) {
            $stats{$s->{Stat}} = 0 + $s->{Value};
        }
        $d->{extracted}{stats} = \%stats;
    }

    # reputation
    {
        my %rep;
        for my $r (@{ $d->{Reputation} }) {
            $rep{$r->{Affiliation}} = 0 + $r->{Reputation} =~ s/%$//r;
        }
        $d->{extracted}{reputation} = \%rep;
    }
    $d->{extracted}{course_count} = @{$d->{Education}};
    $d->{extracted}{credits} = 0 + $d->{Bank}{Credits};
    $d->{extracted}{bonds} = 0 + $d->{Bank}{Bonds};
    
}

sub process_file {
    my $filename = shift;
    my ($date, $rest) = data_from_file($filename);

    transform($rest);

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

sub extract_date {
    if ($_[0] =~ m/data-time="(\d{4}-\d\d-\d\d)T/) {
        return $1;
    }
    die "Cannot extract date\n";
}

sub parse_table_no_head {
    # tables like Career and Equipment have no table head.
    # There, the first column acts as the key
    my $t = shift;
    my %values;
    $t->find('tr')->each(sub {
        my $k = strip($_->at('th')->all_text);
        my $v = strip($_->at('td')->all_text);
        $values{$k} = $v;
    });
    return \%values;
}

sub parse_table {
    my $t = shift;
    my @headers;
    my $thead = $t->at('thead');
    return parse_table_no_head($t) unless $thead;
    $thead->find('th')->each(sub {
        push @headers, strip($_->all_text);
    });
    my @rows;
    $t->at('tbody')->find('tr')->each( sub {
        my @row;
        $_->find('td')->each(sub {
            push @row, strip($_->all_text);
        });
        push @rows, \@row;
    });

    my @result;
    for my $r (@rows) {
        my %v;
        for my $idx (0..$#headers) {
            $v{$headers[$idx]} = $r->[$idx];
        }
        push @result, \%v;
    };
    return \@result;
}

sub data_from_file {
    my $filename = shift;
    my $contents = do {
        local $/;
        open my $FH, '<', $filename
            or die "Cannot read '$filename': $!";
        <$FH>;
    };
    my $date = extract_date($contents);
    my $dom = Mojo::DOM->new( $contents );
    my $content = $dom->find('div.character-overview')->[0];
    my %data;
    $content->find('h2')->each(sub {
        my $heading = $_;
        my $heading_str = strip($heading->all_text);
        my $table = $heading->following('div')->[0]->at('table');
        if ($heading_str && $table) {
            my $t = parse_table($table);
            $data{$heading_str} = $t;
        }
    });
    $data{date} = $date;
    return ($date, \%data);
}


sub numify {
    $_[0] =~ s/[^\d]//gr;
}
