use strict;
use warnings;
use Test::More;

use_ok('Type::Tiny::XS');

{
	package Local::Overload;
	my @xyz = (1 .. 10);
	use overload q(@{}) => sub { \@xyz };
}

{
	package Local::Overload2;
	my %xyz = ( foo => 42 );
	use overload q(%{}) => sub { \%xyz };
}

{
	package Local::Overload3;
	my %xyz = ( foo => 'bar' );
	use overload q(%{}) => sub { \%xyz };
}

my $obj = bless {}, 'Local::Overload';
is( $obj->[1], 2 );

my $obj2 = bless [], 'Local::Overload2';
is( $obj2->{foo}, 42 );

ok !Type::Tiny::XS::HashLike([]), 'NOT []';
ok !Type::Tiny::XS::HashLike([1..3]), 'NOT [1..3]';
ok !Type::Tiny::XS::HashLike($obj), 'NOT $obj';
ok Type::Tiny::XS::HashLike($obj2), '$obj2';
ok Type::Tiny::XS::HashLike({}), '{}';
ok Type::Tiny::XS::HashLike({ bar => 666 }), '{ bar => 666 }';
ok !Type::Tiny::XS::HashLike(1), 'NOT 1';

my $arrayof = Type::Tiny::XS::get_coderef_for('ArrayRef[HashLike]');
ok $arrayof->( [ {}, {bar=>666}, $obj2 ] ), '$arrayof : 1';
ok !$arrayof->( [ {}, {bar=>666}, $obj ]), '$arrayof : 2';

my $hashlikeof = Type::Tiny::XS::get_coderef_for('HashLike[Num]');
ok(   $hashlikeof->( { 1..4 } ) );
ok( ! $hashlikeof->( { 1..4, xyz => 'foo' } ) );
ok( ! $hashlikeof->( $obj ) );
ok(   $hashlikeof->( $obj2 ) );
ok( ! $hashlikeof->( bless [], 'Local::Overload3' ) );
ok( ! $hashlikeof->( [] ) );
ok(   $hashlikeof->( {} ) );

done_testing;
