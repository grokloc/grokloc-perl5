package GrokLOC::App::Client;
use Object::Pad;
use strictures 2;
use Carp qw(croak);
use experimental qw(signatures);
use GrokLOC::Security::Input qw(:validators);

# ABSTRACT: App client library.

## no critic (RequireEndWithOne);

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

class GrokLOC::App::Client {
    has $url :reader;
    has $id :reader;
    has $api_secret :reader;
    has $ua :reader;

    BUILD(%args) {
        for my $k (qw(url id api_secret)) {
            croak "missing/malformed $k"
              unless ( exists $args{$k} && safe_str( $args{$k} ) );
        }
        croak 'missing/malformed ua'
          unless ( exists $args{ua}
            && safe_obs( [ $args{ua} ], ['Mojo::UserAgent'] ) );
        ( $url, $id, $api_secret, $ua ) =
          ( $args{url}, $args{id}, $args{api_secret}, $args{ua} );
    }
}

1;

__END__

=head1 NAME

GrokLOC::App::Client

=head1 SYNOPSIS

App client library.

=head1 DESCRIPTION

App client library.

=cut
