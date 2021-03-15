package main;
use strictures 2;
use Crypt::Misc qw(random_v4uuid);
use Mojo::JSON qw(decode_json encode_json);
use Test2::V0;
use Test2::Tools::Exception;
use GrokLOC::Env qw(:all);
use GrokLOC::State::Init qw(:all);
use GrokLOC::Models qw(:all);
use GrokLOC::Models::Org;

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

done_testing;

1;
