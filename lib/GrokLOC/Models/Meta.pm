package GrokLOC::Models::Meta;
use Object::Pad;
use strictures 2;
use Carp qw( croak );
use experimental qw(signatures);
use GrokLOC::Models qw( $STATUS_UNCONFIRMED safe_status );
use GrokLOC::Security::Input qw( safe_unixtime );

# ABSTRACT: Metadata model.

## no critic (RequireEndWithOne);

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

class GrokLOC::Models::Meta {
    has $status : reader = $STATUS_UNCONFIRMED;
    has $ctime  : reader = 0;
    has $mtime  : reader = 0;

    BUILD(%args) {
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
