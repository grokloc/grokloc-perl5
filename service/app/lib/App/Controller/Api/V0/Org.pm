package App::Controller::Api::V0::Org;
use strictures 2;
use Mojo::Base 'Mojolicious::Controller';
use experimental qw(signatures try);
use GrokLOC::App qw(:all);
use GrokLOC::App::Message qw(app_msg);
use GrokLOC::App::Routes qw(:routes);
use GrokLOC::Models qw(:all);
use GrokLOC::Models::Org;
use GrokLOC::Security::Input qw(:validators);

# ABSTRACT: Org operations.

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

sub create_ ( $c ) {

    # only root can create an org
    if ( $c->stash($STASH_AUTH) != $TOKEN_ROOT ) {
        return $c->render(
            app_msg( 403, { error => 'inadequate authorization' } ) );
    }

    # check args
    my %org_args = %{ $c->req->json };
    unless ( 1 == scalar keys %org_args && exists $org_args{name} ) {
        return $c->render( app_msg( 400, { error => 'malformed org args' } ) );
    }

    # make obj
    my $org;
    try {
        $org = GrokLOC::Models::Org->new( name => $org_args{name} );
    }
    catch ($e) {
        $c->app->log->error( 'internal error creating org:' . $e );
        return $c->render( app_msg( 500, { error => 'internal error' } ) );
    }

    # insert
    my $result;
    try {
        $result = $org->insert( $c->st->master );
    }
    catch ($e) {
        $c->app->log->error( 'internal error inserting org:' . $e );
        return $c->render( app_msg( 500, { error => 'internal error' } ) );
    }

    if ( $RESPONSE_OK == $result ) {
        $c->res->headers->header( 'Location' => "$ORG_ROUTE/" . $org->id );
        return $c->render( app_msg( 201, { status => 'created' } ) );
    }
    if ( $RESPONSE_CONFLICT == $result ) {
        return $c->render( app_msg( 409, { error => 'conflict' } ) );
    }
    $c->app->log->error('unknown internal error inserting org');
    return $c->render( app_msg( 500, { error => 'internal error' } ) );
}

sub read_ ( $c ) {

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
            return $c->render( app_msg( 500, { error => 'internal error' } ) );
        }

        if ( !defined $org ) {
            return $c->render( app_msg( 404, { error => 'not found' } ) );
        }

        return $c->render( app_msg( 200, $org->TO_JSON() ) );
    }

    # otherwise, a regular user or org owner

    # if caller is not root, it can only read its own org (which is stashed)
    my $calling_org = $c->stash($STASH_ORG);
    if ( $c->param('id') ne $calling_org->id ) {
        return $c->render(
            app_msg( 403, { error => 'not a member of requested org' } ) );
    }

    return $c->render( app_msg( 200, $calling_org->TO_JSON() ) );
}

sub update_ ( $c ) {

    # only root can update an org
    if ( $c->stash($STASH_AUTH) != $TOKEN_ROOT ) {
        return $c->render(
            app_msg( 403, { error => 'inadequate authorization' } ) );
    }

    my $org;
    try {
        $org = GrokLOC::Models::Org::read( $c->st->random_replica(),
            $c->param('id') );
    }
    catch ($e) {
        $c->app->log->error(
            'internal error reading org:' . $c->param('id') . ":$e" );
        return $c->render( app_msg( 500, { error => 'internal error' } ) );
    }

    unless ( defined $org ) {
        return $c->render( app_msg( 404, { error => 'not found' } ) );
    }

    # check args
    my %org_args = %{ $c->req->json };
    if ( 1 != scalar keys %org_args ) {
        return $c->render(
            app_msg( 400, { error => 'only one org updated permitted' } ) );
    }

    if ( exists $org_args{status} ) {
        unless ( safe_status( $org_args{status} ) ) {
            return $c->render(
                app_msg( 400, { error => 'malformed status' } ) );
        }
    }
    else {
        for my $k ( keys %org_args ) {
            unless ( safe_str( $org_args{$k} ) ) {
                return $c->render(
                    app_msg( 400, { error => "malformed $k" } ) );
            }
        }
    }

    # do update
    my $result;
    try {
        if ( exists $org_args{owner} ) {
            $result = $org->update_owner( $c->st->master, $org_args{owner} );
        }
        elsif ( exists $org_args{status} ) {
            $result = $org->update_status( $c->st->master, $org_args{status} );
        }
        else {
            return $c->render(
                app_msg( 400, { error => 'unsupported update attribute' } ) );
        }
    }
    catch ($e) {
        $c->app->log->error(
            'internal error updating org:' . $c->param('id') . ":$e" );
        return $c->render( app_msg( 500, { error => 'internal error' } ) );
    }

    if ( $RESPONSE_OK == $result ) {
        return $c->rendered(204);
    }
    if ( $RESPONSE_NO_ROWS == $result ) {
        return $c->render( app_msg( 404, { error => 'no rows updated' } ) );
    }
    if ( $RESPONSE_USER_ERR == $result ) {
        return $c->render( app_msg( 400, { error => 'user error' } ) );
    }

    $c->app->log->error(
        'internal error updating org:' . $c->param('id') . ":$result-" );
    return $c->render( app_msg( 500, { error => 'internal error' } ) );
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
