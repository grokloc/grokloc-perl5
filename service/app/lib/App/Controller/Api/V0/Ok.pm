package App::Controller::Api::V0::Ok;
use strictures 2;
use Mojo::Base 'Mojolicious::Controller';
use experimental qw(signatures);
use GrokLOC::App::Message qw(app_msg);

# ABSTRACT: Ok (unathenticated ping) handler.

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

sub ok_ ( $c ) {
    $c->render( app_msg( 200, { ping => 'ok' } ) );
    return 1;
}

1;

__END__

=head1 NAME

App::Controller::Api::V0::Ok

=head1 SYNOPSIS

Ok (unathenticated ping) handler.

=head1 DESCRIPTION

Ok (unathenticated ping) handler.

=cut
