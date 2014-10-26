# Copyright (C) 2008-2009, Sebastian Riedel.

package MojoX::Dispatcher::Routes;

use strict;
use warnings;

use base 'MojoX::Routes';

use Mojo::ByteStream;
use Mojo::Loader;
use Mojo::Loader::Exception;

__PACKAGE__->attr('disallow',
    default => sub { [qw/new app attr render req res stash/] });
__PACKAGE__->attr('namespace');

# Hey. What kind of party is this? There's no booze and only one hooker.
sub dispatch {
    my ($self, $c, $match) = @_;

    # Match
    $match = $self->match($match || $c->tx->req->url->path->to_string)
      unless ref $match;
    $c->match($match);

    # No match
    return 1 unless $match && @{$match->stack};

    # Initialize stash with captures
    my %captures = %{$match->captures};
    foreach my $key (keys %captures) {
        $captures{$key} =
          Mojo::ByteStream->new($captures{$key})->url_unescape->to_string;
    }
    $c->stash({%captures});

    # Walk the stack
    my $e = $self->walk_stack($c);
    return $e if $e;

    # Render
    $self->render($c);

    # All seems ok
    return 0;
}

sub generate_class {
    my ($self, $c, $field) = @_;

    # Class
    my $class = $field->{class};
    my $controller = $field->{controller} || '';
    unless ($class) {
        my @class;
        for my $part (split /-/, $controller) {

            # Junk
            next unless $part;

            # Camelize
            push @class, Mojo::ByteStream->new($part)->camelize;
        }
        $class = join '::', @class;
    }

    # Format
    my $namespace = $field->{namespace} || $self->namespace;
    $class = length $class ? "${namespace}::$class" : $namespace;

    # Invalid
    return undef unless $class =~ /^[a-zA-Z0-9_:]+$/;

    return $class;
}

sub generate_method {
    my ($self, $c, $field) = @_;

    # Prepare disallow
    unless ($self->{_disallow}) {
        $self->{_disallow} = {};
        $self->{_disallow}->{$_}++ for @{$self->disallow};
    }

    my $method = $field->{method};
    $method ||= $field->{action};

    # Shortcut for disallowed methods
    return undef if $self->{_disallow}->{$method};
    return undef if index($method, '_') == 0;

    # Invalid
    return undef unless $method =~ /^[a-zA-Z0-9_:]+$/;

    return $method;
}

sub render {
    my ($self, $c) = @_;

    # Render
    $c->render unless $c->stash->{rendered} || $c->res->code;
}

sub walk_stack {
    my ($self, $c) = @_;

    # Walk the stack
    for my $field (@{$c->match->stack}) {

        # Don't cache errors
        local $@;

        # Method
        my $method = $self->generate_method($c, $field);
        next unless $method;

        # Class
        my $class = $self->generate_class($c, $field);
        next unless $class;

        # Debug
        $c->app->log->debug(qq/Dispatching "${class}::$method"./);

        # Captures
        $c->match->captures($field);

        # Load class
        $self->{_loaded} ||= {};
        my $e = 0;
        unless ($self->{_loaded}->{$class}) {
            $e = Mojo::Loader->new->load($class);
            $self->{_loaded}->{$class}++ unless $e;
        }

        # Load error
        if ($e && $e->loaded) {
            $c->app->log->debug($e);
            return $e;
        }

        # Check class
        eval {
            die
              unless $class->isa('MojoX::Dispatcher::Routes::Controller');
        };

        # Not a conroller
        if ($@) {
            $c->app->log->debug(qq/"$class" is not a controller./);
            return 1;
        }

        # Dispatch
        my $done;
        eval { $done = $class->new(ctx => $c)->$method($c) };

        # Controller error
        if ($@) {
            my $e = Mojo::Loader::Exception->new($class, $@);
            $c->app->log->debug($e);
            return $e;
        }

        # Break the chain
        last unless $done;
    }

    # Done
    return 0;
}

1;
__END__

=head1 NAME

MojoX::Dispatcher::Routes - Routes Dispatcher

=head1 SYNOPSIS

    use MojoX::Dispatcher::Routes;

    my $dispatcher = MojoX::Dispatcher::Routes->new;

=head1 DESCRIPTION

L<MojoX::Dispatcher::Routes> is a dispatcher based on L<MojoX::Routes>.

=head2 ATTRIBUTES

L<MojoX::Dispatcher::Routes> inherits all attributes from L<MojoX::Routes>
and implements the follwing the ones.

=head2 C<disallow>

    my $disallow = $dispatcher->disallow;
    $dispatcher  = $dispatcher->disallow(
        [qw/new attr ctx render req res stash/]
    );

=head2 C<namespace>

    my $namespace = $dispatcher->namespace;
    $dispatcher   = $dispatcher->namespace('Foo::Bar::Controller');

=head1 METHODS

L<MojoX::Dispatcher::Routes> inherits all methods from L<MojoX::Routes> and
implements the follwing the ones.

=head2 C<dispatch>

    my $exception = $dispatcher->dispatch(
        MojoX::Dispatcher::Routes::Context->new
    );
    my $exception = $dispatcher->dispatch(
        MojoX::Dispatcher::Routes::Context->new,
        MojoX::Routes::Match->new
    );
    my $exception = $dispatcher->dispatch(
        MojoX::Dispatcher::Routes::Context->new,
        '/foo/bar/baz'
    );

=head2 C<generate_class>

    my $class = $dispatcher->generate_class($c, $field);

=head2 C<generate_method>

    my $method = $dispatcher->genrate_method($c, $field);

=head2 C<render>

    $dispatcher->render($c);

=head2 C<walk_stack>

    my $exception = $dispatcher->walk_stack($c);

=cut
