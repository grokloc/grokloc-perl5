package GrokLOC::State;
use strictures 2;
use English qw(-no_match_vars);
use Mojo::SQLite;
use Moo;
use Types::Standard qw(ArrayRef Object);
use experimental qw(signatures switch);
use GrokLOC::Env qw(:all);
use GrokLOC::Security::Input qw(:validators);

# ABSTRACT: Core state for the GrokLOC app.

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

has master => (
    is       => 'ro',
    isa      => Object->where('safe_objs([$_],["Mojo::SQLite","Mojo::Pg"])'),
    required => 1,
);

has replicas => (
    is => 'rw',
    isa =>
      ( ArrayRef [Object] )->where('safe_objs($_,["Mojo::SQLite","Mojo::Pg"])'),
    required => 1,
);

1;

__END__

=head1 NAME

GrokLOC::State

=head1 SYNOPSIS

State instance info for the GrokLOC app.

=head1 DESCRIPTION

State instance info for the GrokLOC app.

=cut
