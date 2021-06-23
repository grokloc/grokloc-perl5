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
    has $schema_version :reader;

    BUILD(%args) {
        ( $id, $meta, $schema_version ) =
          ( random_v4uuid, GrokLOC::Models::Meta->new, 0 );
        if ( exists $args{id} ) {
            croak 'id invalid' unless safe_str( $args{id} );
            $id = $args{id};
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

        if ( exists $args{schema_version} ) {
            $schema_version = $args{schema_version};
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

=cut

