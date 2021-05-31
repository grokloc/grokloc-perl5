package main;
use strictures 2;
use Carp qw(croak);
use Crypt::Misc qw(random_v4uuid);
use Mojo::URL;
use Test::Mojo;
use Test2::V0;
use Test2::Tools::Exception;
use experimental qw(signatures try);
use GrokLOC::App qw(:all);
use GrokLOC::App::Client;
use GrokLOC::App::Routes qw(:routes);
use GrokLOC::Models qw(:all);
use GrokLOC::Models::Org;
use GrokLOC::Security::Crypt qw(:all);
use GrokLOC::State::Init qw($ST);
use GrokLOC::Test;

my $t   = Test::Mojo->new('App');
my $url = Mojo::URL->new( $t->ua->server->url->to_string );

my $root_client;

ok(
    lives {
        $root_client = GrokLOC::App::Client->new(
            id         => $ST->root_user,
            api_secret => $ST->root_user_api_secret,
            url        => $url,
            ua         => $t->ua,
        );
    },
    'root client'
) or note($@);

# need an org for any user operations
# only root can create a new org
my $create_org_result;
my $org_name = random_v4uuid;
ok(
    lives {
        $create_org_result = $root_client->org_create($org_name);
    },
    'org create'
) or note($@);

is( $create_org_result->code, 201, 'org create code' );
like( $create_org_result->headers->location,
    qr/\/\S+\/\S+\/\S+\/\S+/, 'location path' );
my $org_id;
if ( $create_org_result->headers->location =~ /\/\S+\/\S+\/\S+\/(\S+)/ ) {
    $org_id = $1;
}
else {
    croak 'cannot extract id from ' . $create_org_result->headers->location;
}

# at first, set the org to be inactive
my $update_org_result;

ok(
    lives {
        $update_org_result =
          $root_client->org_update( $org_id, { status => $STATUS_INACTIVE } );
    },
    'org update to inactive'
) or note($@);

is( $update_org_result->code, 204, 'org update to inactive' );

# make a new user
my $create_user_result;

# org not found

ok(
    lives {
        $create_user_result =
          $root_client->user_create( random_v4uuid, random_v4uuid,
            random_v4uuid,
            kdf( random_v4uuid, salt(random_v4uuid), $ST->kdf_iterations ) );
    },
    'user create - org not in db'
) or note($@);

is( $create_user_result->code, 400, 'user create - org not in db' );

# org not active
ok(
    lives {
        $create_user_result =
          $root_client->user_create( random_v4uuid, random_v4uuid, $org_id,
            kdf( random_v4uuid, salt(random_v4uuid), $ST->kdf_iterations ) );
    },
    'user create - org not active'
) or note($@);

is( $create_user_result->code, 400, 'user ceate - org not active' );

# now make org active again so user insertion will proceed
ok(
    lives {
        $update_org_result =
          $root_client->org_update( $org_id, { status => $STATUS_ACTIVE } );
    },
    'org update to active'
) or note($@);

is( $update_org_result->code, 204, 'org update to active' );

# org not active
ok(
    lives {
        $create_user_result =
          $root_client->user_create( random_v4uuid, random_v4uuid, $org_id,
            kdf( random_v4uuid, salt(random_v4uuid), $ST->kdf_iterations ) );
    },
    'user create - org active'
) or note($@);

is( $create_user_result->code, 201, 'user ceate - org active' );

like( $create_user_result->headers->location,
    qr/\/\S+\/\S+\/\S+\/\S+/, 'location path' );
my $user_id;
if ( $create_user_result->headers->location =~ /\/\S+\/\S+\/\S+\/(\S+)/ ) {
    $user_id = $1;
}
else {
    croak 'cannot extract id from ' . $create_user_result->headers->location;
}

done_testing();
