package main;
use strictures 2;
use Crypt::Misc qw(random_v4uuid);
use Test2::V0;
use Test2::Tools::Exception;
use Test2::Tools::Ref;
use GrokLOC::App::JWT qw(:all);

my $id         = random_v4uuid;
my $key        = random_v4uuid;
my $api_secret = random_v4uuid;

my $encoded_request;
is( 1, 1, 'ok' );
ok(
    lives {
        $encoded_request = encode_token_request( $id, $api_secret );
    }
) or note($@);
is( 1, verify_token_request( $encoded_request, $id, $api_secret ) );

my $jwt;
ok(
    lives {
        $jwt = encode_token( $id, $key )
    }
) or note($@);

my $decoded;
ok(
    lives {
        $decoded = decode_token( $jwt, $key )
    }
) or note($@);
ref_ok( $decoded, 'HASH' );

is( $jwt, token_from_header_val($jwt) );
is( $jwt, token_from_header_val( token_to_header_val($jwt) ) );

done_testing;

1;
