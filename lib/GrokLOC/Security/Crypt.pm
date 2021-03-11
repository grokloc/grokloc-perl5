package GrokLOC::Security::Crypt;
use strictures 2;
use Carp qw(croak);
use Crypt::Digest::SHA256 qw(sha256_b64);
use Crypt::KeyDerivation qw(pbkdf2);
use Crypt::Misc qw(encode_b64 decode_b64);
use Readonly;
use experimental qw(signatures);

# ABSTRACT: Initialize a State instance for the environment.

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

use base qw(Exporter);

Readonly::Scalar our $SALT_LEN => 8;
Readonly::Scalar our $IV_LEN   => 16;
Readonly::Scalar our $KEY_LEN  => 32;

sub iv($iv) {
    croak 'iv zero len' if ( length $iv == 0 );
    return substr sha256_b64($iv), 0, $IV_LEN;
}

sub key($key) {
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

sub salt($salt) {
    croak 'salt zero len' if ( length $salt == 0 );
    return substr sha256_b64($salt), 0, $SALT_LEN;
}

sub kdf ( $pw, $salt, $iterations ) {
    return encode_b64( pbkdf2( $pw, $salt, $iterations ) );
}

our @EXPORT_OK = qw($SALT_LEN $IV_LEN $KEY_LEN iv key encrypt decrypt salt kdf);
our %EXPORT_TAGS = (
    lens => [qw($SALT_LEN $IV_LEN $KEY_LEN)],
    all  => [qw($SALT_LEN $IV_LEN $KEY_LEN iv key encrypt decrypt salt kdf)]
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

kdf - Password hashing using PBKDF2.

=cut
