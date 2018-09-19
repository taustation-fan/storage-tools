package Taustation::Character;
use strict;
use utf8;
use warnings;
use 5.014;

use Exporter qw(import);

our @EXPORT_OK = qw(data_from_file);

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
    {
        my $stats = $content->at('div.statistics-container')->at('dl.statistics');
        my $keys = $stats->find('dt')->map('text');
        my $values = $stats->find('dd')->map('text');
        my %d;
        @d{ @$keys } = @$values;
        if ( $d{'Level:'} =~ /(\d+)\s*\@\s*(\d+(?:\.\d+))\s*%/) {
            $data{level} = $1 + ($2/100);
        }
    }
    $data{date} = $date;
    transform(\%data);
    return ($date, \%data);
}

sub numify {
    $_[0] =~ s/[^\d]//gr;
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
            if ($r->{Reputation} =~ /[a-z]/) {
                $rep{$r->{Affiliation}} = $r->{Reputation};
            }
            else {
                $rep{$r->{Affiliation}} = 0 + $r->{Reputation} =~ s/%$//r;
            }
        }
        $d->{extracted}{reputation} = \%rep;
    }

    $d->{Bank}{$_} =~ tr/,//d for qw(Bonds Credits);
    $d->{Bank}{$_} =~ s/\n.*//s for qw(Bonds Credits);

    $d->{extracted}{course_count} = @{$d->{Education}};
    $d->{extracted}{credits} = 0 + $d->{Bank}{Credits};
    $d->{extracted}{bonds} = 0 + $d->{Bank}{Bonds};
    $d->{extracted}{level} = $d->{level} if defined $d->{level};
    
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

sub strip {
    my $s = shift;
    $s =~ s/^\s+//;
    $s =~ s/\s+\z//;
    $s =~ s/:$//;
    return $s;
}

sub extract_date {
    if ($_[0] =~ m/data-time="(\d{4}-\d\d-\d\d)T/) {
        return $1;
    }
    die "Cannot extract date\n";
}



1;
