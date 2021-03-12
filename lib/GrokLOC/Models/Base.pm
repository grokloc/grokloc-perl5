package GrokLOC::Models::Base;
use strictures 2;
use Moo;
use Types::Standard qw(Object Str);

# ABSTRACT: Base model inherited by other models.

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

has id => (
    is       => 'ro',
    isa      => Str->where('GrokLOC::Security::Input::safe_str $_'),
    required => 1,
);

has meta => (
    is       => 'ro',
    isa      => Object->where('$_->isa("GrokLOC::Models::Meta")'),
    required => 1,
);

1;

__END__

=head1 NAME

GrokLOC::Models::Base

=head1 SYNOPSIS

Base model.

=head1 DESCRIPTION

Base model inherited by other models.

=cut
