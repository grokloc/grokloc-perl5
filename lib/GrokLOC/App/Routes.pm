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
Readonly::Scalar our $API_ROUTE           => $API . $API_VERSION;
Readonly::Scalar our $OK                  => '/ok';
Readonly::Scalar our $OK_ROUTE            => $API_ROUTE . $OK;
Readonly::Scalar our $ORG                 => '/org';
Readonly::Scalar our $ORG_ROUTE           => $API_ROUTE . $ORG;
Readonly::Scalar our $STATUS              => '/status';
Readonly::Scalar our $STATUS_ROUTE        => $API_ROUTE . $STATUS;
Readonly::Scalar our $TOKEN_REQUEST       => '/token';
Readonly::Scalar our $TOKEN_REQUEST_ROUTE => $API_ROUTE . $TOKEN_REQUEST;

Readonly::Array our @ROUTES =>
  ( $API_ROUTE, $OK_ROUTE, $ORG_ROUTE, $STATUS_ROUTE, $TOKEN_REQUEST_ROUTE );

our @EXPORT_OK =
  qw($API $API_VERSION $API_ROUTE $OK $OK_ROUTE $ORG $ORG_ROUTE $STATUS $STATUS_ROUTE $TOKEN_REQUEST $TOKEN_REQUEST_ROUTE @ROUTES);
our %EXPORT_TAGS = (
    all => [
        qw(
          $API
          $API_VERSION
          $API_ROUTE
          $OK
          $OK_ROUTE
          $ORG
          $ORG_ROUTE
          $STATUS
          $STATUS_ROUTE
          $TOKEN_REQUEST
          $TOKEN_REQUEST_ROUTE
          @ROUTES
        )
    ],
    routes => [
        qw(
          $API_ROUTE
          $OK_ROUTE
          $ORG_ROUTE
          $STATUS_ROUTE
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
