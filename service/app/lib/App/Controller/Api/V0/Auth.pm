package App::Controller::Api::V0::Auth;
use strictures 2;
use Mojo::Base 'Mojolicious::Controller';
use Syntax::Keyword::Try qw(try catch :experimental);
use experimental qw(signatures);
use GrokLOC::App qw(:all);
use GrokLOC::Models qw(:all);
use GrokLOC::Models::Org;
use GrokLOC::Models::User;

# ABSTRACT: Auth middleware for populating the stash.

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

sub with_session( $c ) {
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
          GrokLOC::Models::User->read( $c->st->random_replica(), $user_id );
    }
    catch ($e) {
        $c->app->log->error( 'internal error reading user ' . $user_id );
        $c->render( app_msg( 500, { error => 'internal error' } ) );
        return;
    }
    if ( !defined($user) || $user->_meta->status != $STATUS_ACTIVE ) {
        $c->render( app_msg( 404, { error => 'user not found' } ) );
        return;
    }
    my $org;
    try {
        $org =
          GrokLOC::Models::Org->read( $c->st->random_replica(), $user->org );
    }
    catch ($e) {
        $c->app->log->error( 'internal error reading org ' . $user->org );
        $c->render( app_msg( 500, { error => 'internal error' } ) );
        return;
    }
    if ( !defined($org) || $org->_meta->status != $STATUS_ACTIVE ) {
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

    if ( !$c->req->headers->header($X_GROKLOC_TOKEN) ) {
        # Need to fill in jwt libs.
    }
    $c->stash( $STASH_AUTH => $auth_level );
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
