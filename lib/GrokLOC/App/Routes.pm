package GrokLOC::App::Routes;
use strictures 2;
use Exporter;
use Readonly;

# ABSTRACT: Route definitions.

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

use base qw(Exporter);

Readonly::Scalar our $API                 => '/api';
Readonly::Scalar our $API_VERSION         => '/v0';
Readonly::Scalar our $OK                  => '/ok';
Readonly::Scalar our $OK_ROUTE            => $API . $VERSION . $OK;
Readonly::Scalar our $TOKEN_REQUEST       => '/token';
Readonly::Scalar our $TOKEN_REQUEST_ROUTE => $API . $VERSION . $TOKEN_REQUEST;

Readonly::Array our @ROUTES => ( $OK_ROUTE, $TOKEN_REQUEST_ROUTE );

our @EXPORT_OK =
  qw($API $API_VERSION $OK $OK_ROUTE $TOKEN_REQUEST $TOKEN_REQUEST_ROUTE @ROUTES);
our %EXPORT_TAGS = (
    all => [
        qw(
          $API
          $API_VERSION
          $OK
          $OK_ROUTE
          $TOKEN_REQUEST
          $TOKEN_REQUEST_ROUTE
          @ROUTES
          )
    ],
    routes => [
        qw(
          $OK_ROUTE
          $TOKEN_REQUEST_ROUTE
          @ROUTES
          )
    ]
);

1;

__END__

=head1 NAME 

GrokLOC::App::Routes

=head1 SYNOPSIS

Route definitions.

=head1 DESCRIPTION

Route definitions.

=cut
