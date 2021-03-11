package GrokLOC::State::Unit;
use strictures 2;
use Carp qw(croak);
use Crypt::Misc qw(random_v4uuid);
use English qw(-no_match_vars);
use File::Spec;
use File::Temp qw(tempdir);
use Mojo::SQLite;
use Test::Mock::Redis;
use experimental qw(signatures);
use GrokLOC::Env qw(:all);
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
    return GrokLOC::State->new(
        master         => $master,
        replicas       => [$master],
        cache          => Test::Mock::Redis->new( server => $UNIT ),
        kdf_iterations => 1,
        root_org       => random_v4uuid,
        key            => key(random_v4uuid),
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
