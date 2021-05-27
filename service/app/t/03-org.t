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

# create a regular non-root user (and client) - won't be able to create an org
my ( $a_org, $a_user, $a_client );
ok(
    lives {
        ( $a_org, $a_user ) =
          GrokLOC::Test::org_user( $ST->master, $ST->key, $ST->kdf_iterations );
        $a_client = GrokLOC::App::Client->new(
            id         => $a_user->id,
            api_secret => $a_user->api_secret,
            url        => $url,
            ua         => $t->ua,
        );
    },
    'a_org, a_user, a_client'
) or note($@);

ok(
    lives {
        $create_org_result = $a_client->org_create(random_v4uuid);
    },
    'a_client org create'
) or note($@);

is( $create_org_result->code, 403, 'org create code' );

# duplicates not allowed
ok(
    lives {
        $create_org_result = $root_client->org_create($org_name);
    },
    'org create'
) or note($@);

is( $create_org_result->code, 409, 'org create code' );

# root can read any org
my $read_org_result;
ok(
    lives {
        $read_org_result = $root_client->org_read($org_id);
    },
    'org read'
) or note($@);

is( $read_org_result->code, 200, 'org read code' );

my $round_trip_org;
ok(
    lives {
        $round_trip_org =
          GrokLOC::Models::Org->new( %{ $read_org_result->json } );
    },
    'round trip org'
) or note($@);

is( $round_trip_org->id, $org_id, 'round trip org' );

# root gets a 404 on an org that isn't there
ok(
    lives {
        $read_org_result = $root_client->org_read(random_v4uuid);
    },
    'org read'
) or note($@);

is( $read_org_result->code, 404, 'org not found' );

# regular user read their own org
ok(
    lives {
        $read_org_result = $a_client->org_read( $a_org->id );
    },
    'org read'
) or note($@);

is( $read_org_result->code, 200, 'org read code' );

# regular user cannot read an org that they don't belong to
# $org_id here is a new org created above
ok(
    lives {
        $read_org_result = $a_client->org_read($org_id);
    },
    'org read'
) or note($@);

is( $read_org_result->code, 403, 'org read code' );

# update org status
# needs to be set to active to change the owner, so this must be done first anyway

# first, read it to make sure it isn't active
my $update_confirm_org_result;
ok(
    lives {
        $update_confirm_org_result = $root_client->org_read($org_id);
    },
    'org read'
) or note($@);

isnt( $update_confirm_org_result->json->{meta}->{status},
    $STATUS_ACTIVE, 'org not active' );

# now, update it to active
my $update_org_result;
ok(
    lives {
        $update_org_result =
          $root_client->org_update( $org_id, { status => $STATUS_ACTIVE } );
    },
    'org update'
) or note($@);

is( $update_org_result->code, 204, 'org update' );

# re-read the org to be sure
ok(
    lives {
        $update_confirm_org_result = $root_client->org_read($org_id);
    },
    'org read'
) or note($@);

is( $update_confirm_org_result->json->{meta}->{status},
    $STATUS_ACTIVE, 'org active' );

# update org - missing org

# update owner

# regular user cannot update an org in any way

# update with no args

# update with multiple args

# # update org owner - first we need a new, active user in the org
# my $new_owner = GrokLOC::Models::User->new(
#         display_name => random_v4uuid,
#         email        => random_v4uuid,
#         org          => $org_id,
#         password => kdf( random_v4uuid, salt(random_v4uuid), $ST->kdf_iterations ),
#         key      => $ST->key,
#     );

# ok(
#     lives {
#         # Insert the user.
#         my $insert_result = $new_owner->insert($ST->master);
#         croak 'user insert fail' unless $insert_result == $RESPONSE_OK;

#         # Update as active.
#         my $update_result = $new_owner->update_status( $ST->master, $STATUS_ACTIVE );
#         warn 'user update fail' unless $update_result == $RESPONSE_OK;
#         croak 'user update fail' unless $update_result == $RESPONSE_OK;
#     }, 'make new org owner'
# ) or note($@);

done_testing();
