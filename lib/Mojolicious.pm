# Copyright (C) 2008-2009, Sebastian Riedel.

package Mojolicious;

use strict;
use warnings;

use base 'Mojo';

use Mojo::Loader;
use Mojolicious::Renderer;
use MojoX::Dispatcher::Routes;
use MojoX::Dispatcher::Static;
use MojoX::Types;
use Time::HiRes ();

__PACKAGE__->attr(ctx_class => (default => 'Mojolicious::Context'));
__PACKAGE__->attr(
    mode => (default => sub { ($ENV{MOJO_MODE} || 'development') }));
__PACKAGE__->attr(
    renderer => (default => sub { Mojolicious::Renderer->new }));
__PACKAGE__->attr(
    routes => (default => sub { MojoX::Dispatcher::Routes->new }));
__PACKAGE__->attr(
    static => (default => sub { MojoX::Dispatcher::Static->new }));
__PACKAGE__->attr(types => (default => sub { MojoX::Types->new }));

# The usual constructor stuff
sub new {
    my $self = shift->SUPER::new(@_);

    # Namespace
    $self->routes->namespace(ref $self);

    # Types
    $self->renderer->types($self->types);
    $self->static->types($self->types);

    # Root
    $self->home->detect(ref $self);
    $self->renderer->root($self->home->rel_dir('templates'));
    $self->static->root($self->home->rel_dir('public'));

    # Mode
    my $mode = $self->mode;

    # Log file
    $self->log->path($self->home->rel_file("log/$mode.log"));

    # Run mode
    $mode = $mode . '_mode';
    $self->$mode if $self->can($mode);

    # Startup
    $self->startup(@_);

    # Load context class
    Mojo::Loader->new->load($self->ctx_class);

    return $self;
}

sub build_ctx {
    my $self = shift;
    return $self->ctx_class->new(app => $self, tx => shift);
}

# You could just overload this method
sub dispatch {
    my ($self, $c) = @_;

    # New request
    my $path = $c->req->url->path;
    $self->log->debug(qq/*** Request for "$path". ***/);

    # Try to find a static file
    my $e = $self->static->dispatch($c);

    # Use routes if we don't have a response yet
    $e = $self->routes->dispatch($c) if $e;

    # Exception
    if (ref $e) {

        # Development mode
        if ($self->mode eq 'development') {
            $c->stash(exception => $e);
            $c->res->code(500);
            $c->render(template => 'exception.html');
        }

        # Production mode
        else { $self->static->serve_500($c) }
    }

    # Nothing found
    elsif ($e) { $self->static->serve_404($c) }
}

# This will run for every request after dispatch
sub finalize { }

# Bite my shiny metal ass!
sub handler {
    my ($self, $tx) = @_;

    # Start timer
    my $start = [Time::HiRes::gettimeofday()];

    # Context
    my $c = $self->build_ctx($tx);

    # Prepare
    $self->prepare($c);

    # Dispatch unless we already have a response code
    $self->dispatch($c) unless $c->res->code;

    # Finalize
    $self->finalize($c);

    # End timer
    my $elapsed = sprintf '%f',
      Time::HiRes::tv_interval($start, [Time::HiRes::gettimeofday()]);
    my $rps = $elapsed == 0 ? '??' : sprintf '%.3f', 1 / $elapsed;
    $self->log->debug("Request took $elapsed seconds ($rps/s).");

    return $tx;
}

# This will run for every request before dispatch
sub prepare { }

# This will run once at startup
sub startup { }

1;
__END__

=head1 NAME

Mojolicious - Web Framework

=head1 SYNOPSIS

    use base 'Mojolicious';

    sub startup {
        my $self = shift;

        my $r = $self->routes;

        $r->route('/(controller)/(action)')
          ->to(controller => 'foo', action => 'bar');
    }

=head1 DESCRIPTION

L<Mojolicous> is a web framework built upon L<Mojo>.

See L<Mojo::Manual::Mojolicious> for user friendly documentation.

=head1 ATTRIBUTES

L<Mojolicious> inherits all attributes from L<Mojo> and implements the
following new ones.

=head2 C<mode>

    my $mode = $mojo->mode;
    $mojo    = $mojo->mode('production');

Returns the current mode if called without arguments.
Returns the invocant if called with arguments.
Defaults to C<$ENV{MOJO_MODE}> or C<development>.

    my $mode = $mojo->mode;
    if ($mode =~ m/^dev/) {
        do_debug_output();
    }

=head2 C<renderer>

    my $renderer = $mojo->renderer;
    $mojo        = $mojo->renderer(Mojolicious::Renderer->new);

=head2 C<routes>

    my $routes = $mojo->routes;
    $mojo      = $mojo->routes(Mojolicious::Dispatcher->new);

=head2 C<static>

    my $static = $mojo->static;
    $mojo      = $mojo->static(MojoX::Dispatcher::Static->new);

=head2 C<types>

    my $types = $mojo->types;
    $mojo     = $mojo->types(MojoX::Types->new)

=head1 METHODS

L<Mojolicious> inherits all methods from L<Mojo> and implements the following
new ones.

=head2 C<new>

    my $mojo = Mojolicious->new;

Returns a new L<Mojolicious> object.
This method will call the method C<${mode}_mode> if it exists.
(C<$mode> being the value of the attribute C<mode>).
For example in production mode, C<production_mode> will be called.

=head2 C<build_ctx>

    my $c = $mojo->build_ctx($tx);

=head2 C<dispatch>

    $mojo->dispatch($c);

=head2 C<finalize>

    $mojo->finalize($c);

=head2 C<handler>

    $tx = $mojo->handler($tx);

=head2 C<prepare>

    $mojo->prepare($c);

=head2 C<startup>

    $mojo->startup($tx);

=cut
