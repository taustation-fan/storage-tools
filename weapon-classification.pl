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

my @weapons = grep { lc($_->{type}) eq 'weapon' } values %all_items;
my @damages = qw(piercing impact energy);

sub classify {
    my $item = shift;

    return join '/', $item->{tier}, $item->{hand_to_hand},
                map { $_ > 0 ? 1 : 0 } @{$item}{@damages};
}
my %grouped;
for my $weapon (@weapons) {
    push @{ $grouped{classify($weapon)} }, $weapon;
}

my $comparison_table = Text::Table->new('tier', 'worse', 'better');

for my $weapons (values %grouped) {
    next if @$weapons <= 1;
#    printf "\n\n\nTier %d, %s\n\n", $weapons->[0]{tier}, $weapons->[0]{hand_to_hand} ? 'Hand-to-hand' : 'long range';

    my $t = Text::Table->new("Name", 'Mass', 'Accuracy', @damages);
    my @weapons = reverse sort {$a->{accuracy} <=> $b->{accuracy}} @$weapons;
    for my $w (@weapons) {
        $t->add($w->{name}, $w->{mass}, $w->{accuracy}, @{$w}{@damages});
    }
#    say $t;
    
    for my $idx (1..$#weapons) {
        my $w = $weapons[$idx];
        for my $comp(@weapons[0...$idx-1]) {
            if (    $w->{mass} > $comp->{mass}
                 && $w->{piercing} <= $comp->{piercing}
                 && $w->{impact} <= $comp->{impact}
                 && $w->{energy} <= $comp->{energy}
            ) {
#                say $w->{name}, "\t is worse than ", $comp->{name};
                $comparison_table->add($w->{tier}, $w->{name}, $comp->{name});
                last;
            }
        }

    }
}

say $comparison_table;

# use Data::Dumper; warn Dumper \%grouped;


