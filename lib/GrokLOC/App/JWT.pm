package GrokLOC::App::JWT;
use strictures 2;
use Crypt::Digest::SHA256 qw( sha256_b64 );
use Crypt::JWT qw( decode_jwt encode_jwt );
use Exporter;
use Readonly ();
use experimental qw(signatures);

# ABSTRACT: Auth middleware for populating the stash.

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

use base qw(Exporter);

Readonly::Scalar our $AUTHORIZATION  => 'Authorization';
Readonly::Scalar our $JWT_TYPE       => 'Bearer';
Readonly::Scalar our $JWT_EXPIRATION => 86_400;

sub encode_token_request ( $id, $api_secret ) {
    return sha256_b64( $id . $api_secret );
}

sub verify_token_request ( $request, $id, $api_secret ) {
    return encode_token_request( $id, $api_secret ) eq $request;
}

sub encode_token ( $id, $key ) {
    my $now = time;
    return encode_jwt(
        payload => {
            'iss' => 'GrokLOC.com',
            'aud' => 'GrokLOC',
            'sub' => $id,
            'exp' => $now + $JWT_EXPIRATION,
            'nbf' => $now,
            'iat' => $now,
        },
        key => $key,
        alg => 'HS256',
    );
}

sub decode_token ( $token, $key ) {

    # $token may come in as '$TOKEN_TYPE $val' if from a web context.
    if ( $token =~ /^$JWT_TYPE\s(\S+)/msx ) {
        $token = $1;
    }
    return decode_jwt(
        token          => $token,
        key            => $key,
        decode_payload => 1,
        verify_iat     => 1,
        verify_nbf     => 1,
        verify_exp     => 1,
    );
}

our @EXPORT_OK =
  qw(encode_token_request verify_token_request encode_token decode_token $AUTHORIZATION $JWT_TYPE $JWT_EXPIRATION);
our %EXPORT_TAGS = (
    all => [
        qw(encode_token_request verify_token_request encode_token decode_token $AUTHORIZATION $JWT_TYPE $JWT_EXPIRATION)
    ],
);

1;

__END__

=head1 NAME

GrokLOC::App::JWT

=head1 SYNOPSIS

Core JWT definitions.

=head1 DESCRIPTION

Support for encoding and verifying token requests, as 
well as encoding and decoding tokens.

=cut
