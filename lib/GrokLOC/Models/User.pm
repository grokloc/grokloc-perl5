package GrokLOC::Models::User;
use Object::Pad;
use strictures 2;
use Carp qw(croak);
use Crypt::Digest::SHA256 qw(sha256_b64);
use Crypt::Misc qw(random_v4uuid);
use Readonly;
use experimental qw(signatures try);
use GrokLOC::Models qw(:all);
use GrokLOC::Models::Base;
use GrokLOC::Models::Meta;
use GrokLOC::Security::Crypt qw(:all);
use GrokLOC::Security::Input qw(:validators);

# ABSTRACT: User model with persistence methods.

## no critic (RequireEndWithOne);

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

Readonly::Scalar our $SCHEMA_VERSION => 0;
Readonly::Scalar our $TABLENAME      => $USERS_TABLENAME;

class GrokLOC::Models::User extends GrokLOC::Models::Base {
    has $api_secret :reader;
    has $api_secret_digest :reader;
    has $display_name :reader;
    has $display_name_digest :reader;
    has $email :reader;
    has $email_digest :reader;
    has $org :reader;
    has $password :reader;

    # Constructor has two forms:
    # 1. New user. In this case, there must be exactly six
    #    fields in the args hash:
    #    (display, email, org, password, key, kdf_iterations).
    #    The last two fields are used to perform encryption on
    #    cleartext fields.
    # 2. Existing user. In this case, the (key, kdf_iterations)
    #    args are not passed,
    #    since all fields are assumed to be in their sealed states.
    #    The args passed must be
    #    (id, api_secret, api_secret_digest, display,
    #     display_digest, email, email_digest, org, password).
    BUILD(%args) {
        if ( 6 == scalar keys %args ) {

            # New user.
            for my $k (qw(display_name email org password key)) {
                croak "missing/malformed $k"
                  unless ( exists $args{$k} && safe_str( $args{$k} ) );
            }
            croak 'missing/malformed kdf iterations'
              unless ( exists $args{kdf_iterations}
                && safe_kdf_iterations( $args{kdf_iterations} ) );
            $display_name_digest = sha256_b64( $args{display_name} );
            $email_digest        = sha256_b64( $args{email} );
            $org                 = $args{org};

            # email_digest is formed from the unique email provided by the user,
            # so it is a useful iv/salt for encryption of display/email.
            $display_name = encrypt( $args{display_name}, key( $args{key} ),
                iv($email_digest) );
            $email =
              encrypt( $args{email}, key( $args{key} ), iv($email_digest) );

            my $_api_secret = random_v4uuid;
            $api_secret =
              encrypt( $_api_secret, key( $args{key} ), iv($email_digest) );
            $api_secret_digest = sha256_b64($_api_secret);

            # password is one-time hashed.
            $password = kdf( $args{password}, salt($email_digest),
                $args{kdf_iterations} );

            # Parent constructor will provide id, meta.
            return;
        }

        # Otherwise, this is an existing user.
        for my $k (
            qw(id api_secret api_secret_digest display_name
            display_name_digest email email_digest org password)
          )
        {
            croak "missing/malformed $k"
              unless ( exists $args{$k} && safe_str( $args{$k} ) );
        }
        $api_secret          = $args{api_secret};
        $api_secret_digest   = $args{api_secret_digest};
        $display_name        = $args{display_name};
        $display_name_digest = $args{display_name_digest};
        $email               = $args{email};
        $email_digest        = $args{email_digest};
        $org                 = $args{org};
        $password            = $args{password};

        # Parent constructor validates id and optionally meta.
        return;
    }

    # insert can be called after ->new. Call like:
    # try {
    #     $result = $org->insert( $master );
    #     die 'insert failed' unless $result == $RESPONSE_OK;
    # }
    # catch ($e) {
    #     ...unknown error
    # }
    method insert ( $master ) {
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
                    id                  => $self->id,
                    api_secret          => $self->api_secret,
                    api_secret_digest   => $self->api_secret_digest,
                    display_name        => $self->display_name,
                    display_name_digest => $self->display_name_digest,
                    email               => $self->email,
                    email_digest        => $self->email_digest,
                    org                 => $self->org,
                    password            => $self->password,
                    status              => $self->meta->status,
                    schema_version      => $SCHEMA_VERSION,
                }
            );
        }
        catch ($e) {
            return $RESPONSE_CONFLICT if ( $e =~ /unique/imsx );
            croak 'uncaught:' . $e;
        };
        return $RESPONSE_OK;
    }

    method update_display_name ( $master, $display_name ) {
        croak 'malformed display_name' unless safe_str($display_name);
        return $self->_update(
            $master,
            $TABLENAME,
            $self->id,
            {
                display_name        => $display_name,
                display_name_digest => sha256_b64($display_name)
            }
        );
    }

    method update_password ( $master, $password, $kdf_iterations ) {
        croak 'malformed password' unless safe_str($password);
        croak 'kdf iterations'     unless safe_kdf_iterations($kdf_iterations);
        my $derived =
          kdf( $password, salt( $self->email_digest ), $kdf_iterations );
        return $self->_update( $master, $TABLENAME, $self->id,
            { password => $derived } );
    }

    method update_status ( $master, $status ) {
        return $self->_update_status( $master, $TABLENAME, $self->id, $status );
    }

    method TO_JSON {
        return {
            id                  => $self->id,
            api_secret          => $self->api_secret,
            api_secret_digest   => $self->api_secret_digest,
            display_name        => $self->display_name,
            display_name_digest => $self->display_name_digest,
            email               => $self->email,
            email_digest        => $self->email_digest,
            org                 => $self->org,
            password            => $self->password,
            meta                => $self->meta,
        };
    }
}

# read is a static method for creating a new Org from an existing row.
# Call like: ;
# try {
#     $user = GrokLOC::Models::User::read( $dbo, $id );
#     ...$user is undef if the row isn't found.
# }
# catch ($e) {
#     ...otherwise unknown error
# }
sub read ( $dbo, $id ) {
    croak 'db ref'
      unless safe_objs( [$dbo], [ 'Mojo::SQLite', 'Mojo::Pg' ] );
    croak 'malformed id' unless safe_str($id);
    my $v = $dbo->db->select( $TABLENAME, [qw{*}], { id => $id } )->hash;
    return unless ( defined $v );    # Not found -> undef.
    return __PACKAGE__->new(
        id                  => $v->{id},
        api_secret          => $v->{api_secret},
        api_secret_digest   => $v->{api_secret_digest},
        display_name        => $v->{display_name},
        display_name_digest => $v->{display_name_digest},
        email               => $v->{email},
        email_digest        => $v->{email_digest},
        org                 => $v->{org},
        password            => $v->{password},
        schema_version      => $v->{schema_version},
        meta                => GrokLOC::Models::Meta->new(
            ctime  => $v->{ctime},
            mtime  => $v->{mtime},
            status => $v->{status}
        )
    );
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
