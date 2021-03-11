package main;
use strictures 2;
use Test2::V0;
use Test2::Tools::Exception;
use GrokLOC::Security::Input qw(:all);

isnt( 1, safe_str('') );
isnt( 1, safe_str( '.' x ( $STR_MAX + 1 ) ) );
isnt( 1, safe_str('DROP') );
isnt( 1, safe_str('drop') );
isnt( 1, safe_str('"') );

isnt( 1, safe_unixtime('string') );
isnt( 1, safe_unixtime(-1) );
isnt( 1, safe_unixtime( $UNIXTIME_MAX + 1 ) );

done_testing;

1;
