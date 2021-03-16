package main;
use strictures 2;
use Crypt::Misc qw(random_v4uuid);
use Test2::V0;
use Test2::Tools::Exception;
use GrokLOC::Security::Crypt qw(:all);

ok( dies { length iv('') } )   or note($@);
ok( dies { length key('') } )  or note($@);
ok( dies { length salt('') } ) or note($@);

my $iv  = iv(random_v4uuid);
my $key = key(random_v4uuid);

is( $IV_LEN,  length $iv );
is( $KEY_LEN, length $key );

my $plain     = random_v4uuid;
my $crypted   = encrypt( $plain, $key, $iv );
my $decrypted = decrypt( $crypted, $key, $iv );
is( $plain, $decrypted );

my $salt    = salt(random_v4uuid);
my $derived = kdf( $plain, $salt, 1 );
is( kdf_verify( $derived, $plain ), 1 );
isnt( kdf_verify( $derived, random_v4uuid ), 1 );

done_testing;

1;
