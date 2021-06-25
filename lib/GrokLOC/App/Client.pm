package GrokLOC::App::Client;
use Object::Pad;
use strictures 2;
use Carp qw( croak );
use Mojo::JSON qw( decode_json );
use experimental qw(signatures);
use GrokLOC::App qw( $X_GROKLOC_ID $X_GROKLOC_TOKEN_REQUEST );
use GrokLOC::App::JWT qw(
  $AUTHORIZATION
  encode_token_request
  token_to_header_val
);
use GrokLOC::App::Routes qw(
  $OK_ROUTE
  $ORG_ROUTE
  $STATUS_ROUTE
  $TOKEN_REQUEST_ROUTE
  $USER_ROUTE
);
use GrokLOC::Security::Input qw( safe_objs safe_str );

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
    has $_token_expires;

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
            && defined $_token_expires
            && $_token_expires > $now )
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
        if ( 200 != $result->code ) {
            croak 'token request code ' . $result->code;
        }

        my $token_fields = decode_json $result->body;
        croak 'body parse'
          unless ( defined $token_fields && ref $token_fields eq 'HASH' );
        croak 'missing token'   unless ( exists $token_fields->{token} );
        croak 'missing expires' unless ( exists $token_fields->{expires} );
        $_token         = $token_fields->{token};
        $_token_expires = $token_fields->{expires};

        return {
            $X_GROKLOC_ID  => $id,
            $AUTHORIZATION => token_to_header_val($_token)
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

    # ----- user related
    # password should aleady be derived by kdf
    method user_create ( $display_name, $email, $org, $password ) {
        for my $k ( $display_name, $email, $org, $password ) {
            croak "missing/malformed $k" unless ( safe_str($k) );
        }
        my $headers = $self->token_request;
        my $route   = $url . $USER_ROUTE;
        return $ua->post(
            $route => $headers => json => {
                display_name => $display_name,
                email        => $email,
                org          => $org,
                password     => $password,
            }
        )->result;
    }

    method user_read ($id) {
        croak 'malformed id' unless safe_str($id);
        my $headers = $self->token_request;
        my $route   = $url . $USER_ROUTE . q{/} . $id;
        return $ua->get( $route => $headers )->result;
    }

    method user_update ($id, $args) {
        croak 'malformed id'   unless safe_str($id);
        croak 'malformed args' unless ( ref($args) eq 'HASH' );
        my $headers = $self->token_request;
        my $route   = $url . $USER_ROUTE . q{/} . $id;
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
