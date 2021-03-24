package main;
use strictures 2;
use Carp qw(croak);
use Crypt::Digest::SHA256 qw(sha256_b64);
use Crypt::Misc qw(random_v4uuid);
use Mojo::JSON qw(decode_json encode_json);
use Test2::V0;
use Test2::Tools::Exception;
use GrokLOC::Env qw(:all);
use GrokLOC::Models qw(:all);
use GrokLOC::Models::Org;
use GrokLOC::Models::User;
use GrokLOC::Security::Crypt qw(:all);
use GrokLOC::State::Init qw(state_init);

my $st;

ok(
    lives {
        $st = state_init($UNIT);
    }
) or note($@);

# User db operations will do a referential integrity check on the org,
# so create one here.
my $org    = GrokLOC::Models::Org->new( name => random_v4uuid );
my $result = $org->insert( $st->master );
croak 'insert org' unless ( $result == $RESPONSE_OK );
$result = $org->update_status( $st->master, $STATUS_ACTIVE );
croak 'update org status' unless ( $result == $RESPONSE_OK );

my $user;

my ( $display, $email, $password ) =
  ( random_v4uuid, random_v4uuid, random_v4uuid );

ok(
    lives {
        $user = GrokLOC::Models::User->new(
            display        => $display,
            email          => $email,
            org            => $org->id,
            password       => $password,
            key            => $st->key,
            kdf_iterations => $st->kdf_iterations,
        );
    },
    'new'
) or note($@);

is( $user->_meta->status, $STATUS_UNCONFIRMED, 'status' );
is( $user->_meta->ctime,  0,                   'ctime' );
is( $user->_meta->mtime,  0,                   'mtime' );

isnt( $user->display,  $display,  'display' );
isnt( $user->email,    $email,    'email' );
isnt( $user->password, $password, 'password' );

ok(
    dies {
        GrokLOC::Models::User->new();
    },
    'no args'
) or note($@);

ok(
    lives {
        GrokLOC::Models::User->new(
            id                => $user->id,
            api_secret        => $user->api_secret,
            api_secret_digest => $user->api_secret_digest,
            display           => $user->display,
            display_digest    => $user->display_digest,
            email             => $user->email,
            email_digest      => $user->email_digest,
            org               => $user->org,
            password          => $user->password,
            _meta             => $user->_meta,
        );
    },
    'all args'
) or note($@);

my $rt;

ok(
    lives {
        $rt =
          GrokLOC::Models::User->new( %{ decode_json( encode_json($user) ) } );
    },
    'json round trip'
) or note($@);

is( $rt->id, $user->id, 'id round trip' );

ok(
    lives {
        $result = $user->insert( $st->master );
    },
    'insert'
) or note($@);

is( $result, $RESPONSE_OK, 'insert ok' );

ok(
    lives {
        $result = $user->insert( $st->master );
    },
    'insert'
) or note($@);

is( $result, $RESPONSE_CONFLICT, 'insert duplicate' );

# org will not be found in db.
ok(
    lives {
        my $bad_org_user = GrokLOC::Models::User->new(
            display        => $display,
            email          => $email,
            org            => random_v4uuid,
            password       => $password,
            key            => $st->key,
            kdf_iterations => $st->kdf_iterations,
        );
        $result = $bad_org_user->insert( $st->master );
    },
    'bad org user'
) or note($@);

is( $result, $RESPONSE_ORG_ERR, 'insert with bad org' );

my $read_user;

ok(
    lives {
        $read_user =
          GrokLOC::Models::User->read( $st->random_replica(), $user->id );
    },
    'read'
) or note($@);

is( $read_user->id, $user->id, 'read ok' );

my $not_found;

ok(
    lives {
        $not_found =
          GrokLOC::Models::User->read( $st->random_replica(), random_v4uuid );
    },
    'read not found'
) or note($@);

isnt( defined($not_found), 1 );

my $new_display = random_v4uuid;

ok(
    lives {
        $result = $user->update_display( $st->master, $new_display );
    },
    'update password'
) or note($@);

is( $result, $RESPONSE_OK, 'update display ok' );

ok(
    lives {
        $read_user =
          GrokLOC::Models::User->read( $st->random_replica(), $user->id );
    },
    'read'
) or note($@);

is( $read_user->display, $new_display, 'update display' );
is(
    $read_user->display_digest,
    sha256_b64($new_display),
    'update display digest'
);

my $new_password = random_v4uuid;

ok(
    lives {
        $result = $user->update_password( $st->master, $new_password,
            $st->kdf_iterations );
    },
    'update password'
) or note($@);

is( $result, $RESPONSE_OK, 'update password ok' );

ok(
    lives {
        $read_user =
          GrokLOC::Models::User->read( $st->random_replica(), $user->id );
    },
    'read'
) or note($@);

is( kdf_verify( $read_user->password, $new_password ),
    1, 'verify new password' );
isnt( kdf_verify( $read_user->password, random_v4uuid ),
    1, 'not-verify wrong password' );

ok(
    lives {
        $result = $user->update_status( $st->master, $STATUS_ACTIVE );
    },
    'update status'
) or note($@);

is( $result, $RESPONSE_OK, 'update status ok' );

ok(
    lives {
        $read_user =
          GrokLOC::Models::User->read( $st->random_replica(), $user->id );
    },
    'read'
) or note($@);

is( $read_user->id,            $user->id,      'read ok' );
is( $read_user->_meta->status, $STATUS_ACTIVE, 'confirm status' );

done_testing;

1;