package GrokLOC::Models;
use strictures 2;
use Readonly;

# ABSTRACT: Core model definitions.

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

use base qw(Exporter);

# Table status values.
Readonly::Scalar our $STATUS_UNCONFIRMED => 1;
Readonly::Scalar our $STATUS_ACTIVE      => 2;
Readonly::Scalar our $STATUS_INACTIVE    => 3;
Readonly::Scalar our $STATUS_ADMIN       => 4;

our @STATUSES =
  ( $STATUS_UNCONFIRMED, $STATUS_ACTIVE, $STATUS_INACTIVE, $STATUS_ADMIN );

# API response indicators.
Readonly::Scalar our $RESPONSE_OK        => 1;
Readonly::Scalar our $RESPONSE_NOT_FOUND => 2;
Readonly::Scalar our $RESPONSE_CONFLICT  => 3;
Readonly::Scalar our $RESPONSE_NO_ROWS   => 4;
Readonly::Scalar our $RESPONSE_ORG_ERR   => 5;
Readonly::Scalar our $RESPONSE_USER_ERR  => 6;

Readonly::Scalar our $NO_OWNER => 'no.owner';

Readonly::Scalar our $ORGS_TABLENAME  => 'orgs';
Readonly::Scalar our $USERS_TABLENAME => 'users';

our @EXPORT_OK =
  qw($STATUS_UNCONFIRMED $STATUS_ACTIVE $STATUS_INACTIVE $STATUS_ADMIN @STATUSES $RESPONSE_OK $RESPONSE_NOT_FOUND $RESPONSE_CONFLICT $RESPONSE_NO_ROWS $RESPONSE_ORG_ERR $RESPONSE_USER_ERR $NO_OWNER $ORGS_TABLENAME $USERS_TABLENAME);
our %EXPORT_TAGS = (
    all => [
        qw($STATUS_UNCONFIRMED $STATUS_ACTIVE $STATUS_INACTIVE $STATUS_ADMIN @STATUSES $RESPONSE_OK $RESPONSE_NOT_FOUND $RESPONSE_CONFLICT $RESPONSE_NO_ROWS $RESPONSE_ORG_ERR $RESPONSE_USER_ERR $NO_OWNER $ORGS_TABLENAME $USERS_TABLENAME)
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
