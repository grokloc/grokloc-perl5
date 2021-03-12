package GrokLOC::Models::Meta;
use strictures 2;
use Moo;
use Types::Standard qw(Int Enum);
use experimental qw(signatures);
use GrokLOC::Models qw(:all);
use GrokLOC::Security::Input qw(:validators);

# ABSTRACT: Metadata model.

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

has status => (
    is  => 'ro',
    isa => Enum [ $STATUS_UNCONFIRMED, $STATUS_ACTIVE, $STATUS_INACTIVE,
        $STATUS_ADMIN, ],
    required => 0,
    default  => $STATUS_UNCONFIRMED,
);

has ctime => (
    is       => 'ro',
    isa      => Int->where('GrokLOC::Security::Input::safe_unixtime $_'),
    required => 0,
    default  => 0,
);

has mtime => (
    is       => 'ro',
    isa      => Int->where('GrokLOC::Security::Input::safe_unixtime $_'),
    required => 0,
    default  => 0,
);

sub TO_JSON($self) {
    return {
        status => $self->status,
        ctime  => $self->ctime,
        mtime  => $self->mtime,
    };
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
