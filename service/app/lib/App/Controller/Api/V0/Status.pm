package App::Controller::Api::V0::Status;
use strictures 2;
use Mojo::Base 'Mojolicious::Controller';
use experimental qw(signatures);
use GrokLOC::App qw(:all);
use GrokLOC::App::Message qw(app_msg);

# ABSTRACT: Status handler.

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

# status should be authenticated for root only.
sub status ( $c ) {
    unless ( defined $c->stash($STASH_AUTH) ) {
        $c->app->log->error( 'missing stash key ' . $STASH_AUTH );
        $c->render( app_msg( 500, { error => 'internal error' } ) );
        return;
    }
    if ( $c->stash($STASH_AUTH) != $TOKEN_ROOT ) {
        $c->render( app_msg( 403, { error => 'inadequate authorization' } ) );
        return;
    }
    $c->render( app_msg( 200, { started_at => $c->started_at } ) );
    return 1;
}

1;

__END__

=head1 NAME

App::Controller::Api::V0::Status

=head1 SYNOPSIS

Status handler.

=head1 DESCRIPTION

Status handler.

=cut
