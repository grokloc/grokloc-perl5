package App::Controller::Api::V0::Auth;
use strictures 2;
use Mojo::Base 'Mojolicious::Controller';
use experimental qw(signatures);

# ABSTRACT: Auth middleware for populating the stash.

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

sub with_session( $c ) {
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
