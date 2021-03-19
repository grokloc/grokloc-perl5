package GrokLOC::Models::User;
use strictures 2;
use Carp qw(croak);
use Crypt::Digest::SHA256 qw(sha256_b64);
use Crypt::Misc qw(random_v4uuid);
use Moo;
use Readonly;
use Syntax::Keyword::Try qw(try catch :experimental);
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
Readonly::Scalar our $TABLENAME      => $USERS_TABLENAME;

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
              unless ( exists $kv{$k} && safe_str( $kv{$k} ) );
        }
        croak 'missing/malformed kdf iterations'
          unless ( exists $kv{kdf_iterations}
            && $kv{kdf_iterations} =~ /^\d+$/imsx );
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
            password => kdf( $kv{password}, salt($id), $kv{kdf_iterations} ),
            _meta    => GrokLOC::Models::Meta->new(),
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

sub TO_JSON($self) {
    return {
        id                => $self->id,
        api_secret        => $self->api_secret,
        api_secret_digest => $self->api_secret_digest,
        display           => $self->display,
        display_digest    => $self->display_digest,
        email             => $self->email,
        email_digest      => $self->email_digest,
        org               => $self->org,
        password          => $self->password,
        _meta             => $self->_meta->TO_JSON(),
    };
}

# insert can be called after ->new. Call like:
# try {
#     $result = $org->insert( $master );
#     die 'insert failed' unless $result == $RESPONSE_OK;
# }
# catch ($e) {
#     ...unknown error
# }
sub insert ( $self, $master ) {
    croak 'db ref'
      unless safe_objs( [$master], [ 'Mojo::SQLite', 'Mojo::Pg' ] );

    # Verify that the org is in the db and active.
    my $v =
      $master->db->select( $ORGS_TABLENAME, [qw{*}], { id => $self->org } )
      ->hash;
    return $RESPONSE_ORG_ERR
      unless ( defined $v ) && ( $v->{status} == $STATUS_ACTIVE );
    try {
        $master->db->insert(
            $TABLENAME,
            {
                id                => $self->id,
                api_secret        => $self->api_secret,
                api_secret_digest => $self->api_secret_digest,
                display           => $self->display,
                display_digest    => $self->display_digest,
                email             => $self->email,
                email_digest      => $self->email_digest,
                org               => $self->org,
                password          => $self->password,
                status            => $self->_meta->status,
                version           => $SCHEMA_VERSION,
            }
        );
    }
    catch ($e) {
        return $RESPONSE_CONFLICT if ( $e =~ /unique/imsx );
        croak 'uncaught: ' . $e;
    };
    return $RESPONSE_OK;
}

# read is a static method for creating a new Org from an existing row.
# Call like: ;
# try {
#     $user = GrokLOC::Models::User->read( $dbo, $id );
#     ...$user is undef if the row isn't found.
# }
# catch ($e) {
#     ...otherwise unknown error
# }
sub read ( $pkg, $dbo, $id ) {
    croak 'call like: ' . __PACKAGE__ . '->read( $dbo, $id )'
      unless $pkg eq __PACKAGE__;
    croak 'db ref'
      unless safe_objs( [$dbo], [ 'Mojo::SQLite', 'Mojo::Pg' ] );
    croak 'malformed id' unless safe_str($id);
    my $v = $dbo->db->select( $TABLENAME, [qw{*}], { id => $id } )->hash;
    return unless ( defined $v );    # Not found.
    return $pkg->new(
        id                => $v->{id},
        api_secret        => $v->{api_secret},
        api_secret_digest => $v->{api_secret_digest},
        display           => $v->{display},
        display_digest    => $v->{display_digest},
        email             => $v->{email},
        email_digest      => $v->{email_digest},
        org               => $v->{org},
        password          => $v->{password},
        _meta             => GrokLOC::Models::Meta->new(
            ctime  => $v->{ctime},
            mtime  => $v->{mtime},
            status => $v->{status}
        )
    );
}

sub update_display ( $self, $master, $display ) {
    croak 'malformed display' unless safe_str($display);
    return $self->_update(
        $master,
        $TABLENAME,
        $self->id,
        {
            display        => $display,
            display_digest => sha256_b64($display)
        }
    );
}

sub update_password ( $self, $master, $password, $kdf_iterations ) {
    croak 'malformed password' unless safe_str($password);
    my $derived = kdf( $password, salt( $self->id ), $kdf_iterations );
    return $self->_update( $master, $TABLENAME, $self->id,
        { password => $derived } );
}

sub update_status ( $self, $master, $status ) {
    return $self->_update_status( $master, $TABLENAME, $self->id, $status );
}

1;

__END__

=head1 NAME

GrokLOC::Models::User

=head1 SYNOPSIS

User model.

=head1 DESCRIPTION

User model with persistence methods.

=cut
