package main;
use strictures 2;
use Carp qw(croak);
use Crypt::Misc qw(random_v4uuid);
use Mojo::URL;
use Test::Mojo;
use Test2::V0;
use Test2::Tools::Exception;
use GrokLOC::App qw(:all);
use GrokLOC::App::Client;
use GrokLOC::App::JWT qw(:all);
use GrokLOC::App::Routes qw(:routes);
use GrokLOC::State::Init qw($ST);

my $t   = Test::Mojo->new('App');
my $url = Mojo::URL->new( $t->ua->server->url->to_string );

$t->get_ok($OK_ROUTE)->status_is(200)->content_like(qr/ok/i);

# Token requests.

# No headers.
$t->post_ok($TOKEN_REQUEST_ROUTE)->status_is(400);

# Missing ID.
$t->post_ok(
    $TOKEN_REQUEST_ROUTE => {
        $X_GROKLOC_ID => random_v4uuid,
    }
)->status_is(404);

# Bad token.
$t->post_ok(
    $TOKEN_REQUEST_ROUTE => {
        $X_GROKLOC_ID            => $ST->root_user,
        $X_GROKLOC_TOKEN_REQUEST => random_v4uuid,
    }
)->status_is(401);

my $token_request = encode_token_request( $ST->root_user, $ST->root_user_api_secret );

$t->post_ok(
    $TOKEN_REQUEST_ROUTE => {
        $X_GROKLOC_ID            => $ST->root_user,
        $X_GROKLOC_TOKEN_REQUEST => $token_request,
    }
)->status_is(204);

# Further tests require state - use the client.

my $client;

ok(
    lives {
        $client = GrokLOC::App::Client->new(
            id         => $ST->root_user,
            api_secret => $ST->root_user_api_secret,
            url        => $url,
            ua         => $t->ua,
        );
    }
) or note($@);

ok(
    lives {
        $client->token_request;
    }
) or note($@);

ok(
    lives {
        $client->ok;
    }
) or note($@);

ok(
    lives {
        $client->status;
    }
) or note($@);

done_testing();
