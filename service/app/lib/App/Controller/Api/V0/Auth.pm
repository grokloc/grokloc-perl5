package App::Controller::Api::V0::Auth;
use strictures 2;
use Mojo::Base 'Mojolicious::Controller';
use Syntax::Keyword::Try qw(try catch :experimental);
use experimental qw(signatures switch);
use GrokLOC::App qw(:all);
use GrokLOC::App::JWT qw(:all);
use GrokLOC::App::Message qw(app_msg);
use GrokLOC::Models qw(:all);
use GrokLOC::Models::Org;
use GrokLOC::Models::User;
use GrokLOC::Security::Crypt qw(:all);

# ABSTRACT: Auth middleware for populating the stash.

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

# with_session is a middleware that will fill the stash with user and org instances.
# Subsequent chained handlers can be assured of a stashed user and org.
# Subsequent chained handlers can be assured of a minumum auth level of $AUTH_USER.
# See perldocs for more info.
sub with_session ( $c ) {
    $c->stash( $STASH_AUTH => $AUTH_NONE );

    # The X-GrokLOC-ID header must be present in order to look up the user.
    unless ( $c->req->headers->header($X_GROKLOC_ID) ) {
        $c->render( app_msg( 400, { error => 'missing:' . $X_GROKLOC_ID } ) );
        return;
    }
    my $user_id = $c->req->headers->header($X_GROKLOC_ID);
    my $user;
    try {
        $user =
          GrokLOC::Models::User::read( $c->st->random_replica(), $user_id );
    }
    catch ($e) {
        $c->app->log->error( 'internal error reading user ' . $user_id );
        $c->render( app_msg( 500, { error => 'internal error' } ) );
        return;
    }
    if ( !defined($user) || $user->meta->status != $STATUS_ACTIVE ) {
        $c->render( app_msg( 404, { error => 'user not found' } ) );
        return;
    }
    my $org;
    try {
        $org =
          GrokLOC::Models::Org::read( $c->st->random_replica(), $user->org );
    }
    catch ($e) {
        $c->app->log->error(
            'internal error reading org:' . $user->org . ': ' . $e );
        $c->render( app_msg( 500, { error => 'internal error' } ) );
        return;
    }
    if ( !defined($org) || $org->meta->status != $STATUS_ACTIVE ) {
        $c->render( app_msg( 400, { error => 'org not found' } ) );
        return;
    }

    my $auth_level = $AUTH_USER;
    if ( $org->id eq $c->st->root_org ) {
        $auth_level = $AUTH_ROOT;
    }
    elsif ( $org->owner eq $user->id ) {
        $auth_level = $AUTH_ORG;
    }

    if ( $c->req->headers->header($AUTHORIZATION) ) {
        try {
            my $encoded = $c->req->headers->header($AUTHORIZATION);
            my $decoded = decode_token( $encoded, key( $c->st->key ) );
        }
        catch ($e) {
            $c->render( app_msg( 400, { error => 'refresh token' } ) );
            return;
        }
        given ($auth_level) {
            when ($AUTH_USER) { $auth_level = $TOKEN_USER; }
            when ($AUTH_ORG)  { $auth_level = $TOKEN_ORG; }
            when ($AUTH_ROOT) { $auth_level = $TOKEN_ROOT; }
            default {
                $c->app->log->error('invalid auth level');
                $c->render( app_msg( 500, { error => 'internal error' } ) );
                return;
            }
        }
    }
    $c->stash( $STASH_AUTH => $auth_level );
    $c->stash( $STASH_ORG  => $org );
    $c->stash( $STASH_USER => $user );
    return 1;
}

# new_token mints a new jwt for a user if the token request header
# validates. Should be treated as a POST handler since a new jwt is always
# minted, but note that unlike typical POSTs, there is no redirect or Location
# header in the response, only the value of the jwt.
sub new_token ( $c ) {
    my $token_request = $c->req->headers->header($X_GROKLOC_TOKEN_REQUEST);
    unless ( defined $token_request ) {
        $c->render(
            app_msg( 400, { error => 'missing:' . $X_GROKLOC_TOKEN_REQUEST } )
        );
        return;
    }
    my $user = $c->stash($STASH_USER);
    my $api_secret;
    try {
        $api_secret =
          decrypt( $user->api_secret, key( $c->st->key ), iv( $user->id ) );
    }
    catch ($e) {
        $c->app->log->error(
            'cannot decrypt api_secret for user:' . $user->id . ': ' . $e );
        $c->render( app_msg( 500, { error => 'internal error' } ) );
        return;
    }
    unless ( verify_token_request( $token_request, $user->id, $api_secret ) ) {
        $c->render( app_msg( 401, { error => 'bad token request' } ) );
        return;
    }
    my $token;
    try {
        $token = encode_token( $user->id, key( $c->st->key ) );
    }
    catch ($e) {
        $c->app->log->error(
            'cannot encode token for user:' . $user->id . ': ' . $e );
        $c->render( app_msg( 500, { error => 'internal error' } ) );
        return;
    }
    $c->res->headers->header( $AUTHORIZATION => $JWT_TYPE . q{ } . $token );
    $c->render( status => 204, data => q{} );
    $c->app->log->info( 'new token for user ' . $user->id );
    return 1;
}

1;

__END__

=head1 NAME

App::Controller::Api::V0::Auth

=head1 SYNOPSIS

Auth middleware for populating the stash.

=head1 DESCRIPTION

The `with_session` middleware performs the following checks:

- From the X-GrokLOC-ID header, look up the user and the org.
  - Set the stash auth level to AUTH_NONE.
  - If the user is not active, immediately return 404.
  - If the org is not active, immediately return 400.
  - Otherwise: 
    - Set the stash references to the user and org model instances.
    - Set the stash auth level to AUTH_USER, AUTH_ORG or AUTH_ROOT
- If the X-GrokLOC-Token header is found, validate the JWT.
  - If the JWT is unparseable, return 400.
  - If the JWT is not valid or expired, immediately return 403.
  - Otherwise:
    - Change the stash auth value to TOKEN_USER, TOKEN_ORG, or TOKEN_ROOT.

=cut
