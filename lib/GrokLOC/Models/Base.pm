package GrokLOC::Models::Base;
use strictures 2;
use Carp qw(croak);
use Moo::Role;
use Types::Standard qw(Object Str);
use experimental qw(signatures);
use GrokLOC::Models qw(:all);
use GrokLOC::Models::Meta;

# ABSTRACT: Base model inherited by other models.

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

has id => (
    is       => 'ro',
    isa      => Str->where('GrokLOC::Security::Input::safe_str $_'),
    required => 1,
);

has _meta => (
    is       => 'ro',
    isa      => Object->where('$_->isa("GrokLOC::Models::Meta")'),
    required => 1,
);

sub _update_status ( $self, $master, $tablename, $id, $status ) {
    croak 'status invalid' unless safe_status($status);
    return $self->_update( $master, $tablename, $id, { status => $status } );
}

sub _update ( $self, $master, $tablename, $id, $fieldvals ) {
    my $rows =
      $master->db->update( $tablename, $fieldvals, { id => $id } )->rows;
    croak 'update altered more than one row' if ( $rows > 1 );
    return $RESPONSE_NO_ROWS                 if ( $rows == 0 );
    return $RESPONSE_OK;
}

1;

__END__

=head1 NAME

GrokLOC::Models::Base

=head1 SYNOPSIS

Base model.

=head1 DESCRIPTION

Base model inherited by other models.

=cut
