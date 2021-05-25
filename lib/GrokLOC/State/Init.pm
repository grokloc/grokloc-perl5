package GrokLOC::State::Init;
use strictures 2;
use Carp qw(croak);
use List::AllUtils qw(any);
use experimental qw(signatures switch);
use GrokLOC::Env qw(:all);
use GrokLOC::State::Unit;

# ABSTRACT: Initialize a State instance for the environment.

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

# Make the state instance available as a pkg var - this aids testing.
our $ST;

use base qw(Exporter);

sub state_init ($level) {
    croak 'no valid level' unless ( any { $_ eq $level } @LEVELS );
    given ($level) {
        when ($UNIT) {
            $ST = GrokLOC::State::Unit::init();
            return $ST;
        }
        default {
            croak 'no valid level';
        }
    }
    return;
}

our @EXPORT_OK   = qw(state_init $ST);
our %EXPORT_TAGS = ( all => [qw(state_init $ST)] );

1;

__END__

=head1 NAME

GrokLOC::State::Init

=head1 SYNOPSIS

Initialize per environmemt.

=head1 DESCRIPTION

Initialize a State instance for the environment.

=cut
