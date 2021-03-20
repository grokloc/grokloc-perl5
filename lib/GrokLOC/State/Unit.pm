package GrokLOC::State::Unit;
use strictures 2;
use Carp qw(croak);
use Crypt::Digest::SHA256 qw(sha256_b64);
use Crypt::Misc qw(random_v4uuid);
use English qw(-no_match_vars);
use File::Spec;
use File::Temp qw(tempdir);
use Mojo::SQLite;
use Test::Mock::Redis;
use experimental qw(signatures);
use GrokLOC::Env qw(:all);
use GrokLOC::Models qw(:all);
use GrokLOC::Schemas;
use GrokLOC::Security::Crypt qw(:all);
use GrokLOC::State;

# ABSTRACT: Initialize a State instance for the environment.

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

# unit_init initializes a State instance for the Unit environment.
sub init() {
    my $db     = 'sqlite:' . File::Spec->catfile( tempdir, 'app.db' );
    my $master = Mojo::SQLite->new($db) || croak "new db: $ERRNO";
    $master->migrations->name('app')->from_string($GrokLOC::Schemas::APP);
    $master->migrations->migrate(0)->migrate || croak "migrate: $ERRNO";

    my $kdf_iterations = 1;
    my $key            = key(random_v4uuid);

    # Set up the initial test root org and user. Tests need these.
    my $root_org  = $ENV{ROOT_ORG}  // croak 'unit env root org';
    my $root_user = $ENV{ROOT_USER} // croak 'unit env root user';
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

    my ( $display, $email, $password ) =
      ( random_v4uuid, random_v4uuid, random_v4uuid );
    $master->db->insert(
        $USERS_TABLENAME,
        {
            id => $root_user,
            api_secret =>
              encrypt( $root_user_api_secret, $key, iv($root_user) ),
            api_secret_digest => sha256_b64($root_user_api_secret),
            display           => encrypt( $display, $key, iv($root_user) ),
            display_digest    => sha256_b64($display),
            email             => encrypt( $email, $key, iv($root_user) ),
            email_digest      => sha256_b64($email),
            org               => $root_org,
            password => kdf( $password, salt($root_user), $kdf_iterations ),
            status   => $STATUS_ACTIVE,
        }
    );

    return GrokLOC::State->new(
        master         => $master,
        replicas       => [$master],
        cache          => Test::Mock::Redis->new( server => $UNIT ),
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
