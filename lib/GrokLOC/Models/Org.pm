package GrokLOC::Models::Org;
use strictures 2;
use Carp qw(croak);
use Crypt::Misc qw(random_v4uuid);
use Moo;
use Readonly;
use Syntax::Keyword::Try qw(try catch :experimental);
use Types::Standard qw(Str);
use experimental qw(signatures);
use GrokLOC::Models qw(:all);
use GrokLOC::Models::Base;
use GrokLOC::Models::Meta;
use GrokLOC::Security::Input qw(:validators);

# ABSTRACT: Org model with persistence methods.

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

with 'GrokLOC::Models::Base';

Readonly::Scalar our $SCHEMA_VERSION => 0;
Readonly::Scalar our $TABLENAME      => $ORGS_TABLENAME;

has name => (
    is       => 'ro',
    isa      => Str->where('GrokLOC::Security::Input::safe_str $_'),
    required => 1,
);

has owner => (
    is       => 'ro',
    isa      => Str->where('GrokLOC::Security::Input::safe_str $_'),
    required => 0,
    default  => $NO_OWNER,
);

# Valid constructor calls:
# ->new(name=>...)
# ->new([all args])
around BUILDARGS => sub ( $orig, $class, @args ) {
    my %kv  = @args;
    my $len = scalar keys %kv;

    # New. Owner will be set to the default.
    if ( 1 == $len ) {
        croak 'missing/malformed key name in new org constructor'
          unless ( exists $kv{name} && safe_str( $kv{name} ) );
        return {
            id    => random_v4uuid,
            name  => $kv{name},
            _meta => GrokLOC::Models::Meta->new(),
        };
    }

    # Otherwise, populate with all args.
    for my $k (qw(id name owner _meta)) {
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
        id    => $self->id,
        name  => $self->name,
        owner => $self->owner,
        _meta => $self->_meta->TO_JSON(),
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
    croak 'bad db ref'
      unless safe_objs( [$master], [ 'Mojo::SQLite', 'Mojo::Pg' ] );
    try {
        $master->db->insert(
            $TABLENAME,
            {
                id      => $self->id,
                name    => $self->name,
                owner   => $self->owner,
                status  => $self->_meta->status,
                version => $SCHEMA_VERSION,
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
#     $org = GrokLOC::Models::Org->read( $dbo, $id );
#     ...$org is undef if the row isn't found.
# }
# catch ($e) {
#     ...otherwise unknown error
# }
sub read ( $pkg, $dbo, $id ) {
    croak 'call like: ' . __PACKAGE__ . '->read( $dbo, $id )'
      unless $pkg eq __PACKAGE__;
    croak 'bad db ref'
      unless safe_objs( [$dbo], [ 'Mojo::SQLite', 'Mojo::Pg' ] );
    croak 'bad id' unless safe_str($id);
    my $v = $dbo->db->select( $TABLENAME, [qw{*}], { id => $id } )->hash;
    return unless ( defined $v );    # Not found.w
    return $pkg->new(
        id    => $v->{id},
        name  => $v->{name},
        owner => $v->{owner},
        _meta => GrokLOC::Models::Meta->new(
            ctime  => $v->{ctime},
            mtime  => $v->{mtime},
            status => $v->{status}
        )
    );
}

sub update_status ( $self, $master, $status ) {
    return $self->_update_status( $master, $TABLENAME, $self->id, $status );
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
