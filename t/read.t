use Test::Most;

use Geo::UK::Postcode::CodePointOpen;

ok my $cpo = Geo::UK::Postcode::CodePointOpen->new( path => 'corpus' ),
    'new object';

ok my $ri = $cpo->read_iterator(), 'got read_iterator';

my @pcs;
while (my $row = $ri->()) {
    push @pcs, $row;
}

is scalar(@pcs), 20, "read correct number of postcodes";

is_deeply $pcs[0],
    {
    Admin_county_code            => "",
    Admin_district_code          => "S12000033",
    Admin_ward_code              => "S13002483",
    Country_code                 => "S92000003",
    Eastings                     => 394251,
    NHS_HA_code                  => "S08000006",
    NHS_regional_HA_code         => "",
    Northings                    => 806376,
    Positional_quality_indicator => 10,
    Postcode                     => "XX101AA"
    },
    "sample row ok";

done_testing();

