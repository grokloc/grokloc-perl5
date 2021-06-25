package App::Controller::Api::V0::Auth;
use strictures 2;
use Mojo::Base 'Mojolicious::Controller';
use experimental qw(signatures try);
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

# with_session_ is a middleware that will fill the stash with user and org instances
# subsequent chained handlers can be assured of a stashed user and org
# subsequent chained handlers can be assured of a minumum auth level of $AUTH_USER
# subsequent chained handlers can be assured calling user and org are $STATUS_ACTIVE
# see perldocs for more info
sub with_session_ ( $c ) {
    $c->stash( $STASH_AUTH => $AUTH_NONE );

    # X-GrokLOC-ID header must be present in order to look up the user
    unless ( $c->req->headers->header($X_GROKLOC_ID) ) {
        return $c->render(
            app_msg( 400, { error => 'missing:' . $X_GROKLOC_ID } ) );
    }
    my $user_id = $c->req->headers->header($X_GROKLOC_ID);
    my $user;
    try {
        $user = GrokLOC::Models::User::read( $c->st->random_replica(),
            $c->st->key, $user_id );
    }
    catch ($e) {
        $c->app->log->error("internal error reading user $user_id:$e");
        $c->render( app_msg( 500, { error => 'internal error' } ) );
        return;
    }

    if ( !defined($user) || $user->meta->status != $STATUS_ACTIVE ) {
        return $c->render( app_msg( 400, { error => 'user not found' } ) );
    }

    my $org;
    try {
        $org =
          GrokLOC::Models::Org::read( $c->st->random_replica(), $user->org );
    }
    catch ($e) {
        $c->app->log->error("internal error reading org:$user->org:$e");
        $c->render( app_msg( 500, { error => 'internal error' } ) );
        return;
    }
    if ( !defined($org) || $org->meta->status != $STATUS_ACTIVE ) {
        return $c->render( app_msg( 400, { error => 'org not found' } ) );
    }

    my $auth_level = $AUTH_USER;
    if ( $org->id eq $c->st->root_org ) {

        # allow for multiple accounts in root org
        $auth_level = $AUTH_ROOT;
    }
    elsif ( $org->owner eq $user->id ) {
        $auth_level = $AUTH_ORG;
    }

    $c->stash( $STASH_AUTH => $auth_level );
    $c->stash( $STASH_ORG  => $org );
    $c->stash( $STASH_USER => $user );
    return 1;
}

# with_token_ calls to with_session but also requires that the auth
# level include a token setting (user, org or root) to continue
## no critic (RequireFinalReturn)
sub with_token_ ( $c ) {
    unless ( $c->with_session_ ) {
        $c->app->log->error('inlined call to with_session failed');
        return;
    }

    unless ( $c->req->headers->header($AUTHORIZATION) ) {
        return $c->render(
            app_msg( 400, { error => 'missing ' . $AUTHORIZATION } ) );
    }

    try {
        my $encoded =
          token_from_header_val( $c->req->headers->header($AUTHORIZATION) );
        my $decoded = decode_token( $encoded, $c->st->key );
        unless ( $decoded->{'sub'} eq $c->stash($STASH_USER)->id ) {
            return $c->render(
                app_msg( 400, { error => 'token contents incorrect' } ) );
        }
        my $now = time;
        if ( $decoded->{exp} < $now ) {
            return $c->render( app_msg( 400, { error => 'token expired' } ) );
        }
    }
    catch ($e) {
        $c->app->log->info( 'token decode:' . $e );
        return $c->render( app_msg( 400, { error => 'token decode error' } ) );
    }

    return 1;
}

# new_token mints a new jwt for a user if the token request header
# validates
# should be treated as a POST handler since a new jwt is always
# minted, but note that unlike typical POSTs, there is no redirect or Location
# header in the response, only the value of the jwt
sub new_token_ ( $c ) {
    my $token_request = $c->req->headers->header($X_GROKLOC_TOKEN_REQUEST);
    unless ( defined $token_request ) {
        return $c->render(
            app_msg( 400, { error => 'missing:' . $X_GROKLOC_TOKEN_REQUEST } )
        );
    }

    my $calling_user = $c->stash($STASH_USER);
    unless (
        verify_token_request(
            $token_request, $calling_user->id, $calling_user->api_secret
        )
      )
    {
        return $c->render( app_msg( 401, { error => 'bad token request' } ) );
    }

    my $now = time;
    my $token;
    try {
        $token = encode_token( $calling_user->id, $c->st->key );
    }
    catch ($e) {
        $c->app->log->error(
            "cannot encode token for user:$calling_user->id:$e");
        $c->render( app_msg( 500, { error => 'internal error' } ) );
        return;
    }

    $c->app->log->info( 'new token for user ' . $calling_user->id );
    return $c->render(
        app_msg(
            200,
            {
                token   => $token,
                expires => $now + $JWT_EXPIRATION - 30,
            }
        )
    );
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
  - If the user is not active, immediately return 400.
  - If the org is not active, immediately return 400.
  - Otherwise: 
    - Set the stash references to the user and org model instances.
    - Set the stash auth level to AUTH_USER, AUTH_ORG or AUTH_ROOT
- If the X-GrokLOC-Token header is found, validate the JWT.
  - If the JWT is unparseable, return 400.
  - If the JWT is not valid or expired, immediately return 400.

=cut
