package GrokLOC::State;
use Object::Pad;
use strictures 2;
use Carp qw(croak);
use Mojo::SQLite;
use experimental qw(signatures);
use GrokLOC::Security::Input qw(:validators);

# ABSTRACT: Core state for the GrokLOC app.

## no critic (RequireEndWithOne);

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

class GrokLOC::State {

    has $master :reader;
    has @replicas;
    has $kdf_iterations :reader;
    has $root_org :reader;
    has $key :reader;

    BUILD(%args) {
        croak 'invalid master'
          unless ( exists $args{master}
            && safe_objs( [ $args{master} ], [ 'Mojo::SQLite', 'Mojo::Pg' ] ) );
        $master = $args{master};
        croak 'invalid replicas'
          unless ( exists $args{replicas}
            && ref( $args{replicas} ) eq 'ARRAY'
            && safe_objs( $args{replicas}, [ 'Mojo::SQLite', 'Mojo::Pg' ] ) );
        @replicas = @{ $args{replicas} };
        croak 'invalid kdf iterations'
          unless ( exists $args{kdf_iterations}
            && safe_kdf_iterations( $args{kdf_iterations} ) );
        $kdf_iterations = $args{kdf_iterations};
        croak 'invalid root_org'
          unless ( exists $args{root_org} && safe_str( $args{root_org} ) );
        $root_org = $args{root_org};
        croak 'invalid key'
          unless ( exists $args{key} && safe_str( $args{key} ) );
        $key = $args{key};
    }

    method random_replica {
        return $replicas[ int rand scalar @replicas ];
    }
}

1;

__END__

=head1 NAME

GrokLOC::State

=head1 SYNOPSIS

State instance info for the GrokLOC app.

=head1 DESCRIPTION

State instance info for the GrokLOC app.

=cut
