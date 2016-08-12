use Test::More;

use Test::Needs 'Types::Standard';

use Types::Standard qw( Bool );

SKIP: {
    eval { require Cpanel::JSON::XS };
    skip 'Cpanel::JSON::XS not installed', 1 if $@;
    ok( Bool->check(Cpanel::JSON::XS::true), 'Cpanel::JSON::XS::true' );
}

done_testing();
