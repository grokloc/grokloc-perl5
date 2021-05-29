package App::Controller::Api::V0::User;
use strictures 2;
use Crypt::Misc qw(random_v4uuid);
use Mojo::Base 'Mojolicious::Controller';
use experimental qw(signatures try);
use GrokLOC::App qw(:all);
use GrokLOC::App::Message qw(app_msg);
use GrokLOC::App::Routes qw(:routes);
use GrokLOC::Models qw(:all);
use GrokLOC::Models::User;

# ABSTRACT: User operations.

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

sub create_ ( $c ) {

    # only root or a org owner can create a user
    if ( $c->stash($STASH_AUTH) == $TOKEN_USER ) {
        return $c->render(
            app_msg( 403, { error => 'inadequate authorization' } ) );
    }

    my %user_args = %{ $c->req->json };
    unless ( 4 == scalar keys %user_args ) {
        return $c->render( app_msg( 400, { error => 'malformed user args' } ) );
    }
    for my $k (qw(display_name email org password)) {
        unless ( exists $user_args{$k} ) {
            return $c->render(
                app_msg( 400, { error => 'malformed user args' } ) );
        }
    }

    # if caller is an org owner, must be in same org as prospective new user
    if ( $c->stash($STASH_AUTH) == $TOKEN_ORG ) {
        my $calling_user = $c->stash($STASH_USER);
        if ( $calling_user->org != $user_args{org} ) {
            return $c->render(
                app_msg( 403, { error => 'inadequate authorization' } ) );
        }
    }

    my $user;
    try {
        $user = GrokLOC::Models::User->new(
            display_name => $user_args{display_name},
            email        => $user_args{email},
            org          => $user_args{org},
            password     => kdf(
                $user_args{password}, salt(random_v4uuid),
                $c->st->kdf_iterations
            ),
        );
    }
    catch ($e) {
        $c->app->log->error( 'internal error creating user:' . $e );
        return $c->render( app_msg( 500, { error => 'internal error' } ) );
    }

    my $result;
    try {
        $result = $user->insert( $c->st->master );
    }
    catch ($e) {
        $c->app->log->error( 'internal error inserting user:' . $e );
        return $c->render( app_msg( 500, { error => 'internal error' } ) );
    }

    if ( $RESPONSE_OK == $result ) {
        $c->res->headers->header( 'Location' => "$USER_ROUTE/" . $user->id );
        return $c->render( app_msg( 201, { status => 'created' } ) );
    }
    if ( $RESPONSE_CONFLICT == $result ) {
        return $c->render( app_msg( 409, { error => 'conflict' } ) );
    }
    $c->app->log->error('unknown internal error inserting org');
    return $c->render( app_msg( 500, { error => 'internal error' } ) );
}

1;

__END__

=head1 NAME

App::Controller::Api::V0::User

=head1 SYNOPSIS

User operations.

=head1 DESCRIPTION

User operations.

=cut
