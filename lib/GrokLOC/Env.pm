package GrokLOC::Env;
use strictures 2;
use Readonly;

# ABSTRACT: Environment settings for GrokLOC.

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

use base qw(Exporter);

# Env vars.
Readonly::Scalar our $GROKLOC_ENV => 'GROKLOC_ENV';
Readonly::Scalar our $ROOT_ORG    => 'ROOT_ORG';
Readonly::Scalar our $ENCRYPT_KEY => 'ENCRYPT_KEY';
Readonly::Scalar our $SIGN_KEY    => 'SIGN_KEY';

# Run levels.
Readonly::Scalar our $UNIT  => 'UNIT';
Readonly::Scalar our $DEV   => 'DEV';
Readonly::Scalar our $STAGE => 'STAGE';
Readonly::Scalar our $PROD  => 'PROD';

Readonly::Array our @LEVELS => ( $UNIT, $DEV, $STAGE, $PROD );

our @EXPORT_OK =
  qw($GROKLOC_ENV $ROOT_ORG $ENCRYPT_KEY $SIGN_KEY $UNIT $DEV $STAGE $PROD @LEVELS);
our %EXPORT_TAGS = (
    all => [
        qw($GROKLOC_ENV $ROOT_ORG $ENCRYPT_KEY $SIGN_KEY $UNIT $DEV $STAGE $PROD @LEVELS)
    ]
);

1;

__END__

=head1 NAME

GrokLOC::Env

=head1 SYNOPSIS

Environment variables and system constants.

=head1 DESCRIPTION

Environment variables and system constants.

=cut
