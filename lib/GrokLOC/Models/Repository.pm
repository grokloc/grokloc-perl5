package GrokLOC::Models::Repository;
use Carp qw( croak );
use Object::Pad;
use Readonly ();
use strictures 2;
use experimental qw(signatures try);
use GrokLOC::Models qw(
  $REPOSITORIES_TABLENAME
  $RESPONSE_CONFLICT
  $RESPONSE_OK
);
use GrokLOC::Models::Base;
use GrokLOC::Models::Meta;
use GrokLOC::Security::Input qw( safe_objs safe_str );

# ABSTRACT: Repository model with persistence methods.

## no critic (RequireEndWithOne);

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

Readonly::Scalar our $SCHEMA_VERSION => 0;
Readonly::Scalar our $TABLENAME      => $REPOSITORIES_TABLENAME;

class GrokLOC::Models::Repository extends GrokLOC::Models::Base {
    has $name :reader;
    has $org :reader;
    has $repo_path :reader;
    has $upstream :reader;

    # repo_path should be the fully qualified path to the repo; the
    # caller can combine the state value repo_base with the relative
    # path to their repository
    BUILD(%args) {
        for my $k (qw(name org repo_path upstream)) {
            croak "missing/malformed $k"
              unless ( exists $args{$k} && safe_str( $args{$k} ) );
        }
        $name      = $args{name};
        $org       = $args{org};
        $repo_path = $args{repo_path};
        $upstream  = $args{upstream};

        # parent constructor will provide id, meta, so we're done
        return;
    }

    # insert can be called after ->new
    # call like:
    # try {
    #     $result = $repository->insert( $master );
    #     die 'insert failed' unless $result == $RESPONSE_OK;
    # }
    # catch ($e) {
    #     ...unknown error
    # }
    method insert ( $master ) {
        croak 'db ref'
          unless safe_objs( [$master], [ 'Mojo::SQLite', 'Mojo::Pg' ] );
        try {
            $master->db->insert(
                $TABLENAME,
                {
                    id             => $self->id,
                    name           => $self->name,
                    org            => $self->org,
                    repo_path      => $self->repo_path,
                    upstream       => $self->upstream,
                    status         => $self->meta->status,
                    schema_version => $SCHEMA_VERSION,
                }
            );
        }
        catch ($e) {
            return $RESPONSE_CONFLICT if ( $e =~ /unique/imsx );
            croak 'uncaught:' . $e;
        };
        return $RESPONSE_OK;
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
