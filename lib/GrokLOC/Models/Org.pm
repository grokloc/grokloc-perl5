package GrokLOC::Models::Org;
use strictures 2;
use Carp qw(croak);
use Crypt::Misc qw(random_v4uuid);
use Moo;
use Readonly;
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
        croak 'missing key name in new org constructor'
          if ( !exists $kv{name} );
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

1;

__END__

=head1 NAME

GrokLOC::Models::Org

=head1 SYNOPSIS

Org model.

=head1 DESCRIPTION

Org model with persistence methods.

=cut
