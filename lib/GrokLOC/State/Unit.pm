package GrokLOC::State::Unit;
use strictures 2;
use Carp qw( croak );
use Crypt::Misc qw( random_v4uuid );
use English qw(-no_match_vars);
use Mojo::SQLite;
use experimental qw(signatures);
use GrokLOC::Models ();
use GrokLOC::Models::Org;
use GrokLOC::Models::User;
use GrokLOC::Schemas;
use GrokLOC::Security::Crypt qw( key );
use GrokLOC::State;
use GrokLOC::Test;

# ABSTRACT: Initialize a State instance for the environment.

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

# unit_init initializes a State instance for the Unit environment.
sub init () {
    my $db     = 'sqlite::memory:?PrintError=0';
    my $master = Mojo::SQLite->new($db) || croak "new db: $ERRNO";
    $master->migrations->name('app')->from_string($GrokLOC::Schemas::APP);
    $master->migrations->migrate(0)->migrate || croak "migrate: $ERRNO";

    my $kdf_iterations = 1;
    my $key            = key(random_v4uuid);

    my ( $root_org, $root_user ) =
      GrokLOC::Test::org_user( $master, $key, $kdf_iterations );

    return GrokLOC::State->new(
        master               => $master,
        replicas             => [$master],
        kdf_iterations       => $kdf_iterations,
        key                  => $key,
        root_org             => $root_org->id,
        root_user            => $root_user->id,
        root_user_api_secret => $root_user->api_secret,
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
