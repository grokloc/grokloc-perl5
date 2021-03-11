package GrokLOC;
use strictures 2;
use Mojo::Log;

# ABSTRACT: Root image for the GrokLOC distribution.

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

use base qw(Exporter);

# Global logger.
our $L = Mojo::Log->new;

our @EXPORT_OK   = qw($L);
our %EXPORT_TAGS = ( all => [qw($L)] );

1;

__END__

=head1 NAME

GrokLOC

=head1 SYNOPSIS

Base package.

=head1 DESCRIPTION

Global definitions such as the logger.

=cut
