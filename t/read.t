use Test::Most;

use Geo::UK::Postcode::CodePointOpen;

ok my $cpo = Geo::UK::Postcode::CodePointOpen->new( path => 'corpus' ),
    'new object';

ok my $ri = $cpo->read_iterator(), 'got read_iterator';

done_testing();

