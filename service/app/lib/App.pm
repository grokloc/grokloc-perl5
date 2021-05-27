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
    $self->hooks_init;
    $self->routes_init;
    $self->log->info('app startup');
    return;
}

sub hooks_init ($self) {
    $self->hook(
        before_render => sub ( $c, $args ) {
            return unless my $template = $args->{template};
            return unless $template eq 'exception';
            return unless $c->accepts('json');
            $self->log->error( $c->stash('exception') );
            my %h = app_msg( 500, { error => 'internal error' } );
            $args->{json} = $h{json};
        }
    );
    return;
}

sub routes_init ($self) {
    my $r = $self->routes;

    # route endpoints have a suffix of _, middlewares do not

    # GET /ok -> ok, no auth.
    $r->get($OK_ROUTE)->to('api-v0-ok#ok_');

    # everything under /api/v0 requires a user/org/auth session in the stash
    # child routes of $with_session should not include the /api/v0 part
    my $with_session = $r->under($API_ROUTE)->to('api-v0-auth#with_session');

    # request a new token
    $with_session->post($TOKEN_REQUEST)->to('api-v0-auth#new_token_');

    # root-authenticated status
    $with_session->get($STATUS)->to('api-v0-status#status_');

    # create a new org
    $with_session->post($ORG)->to('api-v0-org#create_');

    my $org_id = $ORG . '/:id';

    # read an org
    $with_session->get($org_id)->to('api-v0-org#read_');

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
