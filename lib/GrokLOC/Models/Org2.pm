package GrokLOC::Models::Org2;
use Object::Pad;
use strictures 2;
use Carp qw(croak);
use Readonly;
use experimental qw(signatures);
use GrokLOC::Models qw(:all);
use GrokLOC::Models::Base2;
use GrokLOC::Models::Meta2;
use GrokLOC::Security::Input qw(:validators);

# ABSTRACT: Org model with persistence methods.

## no critic (RequireEndWithOne);

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

Readonly::Scalar our $SCHEMA_VERSION => 0;
Readonly::Scalar our $TABLENAME      => $ORGS_TABLENAME;

class GrokLOC::Models::Org2 extends GrokLOC::Models::Base2 {
    has $name :reader;
    has $owner :reader;

    BUILD(%args) {
        croak 'missing/malformed name'
          unless ( exists $args{name} && safe_str( $args{name} ) );
        my $len = scalar keys %args;
        if ( 1 == $len ) {

            # New. Owner will be set to the default.
            $name  = $args{name};
            $owner = $NO_OWNER;
            return;
        }

        # Otherwise, populate with all args.
        $name = $args{name};
        croak 'missing/malformed owner'
          unless ( exists $args{owner} && safe_str( $args{owner} ) );
        $owner = $args{owner};

        # Parent constructor catches the rest.
        return;
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

1;

__END__

=head1 NAME

GrokLOC::Models::Org2

=head1 SYNOPSIS

Org model.

=head1 DESCRIPTION

Org model with persistence methods.

=cut
