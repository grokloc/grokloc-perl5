package GrokLOC::Models::Org;
use Object::Pad;
use strictures 2;
use Carp qw(croak);
use Readonly;
use experimental qw(signatures try);
use GrokLOC::Models qw(:all);
use GrokLOC::Models::Base;
use GrokLOC::Models::Meta;
use GrokLOC::Security::Input qw(:validators);

# ABSTRACT: Org model with persistence methods.

## no critic (RequireEndWithOne);

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

Readonly::Scalar our $SCHEMA_VERSION => 0;
Readonly::Scalar our $TABLENAME      => $ORGS_TABLENAME;

class GrokLOC::Models::Org extends GrokLOC::Models::Base {
    has $name :reader;
    has $owner :reader;

    # Constructor has two forms:
    # 1. New org. In this case, there must be exactly one field in the args hash:
    #    (name). New orgs have default $NO_OWNER.
    # 2. Existing org. In this case, the (owner, id) must also be provided, while
    #    the meta struct is optional.
    BUILD(%args) {
        croak 'missing/malformed name'
          unless ( exists $args{name} && safe_str( $args{name} ) );
        $name  = $args{name};
        $owner = $NO_OWNER;

        # New org.
        # Parent constructor will provide id, meta.
        return if ( 1 == scalar keys %args );

        # Otherwise, this is an existing org.
        croak 'missing/malformed owner'
          unless ( exists $args{owner} && safe_str( $args{owner} ) );
        $owner = $args{owner};

        # Make sure caller at least passed id; meta can be optional.
        croak 'missing base args' unless ( exists $args{id} );

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
        try {
            $master->db->insert(
                $TABLENAME,
                {
                    id             => $self->id,
                    name           => $self->name,
                    owner          => $self->owner,
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

    method update_owner ( $master, $owner ) {
        croak 'db ref'
          unless safe_objs( [$master], [ 'Mojo::SQLite', 'Mojo::Pg' ] );
        croak 'malformed owner' unless safe_str($owner);
        my $v =
          $master->db->select( $USERS_TABLENAME, [qw{*}], { id => $owner } )
          ->hash;
        return $RESPONSE_USER_ERR
          unless ( defined $v )
          && ( $v->{status} == $STATUS_ACTIVE )
          && ( $v->{org} eq $self->id );
        return $self->_update( $master, $TABLENAME, $self->id,
            { owner => $owner } );
    }

    method update_status ( $master, $status ) {
        return $self->_update_status( $master, $TABLENAME, $self->id, $status );
    }

    method TO_JSON {
        return {
            name  => $self->name,
            owner => $self->owner,
            id    => $self->id,
            meta  => $self->meta,
        };
    }
}

# read is a static method for creating a new Org from an existing row.
# Call like: ;
# try {
#     $org = GrokLOC::Models::Org::read( $dbo, $id );
#     ...$org is undef if the row isn't found.
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
        id             => $v->{id},
        name           => $v->{name},
        owner          => $v->{owner},
        schema_version => $v->{schema_version},
        meta           => GrokLOC::Models::Meta->new(
            ctime  => $v->{ctime},
            mtime  => $v->{mtime},
            status => $v->{status},
        )
    );
}

1;

__END__

=head1 NAME

GrokLOC::Models::Org

=head1 SYNOPSIS

Org model.

=head1 DESCRIPTION

Org model with persistence methods.

=cut
