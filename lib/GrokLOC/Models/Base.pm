package GrokLOC::Models::Base;
use Object::Pad;
use strictures 2;
use Carp qw( croak );
use Crypt::Misc qw( random_v4uuid );
use experimental qw(signatures);
use GrokLOC::Models ();
use GrokLOC::Models::Meta;
use GrokLOC::Security::Input qw( safe_objs safe_str );

# ABSTRACT: Base model inherited by other models.

## no critic (RequireEndWithOne);

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

class GrokLOC::Models::Base {
    has $id :reader;
    has $meta :reader;
    has $schema_version : reader = 0;

    BUILD(%args) {
        ( $id, $meta ) = ( random_v4uuid, GrokLOC::Models::Meta->new );
        if ( exists $args{id} ) {
            croak 'id invalid' unless safe_str( $args{id} );
            $id = $args{id};
        }
        if ( exists $args{schema_version} ) {
            croak 'version invalid' if $args{schema_version} !~ /^\d+$/msx;
            $schema_version = $args{schema_version};
        }

        if ( exists $args{meta} ) {

            # if passed through a json encode/decode cycle, the meta object
            # will be a hash ref, so convert it
            if ( ref( $args{meta} ) eq 'HASH' ) {
                $meta = GrokLOC::Models::Meta->new( %{ $args{meta} } );
            }
            else {
                croak 'meta invalid'
                  unless safe_objs( [ ref $args{meta} ],
                    ['GrokLOC::Models::Meta'] );
                $meta = $args{meta};
            }
        }
        return;
    }
}

1;

__END__

=head1 NAME

GrokLOC::Models::Base

=head1 SYNOPSIS

Base model.

=head1 DESCRIPTION

Base model inherited by other models.

=head1 INTEGRITY

Constructing an object derived from Base should only perform well-formedness
checks. Validity checks (foreign key constraints etc) should only be checked
at insertion or update time. Other validity checks which are not db-related
can be performed in the constructor.

=cut

