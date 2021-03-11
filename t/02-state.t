package main;
use strictures 2;
use Test2::V0;
use Test2::Tools::Exception;
use GrokLOC::Env qw(:all);
use GrokLOC::State::Init qw(:all);

ok(
    lives {
        state_init($UNIT);
    }
) or note($@);

done_testing;

1;
