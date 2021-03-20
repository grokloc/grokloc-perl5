package GrokLOC::App::Message;
use strictures 2;
use Exporter;
use experimental qw(signatures);

# ABSTRACT: App message formats.

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

use base qw(Exporter);

# app_msg formats a return tuple suitable for Mojo.
sub app_msg ( $http_code, $content_hashref ) {
    my $v = { status => $http_code, time => time, content => $content_hashref };
    return ( format => 'json', json => $v, status => $http_code );
}

our @EXPORT_OK   = qw(app_msg);
our %EXPORT_TAGS = ( all => [qw(app_msg)] );

1;

__END__

=head1 NAME 

GrokLOC::App::Message

=head1 SYNOPSIS

App message formats.

=head1 DESCRIPTION

App message formats.

=cut
