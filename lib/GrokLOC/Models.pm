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

our @EXPORT_OK =
  qw($STATUS_UNCONFIRMED $STATUS_ACTIVE $STATUS_INACTIVE $STATUS_ADMIN);
our %EXPORT_TAGS = ( all =>
      [qw($STATUS_UNCONFIRMED $STATUS_ACTIVE $STATUS_INACTIVE $STATUS_ADMIN)] );

1;

__END__

=head1 NAME

GrokLOC::Models

=head1 SYNOPSIS

Core model definitions.

=head1 DESCRIPTION

Core model definitions.

=cut
