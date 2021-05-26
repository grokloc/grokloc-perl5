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

# Only root can create a new org.
my $org_result;
my $org_name = random_v4uuid;
ok(
    lives {
        $org_result = $root_client->org_create($org_name);
    },
    'org create'
) or note($@);

is( $org_result->code, 201, 'org create code' );
like( $org_result->headers->location,
    qr/\/\S+\/\S+\/\S+\/\S+/, 'location path' );

# Create a regular non-root user (and client) - won't be able to create an org.
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
        $org_result = $a_client->org_create(random_v4uuid);
    },
    'a_client org create'
) or note($@);

is( $org_result->code, 403, 'org create code' );

# Duplicates not allowed.
ok(
    lives {
        $org_result = $root_client->org_create($org_name);
    },
    'org create'
) or note($@);

is( $org_result->code, 409, 'org create code' );

done_testing();
