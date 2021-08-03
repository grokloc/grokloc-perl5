package GrokLOC::Models::Repository;
use Carp qw( croak );
use Object::Pad;
use Readonly ();
use strictures 2;
use experimental qw(signatures try);
use GrokLOC::Models qw(
  $REPOSITORIES_TABLENAME
);
use GrokLOC::Models::Base;
use GrokLOC::Models::Meta;
use GrokLOC::Security::Input qw( safe_str );

# ABSTRACT: Repository model with persistence methods.

## no critic (RequireEndWithOne);

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

Readonly::Scalar our $SCHEMA_VERSION => 0;
Readonly::Scalar our $TABLENAME      => $REPOSITORIES_TABLENAME;

class GrokLOC::Models::Repository extends GrokLOC::Models::Base {
    has $name :reader;
    has $org :reader;
    has $subdir :reader;
    has $upstream :reader;

    BUILD(%args) {
        for my $k (qw(name org subdir upstream)) {
            croak "missing/malformed $k"
              unless ( exists $args{$k} && safe_str( $args{$k} ) );
        }
        $name     = $args{name};
        $org      = $args{org};
        $subdir   = $args{subdir};
        $upstream = $args{upstream};

        # parent constructor will provide id, meta, so we're done
        return;
    }
}

1;

__END__

=head1 NAME

GrokLOC::Models::Repository

=head1 SYNOPSIS

Repository model.

=head1 DESCRIPTION

Repository model with persistence methods.

=cut
