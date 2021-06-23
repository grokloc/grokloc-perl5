package GrokLOC::Models;
use strictures 2;
use Carp qw( croak );
use Readonly ();
use experimental qw(signatures);
use GrokLOC::Security::Input qw( safe_objs );

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

sub safe_status ( $status ) {
    return if ( $status !~ /^\d+$/msx );
    return if ( $status < $STATUS_UNCONFIRMED );
    return if ( $status > $STATUS_ADMIN );
    return 1;
}

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

# update_status for any model
sub update_status ( $master, $tablename, $id, $status ) {
    croak 'status invalid' unless safe_status($status);
    return update( $master, $tablename, $id, { status => $status } );
}

# update columns for a given id in tablename
# fieldals is a hashref
sub update ( $master, $tablename, $id, $fieldvals ) {
    croak 'db ref'
      unless safe_objs( [$master], [ 'Mojo::SQLite', 'Mojo::Pg' ] );
    croak 'fieldvals must be hashref' unless ( ref $fieldvals eq 'HASH' );
    my $rows =
      $master->db->update( $tablename, $fieldvals, { id => $id } )->rows;
    croak 'update altered more than one row' if ( $rows > 1 );
    return $RESPONSE_NO_ROWS                 if ( $rows == 0 );
    return $RESPONSE_OK;
}

our @EXPORT_OK =
  qw($STATUS_UNCONFIRMED $STATUS_ACTIVE $STATUS_INACTIVE $STATUS_ADMIN @STATUSES $RESPONSE_OK $RESPONSE_NOT_FOUND $RESPONSE_CONFLICT $RESPONSE_NO_ROWS $RESPONSE_ORG_ERR $RESPONSE_USER_ERR $NO_OWNER $ORGS_TABLENAME $USERS_TABLENAME safe_status);
our %EXPORT_TAGS = (
    all => [
        qw($STATUS_UNCONFIRMED $STATUS_ACTIVE $STATUS_INACTIVE $STATUS_ADMIN @STATUSES $RESPONSE_OK $RESPONSE_NOT_FOUND $RESPONSE_CONFLICT $RESPONSE_NO_ROWS $RESPONSE_ORG_ERR $RESPONSE_USER_ERR $NO_OWNER $ORGS_TABLENAME $USERS_TABLENAME safe_status)
    ],
    validators => [qw(safe_status)],
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
