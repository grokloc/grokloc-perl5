package App::Controller::Api::V0::Org;
use strictures 2;
use Mojo::Base 'Mojolicious::Controller';
use experimental qw(signatures try);
use GrokLOC::App qw(:all);
use GrokLOC::App::Message qw(app_msg);
use GrokLOC::App::Routes qw(:routes);
use GrokLOC::Models qw(:all);
use GrokLOC::Models::Org;

# ABSTRACT: Org operations.

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

sub create_ ( $c ) {
    unless ( defined $c->stash($STASH_AUTH) ) {
        $c->app->log->error( 'missing stash key ' . $STASH_AUTH );
        $c->render( app_msg( 500, { error => 'internal error' } ) );
        return;
    }

    # Only root can create an org.
    if ( $c->stash($STASH_AUTH) != $TOKEN_ROOT ) {
        $c->render( app_msg( 403, { error => 'inadequate authorization' } ) );
        return;
    }

    my %org_args = %{ $c->req->json };
    unless ( 1 == scalar keys %org_args && exists $org_args{name} ) {
        $c->render( app_msg( 400, { error => 'malformed org args' } ) );
        return;
    }

    my $org;
    try {
        $org = GrokLOC::Models::Org->new( name => $org_args{name} );
    }
    catch ($e) {
        $c->app->log->error( 'internal error creating org:' . $e );
        $c->render( app_msg( 500, { error => 'internal error' } ) );
        return;
    }

    my $result;
    try {
        $result = $org->insert( $c->st->master );
    }
    catch ($e) {
        $c->app->log->error( 'internal error inserting org:' . $e );
        $c->render( app_msg( 500, { error => 'internal error' } ) );
        return;
    }

    if ( $RESPONSE_CONFLICT == $result ) {
        $c->render( app_msg( 409, { error => 'conflict' } ) );
        return;
    }
    if ( $RESPONSE_OK != $result ) {
        $c->app->log->error('unknown internal error inserting org');
        $c->render( app_msg( 500, { error => 'internal error' } ) );
        return;
    }

    $c->res->headers->header( 'Location' => "$ORG_ROUTE/" . $org->id );
    $c->render( app_msg( 201, { status => 'created' } ) );
    return 1;
}

sub read_ ( $c ) {
    unless ( defined $c->stash($STASH_AUTH) ) {
        $c->app->log->error( 'missing stash key ' . $STASH_AUTH );
        $c->render( app_msg( 500, { error => 'internal error' } ) );
        return;
    }

    # if root is the caller, the stashed org is the root_org,
    # so read the requested org
    if ( $c->stash($STASH_AUTH) == $TOKEN_ROOT ) {
        my $org;
        try {
            $org = GrokLOC::Models::Org::read( $c->st->random_replica(),
                $c->param('id') );
        }
        catch ($e) {
            $c->app->log->error(
                'internal error reading org:' . $c->param('id') . ":$e" );
            $c->render( app_msg( 500, { error => 'internal error' } ) );
            return;
        }
        $c->render( app_msg( 200, $org->TO_JSON() ) );
        return 1;
    }

    # if caller is not root, it can only read its own org (which is stashed)
    my $calling_org = $c->stash($STASH_ORG);
    if ( $c->param('id') ne $calling_org->id ) {
        $c->app->log->error('not a member of requested org');
        $c->render(
            app_msg( 403, { error => 'not a member of requested org' } ) );
        return;
    }

    # the org was already read during auth, so just return it
    $c->render( app_msg( 200, $calling_org->TO_JSON() ) );
    return 1;
}

1;

__END__

=head1 NAME

App::Controller::Api::V0::Org

=head1 SYNOPSIS

Org operations.

=head1 DESCRIPTION

Org operations.

=cut
