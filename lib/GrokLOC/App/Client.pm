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

        # remove trailing / if any
        chop $url if ( $url =~ m{/$}msx );
    }

    method token_request {
        my $now = time;

        # Token already passed, just return it.
        if (   defined $_token
            && defined $_token_time
            && $_token_time > $now )
        {
            return {
                $X_GROKLOC_ID  => $id,
                $AUTHORIZATION => $_token
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

        # subtract a one minute to be safe
        $_token_time = $now + $JWT_EXPIRATION - 60;
        return {
            $X_GROKLOC_ID  => $id,
            $AUTHORIZATION => $_token
        };
    }

    # ok is an unauthenticated ping
    method ok {
        my $route  = $url . $OK_ROUTE;
        my $result = $ua->get($route)->result;
        if ( 200 != $result->code ) {
            croak 'status code ' . $result->code;
        }
        return $result->json;
    }

    # status wrapped from app_msg and returned as a hashref
    method status {
        my $headers = $self->token_request;
        my $route   = $url . $STATUS_ROUTE;
        my $result  = $ua->get( $route => $headers )->result;
        if ( 200 != $result->code ) {
            croak 'status code ' . $result->code;
        }
        return $result->json;
    }

    # ----- org related
    method org_create ($name) {
        croak 'malformed name' unless safe_str($name);
        my $headers = $self->token_request;
        my $route   = $url . $ORG_ROUTE;
        return $ua->post( $route => $headers => json => { name => $name } )
          ->result;
    }

    method org_read ($id) {
        croak 'malformed id' unless safe_str($id);
        my $headers = $self->token_request;
        my $route   = $url . $ORG_ROUTE . q{/} . $id;
        return $ua->get( $route => $headers )->result;
    }

    method org_update ($id, $args) {
        croak 'malformed id'   unless safe_str($id);
        croak 'malformed args' unless ( ref($args) eq 'HASH' );
        my $headers = $self->token_request;
        my $route   = $url . $ORG_ROUTE . q{/} . $id;
        return $ua->put( $route => $headers => json => $args )->result;
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
