package GrokLOC::App::Client;
use Object::Pad;
use strictures 2;
use Carp qw(croak);
use experimental qw(signatures);
use GrokLOC::App qw(:all);
use GrokLOC::App::JWT qw(:all);
use GrokLOC::App::Routes qw(:routes);
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

    has $_token;
    has $_token_time;

    BUILD(%args) {
        for my $k (qw(url id api_secret)) {
            croak "missing/malformed $k"
              unless ( exists $args{$k} && safe_str( $args{$k} ) );
        }

        croak 'missing/malformed ua'
          unless ( exists $args{ua}
            && safe_objs( [ $args{ua} ], ['Mojo::UserAgent'] ) );
        ( $url, $id, $api_secret, $ua ) =
          ( $args{url}, $args{id}, $args{api_secret}, $args{ua} );

        # Remove trailing / if any.
        chop $url if ( $url =~ m{/$}msx );
    }

    method token_request {
        my $now = time;

        if (   defined $_token
            && defined $_token_time
            && $_token_time > $now )
        {
            return {
                $X_GROKLOC_ID    => $id,
                $X_GROKLOC_TOKEN => $_token
            };
        }

        # Otherwise, get a new one.
        my $headers = {
            $X_GROKLOC_ID            => $id,
            $X_GROKLOC_TOKEN_REQUEST => encode_token_request( $id, $api_secret )
        };

        my $route  = $url . $TOKEN_REQUEST_ROUTE;
        my $result = $ua->post( $route => $headers )->result;
        if ( 204 != $result->code ) {
            croak 'token request code ' . $result->code;
        }
        if ( !defined $result->headers->authorization ) {
            croak 'no authorization result headers';
        }
        $_token = $result->headers->authorization;

        # Subtract a one minute to be safe.
        $_token_time = $now + $JWT_EXPIRATION - 60;
        return {
            $X_GROKLOC_ID    => $id,
            $X_GROKLOC_TOKEN => $_token
        };
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
