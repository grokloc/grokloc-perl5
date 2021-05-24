package GrokLOC::State::Unit;
use strictures 2;
use Carp qw(croak);
use Crypt::Digest::SHA256 qw(sha256_b64);
use Crypt::Misc qw(random_v4uuid);
use English qw(-no_match_vars);
use File::Spec;
use File::Temp qw(tempdir);
use Mojo::SQLite;
use experimental qw(signatures);
use GrokLOC::Env qw(:all);
use GrokLOC::Models qw(:all);
use GrokLOC::Models::Org;
use GrokLOC::Models::User;
use GrokLOC::Schemas;
use GrokLOC::Security::Crypt qw(:all);
use GrokLOC::State;

# ABSTRACT: Initialize a State instance for the environment.

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

# unit_init initializes a State instance for the Unit environment.
sub init () {
    my $db     = 'sqlite:' . File::Spec->catfile( tempdir, 'app.db' );
    my $master = Mojo::SQLite->new($db) || croak "new db: $ERRNO";
    $master->migrations->name('app')->from_string($GrokLOC::Schemas::APP);
    $master->migrations->migrate(0)->migrate || croak "migrate: $ERRNO";

    my $kdf_iterations = 1;
    my $key            = random_v4uuid;

    # Set up the initial test root org and user. Tests need these.
    my $root_org             = $ENV{ROOT_ORG}  // croak 'unit env root org';
    my $root_user            = $ENV{ROOT_USER} // croak 'unit env root user';
    my $root_user_api_secret = $ENV{ROOT_USER_API_SECRET}
      // croak 'unit env root user api secret';

    # Insert root org/user without calling the Model packages - those require
    # an initialized State instance, which isn't ready yet.
    $master->db->insert(
        $ORGS_TABLENAME,
        {
            id     => $root_org,
            name   => 'root',
            owner  => $root_user,
            status => $STATUS_ACTIVE,
        }
    );

    my ( $display_name, $email, $password ) =
      ( random_v4uuid, random_v4uuid, random_v4uuid );

    my $email_digest = sha256_b64($email);

    $master->db->insert(
        $USERS_TABLENAME,
        {
            id         => $root_user,
            api_secret =>
              encrypt( $root_user_api_secret, key($key), iv($email_digest) ),
            api_secret_digest => sha256_b64($root_user_api_secret),
            display_name      =>
              encrypt( $display_name, key($key), iv($email_digest) ),
            display_name_digest => sha256_b64($display_name),
            email        => encrypt( $email, key($key), iv($email_digest) ),
            email_digest => $email_digest,
            org          => $root_org,
            password     => kdf( $password, salt($root_user), $kdf_iterations ),
            status       => $STATUS_ACTIVE,
        }
    );

    return GrokLOC::State->new(
        master         => $master,
        replicas       => [$master],
        kdf_iterations => $kdf_iterations,
        root_org       => $root_org,
        key            => $key,
    );
}

1;

__END__

=head1 NAME

GrokLOC::State::Unit

=head1 SYNOPSIS

Initialize for the Unit environment.

=head1 DESCRIPTION

Initialize a State instance for the Unit environment.

=cut
