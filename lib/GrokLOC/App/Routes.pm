package GrokLOC::App::Routes;
use strictures 2;
use Exporter;
use Readonly;

# ABSTRACT: Route definitions.

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

use base qw(Exporter);

Readonly::Scalar our $API         => '/api';
Readonly::Scalar our $API_VERSION => '/v0';
Readonly::Scalar our $OK          => '/ok';
Readonly::Scalar our $OK_ROUTE    => $API . $VERSION . $OK;

Readonly::Array our @ROUTES => ($OK_ROUTE);

our @EXPORT_OK   = qw($API $API_VERSION $OK $OK_ROUTE @ROUTES);
our %EXPORT_TAGS = (
    all => [
        qw(
          $API
          $API_VERSION
          $OK
          $OK_ROUTE
          @ROUTES
          )
    ],
    routes => [
        qw(
          $OK_ROUTE
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
