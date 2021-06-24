package GrokLOC::App;
use strictures 2;
use Exporter;
use Readonly ();

# ABSTRACT: App symbols.

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

use base qw(Exporter);

# headers
Readonly::Scalar our $X_GROKLOC_ID            => 'X-GrokLOC-ID';
Readonly::Scalar our $X_GROKLOC_TOKEN_REQUEST => 'X-GrokLOC-Token-Request';

# auth levels set in the request stash. If you need the request to have a
# valid JWT, check for $level >= $TOKEN_USER
# must always be monotonically increasing!
Readonly::Scalar our $AUTH_NONE => 0;    # Nothing.
Readonly::Scalar our $AUTH_USER => 1;    # User valid from db, no JWT.
Readonly::Scalar our $AUTH_ORG  => 2;    # Org owner valid from db, no JWT.
Readonly::Scalar our $AUTH_ROOT => 3;    # Root org user valid from db, no JWT.

# stash keys
Readonly::Scalar our $STASH_AUTH => 'auth';
Readonly::Scalar our $STASH_USER => 'user';
Readonly::Scalar our $STASH_ORG  => 'org';

our @EXPORT_OK =
  qw($X_GROKLOC_ID $X_GROKLOC_TOKEN_REQUEST $AUTH_NONE $AUTH_USER $AUTH_ORG $AUTH_ROOT $STASH_AUTH $STASH_USER $STASH_ORG);
our %EXPORT_TAGS = (
    headers     => [qw($X_GROKLOC_ID $X_GROKLOC_TOKEN_REQUEST)],
    auth_levels => [qw($AUTH_NONE $AUTH_USER $AUTH_ORG $AUTH_ROOT)],
    stash_keys  => [qw($STASH_AUTH $STASH_USER $STASH_ORG)],
    all         => [
        qw($X_GROKLOC_ID $X_GROKLOC_TOKEN_REQUEST $AUTH_NONE $AUTH_USER $AUTH_ORG $AUTH_ROOT $STASH_AUTH $STASH_USER $STASH_ORG)
    ],
);

1;

__END__

=head1 NAME 

GrokLOC::App

=head1 SYNOPSIS

App symbols.

=head1 DESCRIPTION

App symbols.

=cut
