package GrokLOC::Test;
use Carp qw( croak );
use Crypt::Misc qw( random_v4uuid );
use strictures 2;
use experimental qw(signatures try);
use GrokLOC::Models qw( $RESPONSE_OK $STATUS_ACTIVE );
use GrokLOC::Models::Org;
use GrokLOC::Models::User;
use GrokLOC::Security::Crypt qw( kdf salt );

# ABSTRACT: Useful testing utilities.

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

# Create a new user with ownership of a new org.
sub org_user ( $master, $key, $kdf_iterations ) {

    # Make org.
    my $org = GrokLOC::Models::Org->new( name => random_v4uuid );
    try {
        # Insert the org.
        my $insert_result = $org->insert($master);
        croak 'org insert fail' unless $insert_result == $RESPONSE_OK;

        # Update as active.
        my $update_result = $org->update_status( $master, $STATUS_ACTIVE );
        croak 'org update fail' unless $update_result == $RESPONSE_OK;
    }
    catch ($e) {
        croak 'org - unknown exception'
    }

    # Make user.
    my $user = GrokLOC::Models::User->new(
        display_name => random_v4uuid,
        email        => random_v4uuid,
        org          => $org->id,
        password => kdf( random_v4uuid, salt(random_v4uuid), $kdf_iterations ),
    );
    try {
        # Insert the user.
        my $insert_result = $user->insert( $master, $key );
        croak 'user insert fail' unless $insert_result == $RESPONSE_OK;

        # Update as active.
        my $update_result = $user->update_status( $master, $STATUS_ACTIVE );
        croak 'user update fail' unless $update_result == $RESPONSE_OK;
    }
    catch ($e) {
        croak 'user - unknown exception'
    }

    # Set the owner of the org to the user.
    try {
        my $update_result = $org->update_owner( $master, $user->id );
        croak 'org owner update fail' unless $update_result == $RESPONSE_OK;
    }
    catch ($e) {
        croak 'org owner - unknown exception'
    }

    # Re-read both org and user before returning.
    my $read_org = GrokLOC::Models::Org::read( $master, $org->id );
    croak 'read org failed' unless defined $read_org;
    my $read_user = GrokLOC::Models::User::read( $master, $key, $user->id );
    croak 'read user failed' unless defined $read_user;

    return $read_org, $read_user;
}

1;

__END__

=head1 NAME

GrokLOC::Test

=head1 SYNOPSIS

Useful testing utilities.

=head1 DESCRIPTION

Useful testing utilities.

=cut
