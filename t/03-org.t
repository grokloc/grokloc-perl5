package main;
use strictures 2;
use Crypt::Misc qw(random_v4uuid);
use Mojo::JSON qw(decode_json encode_json);
use Test2::V0;
use Test2::Tools::Exception;
use GrokLOC::Env qw(:all);
use GrokLOC::Models qw(:all);
use GrokLOC::Models::Org;
use GrokLOC::Models::User;
use GrokLOC::State::Init qw(state_init);

my $st;

ok(
    lives {
        $st = state_init($UNIT);
    }
) or note($@);

my $org;

ok(
    lives {
        $org = GrokLOC::Models::Org->new( name => random_v4uuid );
    },
    'new'
) or note($@);

is( $org->_meta->status, $STATUS_UNCONFIRMED, 'status' );
is( $org->_meta->ctime,  0,                   'ctime' );
is( $org->_meta->mtime,  0,                   'mtime' );

ok(
    dies {
        $org = GrokLOC::Models::Org->new();
    },
    'no args'
) or note($@);

ok(
    lives {
        $org = GrokLOC::Models::Org->new(
            id    => random_v4uuid,
            name  => random_v4uuid,
            owner => random_v4uuid,
            _meta => GrokLOC::Models::Meta->new(),
        );
    },
    'all args'
) or note($@);

my $rt;

ok(
    lives {
        $rt =
          GrokLOC::Models::Org->new( %{ decode_json( encode_json($org) ) } );
    },
    'json round trip'
) or note($@);

is( $rt->id, $org->id, 'id round trip' );

my $result;

ok(
    lives {
        $result = $org->insert( $st->master );
    },
    'insert'
) or note($@);

is( $result, $RESPONSE_OK, 'insert ok' );

ok(
    lives {
        $result = $org->insert( $st->master );
    },
    'insert'
) or note($@);

is( $result, $RESPONSE_CONFLICT, 'insert duplicate' );

my $read_org;

ok(
    lives {
        $read_org =
          GrokLOC::Models::Org->read( $st->random_replica(), $org->id );
    },
    'read'
) or note($@);

is( $read_org->id, $org->id, 'read ok' );

my $not_found;

ok(
    lives {
        $not_found =
          GrokLOC::Models::Org->read( $st->random_replica(), random_v4uuid );
    },
    'read not found'
) or note($@);

isnt( defined($not_found), 1 );

# Update to an owner that doesn't exist.
ok(
    lives {
        $result = $org->update_owner( $st->master, random_v4uuid );
    },
    'update owner not found'
) or note($@);

is( $result, $RESPONSE_USER_ERR, 'owner not found' );

# User, but for a different org.
my $user_id = random_v4uuid;

ok(
    lives {
        $st->master->db->insert(
            $USERS_TABLENAME,
            {
                id                => $user_id,
                api_secret        => random_v4uuid,
                api_secret_digest => random_v4uuid,
                display           => random_v4uuid,
                display_digest    => random_v4uuid,
                email             => random_v4uuid,
                email_digest      => random_v4uuid,
                org               => random_v4uuid,
                password          => random_v4uuid,
                status            => $STATUS_ACTIVE,
            }
        );
    },
    'new'
) or note($@);

ok(
    lives {
        $result = $org->update_owner( $st->master, $user_id );
    },
    'update owner not in org'
) or note($@);

is( $result, $RESPONSE_USER_ERR, 'owner not found' );

$user_id = random_v4uuid;

ok(
    lives {
        $st->master->db->insert(
            $USERS_TABLENAME,
            {
                id                => $user_id,
                api_secret        => random_v4uuid,
                api_secret_digest => random_v4uuid,
                display           => random_v4uuid,
                display_digest    => random_v4uuid,
                email             => random_v4uuid,
                email_digest      => random_v4uuid,
                org               => $org->id,
                password          => random_v4uuid,
                status            => $STATUS_INACTIVE,
            }
        );
    },
    'new'
) or note($@);

ok(
    lives {
        $result = $org->update_owner( $st->master, $user_id );
    },
    'update owner not active'
) or note($@);

is( $result, $RESPONSE_USER_ERR, 'owner not active' );

# OK.
$user_id = random_v4uuid;

ok(
    lives {
        $st->master->db->insert(
            $USERS_TABLENAME,
            {
                id                => $user_id,
                api_secret        => random_v4uuid,
                api_secret_digest => random_v4uuid,
                display           => random_v4uuid,
                display_digest    => random_v4uuid,
                email             => random_v4uuid,
                email_digest      => random_v4uuid,
                org               => $org->id,
                password          => random_v4uuid,
                status            => $STATUS_ACTIVE,
            }
        );
    },
    'new'
) or note($@);

ok(
    lives {
        $result = $org->update_owner( $st->master, $user_id );
    },
    'update owner'
) or note($@);

is( $result, $RESPONSE_OK, 'update owner' );

ok(
    lives {
        $result = $org->update_status( $st->master, $STATUS_ACTIVE );
    },
    'update status'
) or note($@);

is( $result, $RESPONSE_OK, 'update status ok' );

ok(
    lives {
        $read_org =
          GrokLOC::Models::Org->read( $st->random_replica(), $org->id );
    },
    'read'
) or note($@);

is( $read_org->id,            $org->id,       'read ok' );
is( $read_org->_meta->status, $STATUS_ACTIVE, 'confirm status' );
is( $read_org->owner,         $user_id,       'confirm owner' );

done_testing;

1;
