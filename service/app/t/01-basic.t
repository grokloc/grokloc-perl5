package main;
use strictures 2;
use Carp qw(croak);
use Mojo::URL;
use Test::Mojo;
use Test2::V0;
use Test2::Tools::Exception;
use GrokLOC::App::Routes qw(:routes);

my $t   = Test::Mojo->new('App');
my $url = Mojo::URL->new( $t->ua->server->url->to_string );

$t->get_ok($OK_ROUTE)->status_is(200)->content_like(qr/ok/i);

# Token requests.

# No headers.

# TODO: Add route.

# $t->post_ok($TOKEN_REQUEST_ROUTE)->status_is(400);

done_testing();
