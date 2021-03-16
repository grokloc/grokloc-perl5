package GrokLOC::Models::User;
use strictures 2;
use Carp qw(croak);
use Crypt::Digest::SHA256 qw(sha256_b64);
use Crypt::Misc qw(random_v4uuid);
use Moo;
use Readonly;
use Types::Standard qw(Str);
use experimental qw(signatures);
use GrokLOC::Models qw(:all);
use GrokLOC::Models::Base;
use GrokLOC::Models::Meta;
use GrokLOC::Security::Crypt qw(:all);
use GrokLOC::Security::Input qw(:validators);

# ABSTRACT: User model with persistence methods.

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

with 'GrokLOC::Models::Base';

Readonly::Scalar our $SCHEMA_VERSION => 0;
Readonly::Scalar our $TABLENAME      => 'users';

has [
    qw(api_secret api_secret_digest display display_digest email email_digest org password)
] => (
    is       => 'ro',
    isa      => Str->where('GrokLOC::Security::Input::safe_str $_'),
    required => 1,
);

# Valid constructor calls:
# ->new(display=>...,email=>...,org=>...,password=>...,key=>...,iterations=>...)
# ->new([all args])
around BUILDARGS => sub ( $orig, $class, @args ) {
    my %kv  = @args;
    my $len = scalar keys %kv;

  # New. =>key is required to encrypt fields, =>iterations for password hashing.
  # The returned object is sealed.
    if ( 6 == $len ) {
        for my $k (qw(display email org password key)) {
            croak "missing/malformed key $k new user constructor"
              unless ( exists $kv{$k} && safe_string( $kv{$k} ) );
        }
        croak 'missing/malformed kdf iterations'
          unless ( exists $kv{iterations} && $kv{iterations} =~ /^\d+$/imsx );
        my ( $id, $api_secret ) = ( random_v4uuid, random_v4uuid );
        return {
            id         => $id,
            api_secret => encrypt( $api_secret, key( $kv{key} ), iv($id) ),
            api_secret_digest => sha256_b64($api_secret),
            display        => encrypt( $kv{display}, key( $kv{key} ), iv($id) ),
            display_digest => sha256_b64( $kv{display} ),
            email          => encrypt( $kv{email}, key( $kv{key} ), iv($id) ),
            email_digest   => sha256_b64( $kv{email} ),
            org            => $kv{org},
            password       => kdf( $kv{password}, salt($id), $kv{iterations} ),
            _meta          => GrokLOC::Models::Meta->new(),
        };
    }

    # Otherwise, populate with all args. Attributes that were hashed/encrypted
    # when the original seed object was created are assumed to be in that form.
    for my $k (
        qw(id api_secret api_secret_digest display display_digest email email_digest org password _meta)
      )
    {
        croak "missing key $k all-arg constructor" if ( !exists $kv{$k} );
    }

    # If passed through a json encode/decode cycle, the meta object
    # will be a hash ref, so convert it.
    if ( ref( $kv{_meta} ) eq 'HASH' ) {
        $kv{_meta} = GrokLOC::Models::Meta->new( %{ $kv{_meta} } );
    }

    return \%kv;
};

1;

__END__

=head1 NAME

GrokLOC::Models::User

=head1 SYNOPSIS

User model.

=head1 DESCRIPTION

User model with persistence methods.

=cut
