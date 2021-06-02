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
use GrokLOC::Security::Crypt qw(:all);
use GrokLOC::Security::Input qw(:validators);

# ABSTRACT: User operations.

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

sub create_ ( $c ) {

    # only root or a org owner can create a user
    if ( $c->stash($STASH_AUTH) == $TOKEN_USER ) {
        return $c->render(
            app_msg( 403, { error => 'inadequate authorization' } ) );
    }

    # check args
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

    # never add to the root org through the web api
    if ( $user_args{org} eq $c->st->root_org ) {
        return $c->render( app_msg( 403, { error => 'prohibited org arg' } ) );
    }

    # if caller is an org owner, must be in same org as prospective new user
    if ( $c->stash($STASH_AUTH) == $TOKEN_ORG ) {
        my $calling_user = $c->stash($STASH_USER);
        if ( $calling_user->org ne $user_args{org} ) {
            return $c->render(
                app_msg( 403, { error => 'inadequate authorization' } ) );
        }
    }

    # derive password
    my $derived =
      kdf( $user_args{password}, salt(random_v4uuid), $c->st->kdf_iterations );

    # make obj
    my $user;
    try {
        $user = GrokLOC::Models::User->new(
            display_name => $user_args{display_name},
            email        => $user_args{email},
            org          => $user_args{org},
            password     => $derived,
        );
    }
    catch ($e) {
        $c->app->log->error( 'internal error creating user:' . $e );
        return $c->render( app_msg( 500, { error => 'internal error' } ) );
    }

    # insert
    my $result;
    try {
        $result = $user->insert( $c->st->master, $c->st->key );
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
    if ( $RESPONSE_ORG_ERR == $result ) {
        return $c->render( app_msg( 400, { error => 'org error' } ) );
    }
    $c->app->log->error('unknown internal error inserting org');
    return $c->render( app_msg( 500, { error => 'internal error' } ) );
}

sub read_ ( $c ) {

    # regular user can only read themselves, we already know calling_user
    # is active or auth would have returned 404
    if ( $c->stash($STASH_AUTH) == $TOKEN_USER ) {
        my $calling_user = $c->stash($STASH_USER);
        if ( $c->param('id') ne $calling_user->id ) {
            return $c->render(
                app_msg( 403, { error => 'inadequate authorization' } ) );
        }

        return $c->render( app_msg( 200, $calling_user->TO_JSON() ) );
    }

    my $user;
    try {
        $user = GrokLOC::Models::User::read( $c->st->random_replica(),
            $c->st->key, $c->param('id') );
    }
    catch ($e) {
        $c->app->log->error(
            'internal error reading user:' . $c->param('id') . ":$e" );
        return $c->render( app_msg( 500, { error => 'internal error' } ) );
    }

    if ( !defined $user ) {
        return $c->render( app_msg( 404, { error => 'not found' } ) );
    }

    if ( $c->stash($STASH_AUTH) == $TOKEN_ORG ) {

        # org owner must be in same org as user being read
        my $calling_user = $c->stash($STASH_USER);
        if ( $user->org ne $calling_user->org ) {
            return $c->render(
                app_msg( 403, { error => 'inadequate authorization' } ) );
        }
    }

    # otherwise, is root or is owner of $user's org, so return user even if
    # not active
    $c->render( app_msg( 200, $user->TO_JSON() ) );
    return 1;
}

sub update_ ( $c ) {

    my %user_args = %{ $c->req->json };

    # regular user can only update themselves (but NOT status),
    if ( $c->stash($STASH_AUTH) == $TOKEN_USER ) {
        my $calling_user = $c->stash($STASH_USER);
        if ( $c->param('id') ne $calling_user->id ) {
            return $c->render(
                app_msg( 403, { error => 'inadequate authorization' } ) );
        }
        if ( exists $user_args{status} ) {
            return $c->render(
                app_msg( 403, { error => 'cannot modify own status' } ) );
        }
    }

    my $user;
    if ( $c->stash($STASH_AUTH) == $TOKEN_USER ) {

        # target user is same as the one auth'd
        $user = $c->stash($STASH_USER);
    }
    else {
        # org owner or root, so must read user in
        try {
            $user = GrokLOC::Models::User::read( $c->st->random_replica(),
                $c->st->key, $c->param('id') );
        }
        catch ($e) {
            $c->app->log->error(
                'internal error reading user:' . $c->param('id') . ":$e" );
            return $c->render( app_msg( 500, { error => 'internal error' } ) );
        }

        unless ( defined $user ) {
            return $c->render( app_msg( 404, { error => 'not found' } ) );
        }
    }

    if ( $c->stash($STASH_AUTH) == $TOKEN_ORG ) {

        # org owner must be in same org as user
        my $calling_user = $c->stash($STASH_USER);
        if ( $user->org ne $calling_user->org ) {
            return $c->render(
                app_msg( 403, { error => 'inadequate authorization' } ) );
        }
    }

    # else - root or other auth preconditions satisfied

    # check args
    if ( 1 != scalar keys %user_args ) {
        return $c->render(
            app_msg( 400, { error => 'only one user updated permitted' } ) );
    }

    if ( exists $user_args{status} ) {
        unless ( safe_status( $user_args{status} ) ) {
            return $c->render(
                app_msg( 400, { error => 'malformed status' } ) );
        }
    }
    else {
        for my $k ( keys %user_args ) {
            unless ( safe_str( $user_args{$k} ) ) {
                return $c->render(
                    app_msg( 400, { error => "malformed $k" } ) );
            }
        }
    }

    # do update
    my $result;
    try {
        if ( exists $user_args{display_name} ) {
            $result = $user->update_display_name( $c->st->master, $c->st->key,
                $user_args{display_name} );
        }
        elsif ( exists $user_args{password} ) {
            my $derived =
              kdf( $user_args{password},
                salt(random_v4uuid), $c->st->kdf_iterations );
            $result = $user->update_status( $c->st->master, $derived );
        }
        elsif ( exists $user_args{status} ) {
            $result =
              $user->update_status( $c->st->master, $user_args{status} );
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
        'internal error updating user:' . $c->param('id') . ":$result" );
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
