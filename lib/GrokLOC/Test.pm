package GrokLOC::Test;
use Carp qw(croak);
use Crypt::Misc qw(random_v4uuid);
use strictures 2;
use experimental qw(signatures try);
use GrokLOC::Models qw(:all);
use GrokLOC::Models::Org;
use GrokLOC::Models::User;
use GrokLOC::Security::Crypt qw(:all);
use GrokLOC::Security::Input qw(:validators);

# ABSTRACT: Useful testing utilities.

## no critic (RequireFinalReturn);

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

# Create a new user with ownership of a new org.
sub test_user_org ( $st ) {
    croak 'state ref' unless safe_objs( [$st], ['GrokLOC::State'] );

    # Make org.
    my $org = GrokLOC::Models::Org->new( name => random_v4uuid );
    try {
        # Insert the org.
        my $insert_result = $org->insert( $st->master );
        croak 'org insert fail' unless $insert_result == $RESPONSE_OK;

        # Update as active.
        my $update_result = $org->update_status( $st->master, $STATUS_ACTIVE );
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
        password     =>
          kdf( random_v4uuid, salt(random_v4uuid), $st->kdf_iterations ),
        key => $st->key,
    );
    try {
        # Insert the user.
        my $insert_result = $user->insert( $st->master );
        croak 'user insert fail' unless $insert_result == $RESPONSE_OK;

        # Update as active.
        my $update_result = $user->update_status( $st->master, $STATUS_ACTIVE );
        croak 'user update fail' unless $update_result == $RESPONSE_OK;
    }
    catch ($e) {
        croak 'user - unknown exception'
    }

    # Set the owner of the org to the user.
    try {
        my $update_result = $org->update_owner( $st->master, $user->id );
        croak 'org owner update fail' unless $update_result == $RESPONSE_OK;
    }
    catch ($e) {
        croak 'org owner - unknown exception'
    }

    return $org, $user;
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
