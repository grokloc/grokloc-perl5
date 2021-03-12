package GrokLOC::Models;
use strictures 2;
use Readonly;

# ABSTRACT: Core model definitions.

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

use base qw(Exporter);

Readonly::Scalar our $STATUS_UNCONFIRMED => 0;
Readonly::Scalar our $STATUS_ACTIVE      => 1;
Readonly::Scalar our $STATUS_INACTIVE    => 2;
Readonly::Scalar our $STATUS_ADMIN       => 4;

Readonly::Scalar our $RESPONSE_OK        => 0;
Readonly::Scalar our $RESPONSE_NOT_FOUND => 1;
Readonly::Scalar our $RESPONSE_CONFLICT  => 2;
Readonly::Scalar our $RESPONSE_NO_ROWS   => 3;

Readonly::Scalar our $NO_OWNER => 'no.owner';

our @EXPORT_OK =
  qw($STATUS_UNCONFIRMED $STATUS_ACTIVE $STATUS_INACTIVE $STATUS_ADMIN $NO_OWNER $RESPONSE_OK $RESPONSE_NOT_FOUND $RESPONSE_CONFLICT $RESPONSE_NO_ROWS);
our %EXPORT_TAGS = (
    all => [
        qw($STATUS_UNCONFIRMED $STATUS_ACTIVE $STATUS_INACTIVE $STATUS_ADMIN $NO_OWNER $RESPONSE_OK $RESPONSE_NOT_FOUND $RESPONSE_CONFLICT $RESPONSE_NO_ROWS)
    ]
);

1;

__END__

=head1 NAME

GrokLOC::Models

=head1 SYNOPSIS

Core model definitions.

=head1 DESCRIPTION

Core model definitions.

=cut
