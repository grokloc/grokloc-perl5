package GrokLOC::Security::Input;
use strictures 2;
use Carp qw(croak);
use Exporter;
use List::AllUtils qw( all any );
use Readonly;
use experimental qw(signatures);

# ABSTRACT: Input and var validation functions.

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

use base qw(Exporter);

# Permitted lengths.
Readonly::Scalar our $STR_MAX => 4096;

# safe_objs returns 1 if all objs in $ar are of $class;
sub safe_objs ( $objs, $classes ) {
    croak 'objs not array ref'    if ( ref($objs) ne 'ARRAY' );
    croak 'classes not array ref' if ( ref($classes) ne 'ARRAY' );
    return if scalar @{$objs} == 0 || scalar @{$classes} == 0;
    for my $obj ( @{$objs} ) {
        return if !( any { $obj->isa($_) } @{$classes} );
    }
    return 1;
}

# safe_str makes sure inputs taken as external args are relatively safe.
sub safe_str($s) {
    return if length $s == 0;
    return if length $s > $STR_MAX;
    return if ( $s =~ /select|drop|update|trunc|eval|echo/gimsx );
    return if ( $s =~ /[\'\"\`]/msx );
    return 1;
}

# safe_strs runs safe_str on a list.
sub safe_strs($ar) {
    return if ( !( ref($ar) eq 'ARRAY' ) );
    return if scalar @{$ar} == 0;
    return all { safe_str($_) } @{$ar};
}

# safe_unixtime makes sure unixtime assignments are sane.
sub safe_unixtime($t) {
    Readonly::Scalar my $DEC_31_2025 => 1_767_139_200;
    return if ( $t !~ /^\d+$/msx );
    return if int($t) < 0;
    return if int($t) > $DEC_31_2025;    # Dec 31, 2025
    return 1;
}

our @EXPORT_OK = qw(
  safe_objs
  safe_str
  safe_strs
  safe_unixtime
);

our %EXPORT_TAGS = (
    validators => [
        qw(
          safe_objs
          safe_str
          safe_strs
          safe_unixtime
          )
    ]
);

1;

__END__

=head1 NAME

GrokLOC::Security::Input

=head1 SYNOPSIS

Security utilities.

=head1 DESCRIPTION

Input and var validation functions.

=cut
