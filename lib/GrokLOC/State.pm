package GrokLOC::State;
use Object::Pad;
use strictures 2;
use Carp qw( croak );
use experimental qw(signatures);
use GrokLOC::Security::Input qw( safe_kdf_iterations safe_objs safe_str );

# ABSTRACT: Core state for the GrokLOC app.

## no critic (RequireEndWithOne);

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

class GrokLOC::State {

    has $master :reader;
    has @replicas;
    has $kdf_iterations :reader;
    has $key :reader;
    has $repo_base :reader;
    has $root_org :reader;
    has $root_user :reader;
    has $root_user_api_secret :reader;

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

        croak 'invalid key'
          unless ( exists $args{key} && safe_str( $args{key} ) );
        $key = $args{key};

        croak 'invalid repo_base' unless -e -w $args{repo_base};
        $repo_base = $args{repo_base};

        croak 'invalid root_org'
          unless ( exists $args{root_org} && safe_str( $args{root_org} ) );
        $root_org = $args{root_org};

        croak 'invalid root_user'
          unless ( exists $args{root_user} && safe_str( $args{root_user} ) );
        $root_user = $args{root_user};

        croak 'invalid root_user_api_secret'
          unless ( exists $args{root_user_api_secret}
            && safe_str( $args{root_user_api_secret} ) );
        $root_user_api_secret = $args{root_user_api_secret};
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
