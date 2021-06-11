package GrokLOC::Security::Crypt;
use strictures 2;
use Carp qw( croak );
use Crypt::Argon2 qw( argon2id_pass argon2id_verify );
use Crypt::Digest::SHA256 qw( sha256_b64 );
use Crypt::Misc qw( decode_b64 encode_b64 );
use Readonly ();
use experimental qw(signatures);

# ABSTRACT: Initialize a State instance for the environment.

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

use base qw(Exporter);

Readonly::Scalar our $SALT_LEN => 16;
Readonly::Scalar our $IV_LEN   => 16;
Readonly::Scalar our $KEY_LEN  => 32;

sub iv ($iv) {
    croak 'iv zero len' if ( length $iv == 0 );
    return substr sha256_b64($iv), 0, $IV_LEN;
}

sub key ($key) {
    croak 'key zero len' if ( length $key == 0 );
    return substr sha256_b64($key), 0, $KEY_LEN;
}

sub encrypt ( $source, $key, $iv ) {
    croak 'key not correct len' if ( length $key != $KEY_LEN );
    croak 'iv not correct len'  if ( length $iv != $IV_LEN );
    my $cbc = Crypt::Mode::CBC->new('AES');
    return encode_b64( $cbc->encrypt( $source, $key, $iv ) );
}

sub decrypt ( $crypted, $key, $iv ) {
    croak 'key not correct len' if ( length $key != $KEY_LEN );
    croak 'iv not correct len'  if ( length $iv != $IV_LEN );
    my $cbc = Crypt::Mode::CBC->new('AES');
    return $cbc->decrypt( decode_b64($crypted), $key, $iv );
}

sub salt ($salt) {
    croak 'salt zero len' if ( length $salt == 0 );
    return substr sha256_b64($salt), 0, $SALT_LEN;
}

sub kdf ( $pw, $salt, $t_cost ) {
    croak 't_cost must be between 1 and 231' if !( 0 < $t_cost < 232 );
    return argon2id_pass( $pw, $salt, $t_cost, '32M', 1, 16 );
}

sub kdf_verify ( $encoded, $pw ) {
    return argon2id_verify( $encoded, $pw );
}

our @EXPORT_OK =
  qw($SALT_LEN $IV_LEN $KEY_LEN iv key encrypt decrypt salt kdf kdf_verify);
our %EXPORT_TAGS = (
    lens => [qw($SALT_LEN $IV_LEN $KEY_LEN)],
    all  => [
        qw($SALT_LEN $IV_LEN $KEY_LEN iv key encrypt decrypt salt kdf kdf_verify)
    ]
);

1;

__END__

=head1 NAME

GrokLOC::Security::Crypt

=head1 SYNOPSIS

Crypt functions.

=head1 DESCRIPTION

iv - Derive the IV.

key - Derive the Key.

encrypt - Symmetric encryption.

decrypt - Symmetric decryption.

salt - Derive the salt for the kdf.

kdf - Password hashing using Argon2.

=cut
