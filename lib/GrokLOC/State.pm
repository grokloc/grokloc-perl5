package GrokLOC::State;
use strictures 2;
use English qw(-no_match_vars);
use Mojo::SQLite;
use Moo;
use Types::Standard qw(ArrayRef Int Object Str);
use experimental qw(signatures);
use GrokLOC::Env qw(:all);
use GrokLOC::Security::Input qw(:validators);
use GrokLOC::Security::Crypt qw(:lens);

# ABSTRACT: Core state for the GrokLOC app.

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

has master => (
    is  => 'ro',
    isa => Object->where(
        'GrokLOC::Security::Input::safe_objs([$_],["Mojo::SQLite","Mojo::Pg"])'
    ),
    required => 1,
);

has replicas => (
    is  => 'ro',
    isa => ( ArrayRef [Object] )->where(
        'GrokLOC::Security::Input::safe_objs($_,["Mojo::SQLite","Mojo::Pg"])'),
    required => 1,
);

has cache => (
    is  => 'ro',
    isa => Object->where(
'GrokLOC::Security::Input::safe_objs([$_],["Redis","Test::Mock::Redis"])'
    ),
    required => 1,
);

has kdf_iterations => (
    is       => 'ro',
    isa      => Int->where('$_ > 0 && $_ < 32'),
    required => 1,
);

has root_org => (
    is       => 'ro',
    isa      => Str->where('length $_ != 0'),
    required => 1,
);

has key => (
    is       => 'ro',
    isa      => Str->where('length $_ == $GrokLOC::Security::Crypt::KEY_LEN'),
    required => 1,
);

# random_replica returns a random replica - the safe_objs call insures
# that this list is not empty at construction.
sub random_replica($self) {
    my @replicas = @{ $self->replicas };
    return $replicas[ rand @replicas ];
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
