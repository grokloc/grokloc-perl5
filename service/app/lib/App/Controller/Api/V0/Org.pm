package App::Controller::Api::V0::Org;
use strictures 2;
use Mojo::Base 'Mojolicious::Controller';
use experimental qw(signatures try);
use GrokLOC::App qw(:all);
use GrokLOC::App::Routes qw(:routes);
use GrokLOC::Models qw(:all);
use GrokLOC::Models::Org;

# ABSTRACT: Org operations.

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

sub create ( $c ) {
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

    $c->res->headers->header( 'Location' => "$ORG_ROUTE/$org->id" );
    $c->render( app_msg( 201, { status => 'created' } ) );
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
