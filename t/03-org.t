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

done_testing;

1;
