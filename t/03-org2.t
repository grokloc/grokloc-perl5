package main;
use strictures 2;
use Crypt::Misc qw(random_v4uuid);
use Test2::V0;
use Test2::Tools::Exception;
use GrokLOC::Env qw(:all);
use GrokLOC::Models qw(:all);
use GrokLOC::Models::Org2;
use GrokLOC::State::Init qw(state_init);

my $st;

ok(
    lives {
        $st = state_init($UNIT);
    }
) or note($@);

my $org;

ok(
    dies {
        GrokLOC::Models::Org2->new;
    }
) or note($@);

my $name = random_v4uuid;

ok(
    lives {
        $org = GrokLOC::Models::Org2->new( name => $name );
    }
) or note($@);

is( $org->name,  $name,     'name' );
is( $org->owner, $NO_OWNER, 'owner' );
isnt( $org->id, q{}, 'id' );
is( ref( $org->meta ), 'GrokLOC::Models::Meta2', 'meta' );

my $id    = random_v4uuid;
my $owner = random_v4uuid;

ok(
    lives {
        $org = GrokLOC::Models::Org2->new(
            name  => $name,
            owner => $owner,
            id    => $id
        );
    }
) or note($@);

is( $org->name,        $name,                    'name' );
is( $org->owner,       $owner,                   'owner' );
is( $org->id,          $id,                      'id' );
is( ref( $org->meta ), 'GrokLOC::Models::Meta2', 'meta' );

done_testing;

1;
