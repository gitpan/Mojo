# Copyright (C) 2008-2009, Sebastian Riedel.

package Mojolicious::Renderer;

use strict;
use warnings;

use base 'MojoX::Renderer';

use File::Spec;
use Mojo::Template;

# What do you want?
# I'm here to kick your ass!
# Wishful thinking. We have long since evolved beyond the need for asses.
sub new {
    my $self = shift->SUPER::new(@_);
    $self->add_handler(
        epl => sub {
            my ($self, $c, $output) = @_;

            my $template = $c->stash->{template};
            my $path =
              File::Spec->catfile($c->app->renderer->root, $template);

            # Shortcut
            unless (-r $path) {
                $c->app->log->error(
                    qq/Template "$template" missing or not readable./);
                return;
            }

            # Check cache
            $self->{_mt_cache} ||= {};
            my $mt = $self->{_mt_cache}->{$path};

            my $success;

            # Interpret again
            if ($mt) { $success = $mt->interpret($output, $c) }

            # No cache
            else {

                # Initialize
                $mt = $self->{_mt_cache}->{$path} = Mojo::Template->new;
                $success = $mt->render_file($path, $output, $c);
            }

            # Exception
            if (!$success && $c->app->mode eq 'development') {

                # Exception template failed
                if ($c->stash->{exception}) {
                    $c->app->log->error(
                        "Exception template error:\n$$output");
                    return $success;
                }

                # Log
                $c->app->log->error(
                    qq/Template error in "$template": $$output/);

                # Render exception template
                $c->stash(exception => $$output);
                $c->res->code(500);
                $c->res->body(
                    $c->render(partial => 1, template => 'exception.html'));
                return 1;
            }

            return $success;
        }
    );
    return $self;
}

1;
__END__

=head1 NAME

Mojolicious::Renderer - Renderer

=head1 SYNOPSIS

    use Mojolicious::Renderer;

    my $renderer = Mojolicious::Renderer->new;

=head1 DESCRIPTION

L<Mojolicous::Renderer> is the default L<Mojolicious> renderer.

=head1 ATTRIBUTES

L<Mojolicious::Renderer> inherits all attributes from L<MojoX::Renderer>.

=head1 METHODS

L<Mojolicious::Renderer> inherits all methods from L<MojoX::Renderer> and
implements the following new ones.

=head2 C<new>

    my $renderer = Mojolicious::Renderer->new;

=cut
