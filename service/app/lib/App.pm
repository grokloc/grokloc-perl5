package App;
use strictures 2;
use Carp qw(croak);
use Mojo::Base 'Mojolicious';
use experimental qw(signatures);
use GrokLOC::App::Message qw(app_msg);
use GrokLOC::App::Routes qw(:all);
use GrokLOC::Env qw(:all);
use GrokLOC::State::Init qw(state_init);

# ABSTRACT: Core package for the GrokLOC app.

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

sub startup ($self) {
    my $level = $ENV{$GROKLOC_ENV} // croak 'level env';
    my $st    = state_init($level);
    $self->helper( st => sub ($self) { return $st; } );
    my $started_at = time;
    $self->helper( started_at => sub ($self) { return $started_at; } );
    $self->routes_init;
    $self->log->info('app startup');
    return;
}

sub routes_init ($self) {
    my $r = $self->routes;

    # GET /ok -> ok, no auth.
    $r->get($OK_ROUTE)->to('api-v0-ok#ok');

    # Everything under /api/v0 requires a user/org/auth session in the stash.
    # Child routes of $with_session should not include the /api/v0 part.
    my $with_session = $r->under($API_ROUTE)->to('api-v0-auth#with_session');

    # Request a new token.
    $with_session->post($TOKEN_REQUEST)->to('api-v0-auth#new_token');

    # Root-authenticated status.
    $with_session->get($STATUS)->to('api-v0-status#status');

    # Create a new org.
    $with_session->post($ORG)->to('api-v0-org#create');

    $r->any(
        '/*whatever' => { whatever => q{} } => sub ($c) {
            my $whatever = $c->param('whatever');
            $c->render(
                app_msg( 404, { error => $whatever . ': not found' } ) );
            return;
        }
    );
    return;
}

1;

__END__

=head1 NAME

App

=head1 SYNOPSIS

Core package for the GrokLOC app.

=head1 DESCRIPTION

Core package for the GrokLOC app.

=cut
