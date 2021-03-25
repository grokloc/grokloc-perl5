package GrokLOC::Models::Meta;
use Object::Pad;
use strictures 2;
use Carp qw(croak);
use experimental qw(signatures);
use GrokLOC::Models qw(:all);
use GrokLOC::Security::Input qw(:validators);

# ABSTRACT: Metadata model.

## no critic (RequireEndWithOne);

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

class GrokLOC::Models::Meta {
    has $status :reader;
    has $ctime :reader;
    has $mtime :reader;

    BUILD(%args) {
        ( $status, $ctime, $mtime ) = ( $STATUS_UNCONFIRMED, 0, 0 );
        if ( exists $args{status} ) {
            croak 'status invalid' unless safe_status( $args{status} );
            $status = $args{status};
        }
        if ( exists $args{ctime} ) {
            croak 'ctime invalid' unless safe_unixtime( $args{ctime} );
            $ctime = $args{ctime};
        }
        if ( exists $args{mtime} ) {
            croak 'mtime invalid' unless safe_unixtime( $args{mtime} );
            $mtime = $args{mtime};
        }
    }

    method TO_JSON {
        return {
            status => $status,
            ctime  => $ctime,
            mtime  => $mtime,
        };
    }
}

1;

__END__

=head1 NAME

GrokLOC::Models::Meta

=head1 SYNOPSIS

Metadata model.

=head1 DESCRIPTION

Metadata model.

=cut
