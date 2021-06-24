package GrokLOC::Models::User;
use Object::Pad;
use strictures 2;
use Carp qw( croak );
use Crypt::Digest::SHA256 qw( sha256_b64 );
use Crypt::Misc qw( random_v4uuid );
use Readonly ();
use experimental qw(signatures try);
use GrokLOC::Models qw(
    $ORGS_TABLENAME
    $RESPONSE_CONFLICT
    $RESPONSE_OK
    $RESPONSE_ORG_ERR
    $STATUS_ACTIVE
    $USERS_TABLENAME
);
use GrokLOC::Models::Base;
use GrokLOC::Models::Meta;
use GrokLOC::Security::Crypt qw( decrypt encrypt iv );
use GrokLOC::Security::Input qw( safe_objs safe_str );

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

    # constructor has two forms:
    # 1. new user
    #    exactly foud fields in the args hash:
    #    (display, email, org, password)
    #    password is always passed as already dervied
    # 2. existing user
    #    all fields required except for meta, which is optional
    BUILD(%args) {
        if ( 4 == scalar keys %args ) {

            # new user
            for my $k (qw(display_name email org password)) {
                croak "missing/malformed $k"
                  unless ( exists $args{$k} && safe_str( $args{$k} ) );
            }
            $api_secret          = random_v4uuid;
            $api_secret_digest   = sha256_b64($api_secret);
            $display_name        = $args{display_name};
            $display_name_digest = sha256_b64( $args{display_name} );
            $email               = $args{email};
            $email_digest        = sha256_b64( $args{email} );
            $org                 = $args{org};
            $password            = $args{password};

            # parent constructor will provide id, meta
            return;
        }

        # existing user
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

        # parent constructor validates id and optionally meta
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
    method insert ( $master, $key ) {
        croak 'missing/malformed key' unless ( safe_str($key) );
        croak 'db ref'
          unless safe_objs( [$master], [ 'Mojo::SQLite', 'Mojo::Pg' ] );

        # verify that the org is in the db and active
        my $v =
          $master->db->select( $ORGS_TABLENAME, [qw{*}], { id => $self->org } )
          ->hash;

        return $RESPONSE_ORG_ERR
          unless ( defined $v ) && ( $v->{status} == $STATUS_ACTIVE );

        try {
            $master->db->insert(
                $TABLENAME,
                {
                    id         => $self->id,
                    api_secret => encrypt(
                        $self->api_secret, $key, iv( $self->email_digest )
                    ),
                    api_secret_digest => $self->api_secret_digest,
                    display_name      => encrypt(
                        $self->display_name, $key,
                        iv( $self->email_digest )
                    ),
                    display_name_digest => $self->display_name_digest,
                    email               =>
                      encrypt( $self->email, $key, iv( $self->email_digest ) ),
                    email_digest   => $self->email_digest,
                    org            => $self->org,
                    password       => $self->password,
                    status         => $self->meta->status,
                    schema_version => $SCHEMA_VERSION,
                }
            );
        }
        catch ($e) {
            return $RESPONSE_CONFLICT if ( $e =~ /unique/imsx );
            croak 'uncaught:' . $e;
        };
        return $RESPONSE_OK;
    }

    method update_display_name ( $master, $key, $display_name ) {
        croak 'malformed display_name' unless safe_str($display_name);
        return GrokLOC::Models::update(
            $master,
            $TABLENAME,
            $self->id,
            {
                display_name =>
                  encrypt( $display_name, $key, iv( $self->email_digest ) ),
                display_name_digest => sha256_b64($display_name)
            }
        );
    }

    # password is assumed passed already derived
    method update_password ( $master, $password ) {
        croak 'malformed password' unless safe_str($password);
        return GrokLOC::Models::update( $master, $TABLENAME, $self->id,
            { password => $password } );
    }

    method update_status ( $master, $status ) {
        return GrokLOC::Models::update_status( $master, $TABLENAME, $self->id,
            $status );
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
            schema_version      => $self->schema_version,
        };
    }
}

# read is a static method for creating a new Org from an existing row.
# Call like: ;
# try {
#     $user = GrokLOC::Models::User::read( $dbo, $key, $id );
#     ...$user is undef if the row isn't found.
# }
# catch ($e) {
#     ...otherwise unknown error
# }
sub read ( $dbo, $key, $id ) {
    croak 'db ref'
      unless safe_objs( [$dbo], [ 'Mojo::SQLite', 'Mojo::Pg' ] );
    croak 'malformed id' unless safe_str($id);
    my $v = $dbo->db->select( $TABLENAME, [qw{*}], { id => $id } )->hash;
    return unless ( defined $v );    # Not found -> undef.

    return __PACKAGE__->new(
        id         => $v->{id},
        api_secret =>
          decrypt( $v->{api_secret}, $key, iv( $v->{email_digest} ) ),
        api_secret_digest => $v->{api_secret_digest},
        display_name      =>
          decrypt( $v->{display_name}, $key, iv( $v->{email_digest} ) ),
        display_name_digest => $v->{display_name_digest},
        email        => decrypt( $v->{email}, $key, iv( $v->{email_digest} ) ),
        email_digest => $v->{email_digest},
        org          => $v->{org},
        password     => $v->{password},
        schema_version => $v->{schema_version},
        meta           => GrokLOC::Models::Meta->new(
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
