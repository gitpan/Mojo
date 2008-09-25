# Copyright (C) 2008, Sebastian Riedel.

package Mojo::Server;

use strict;
use warnings;

use base 'Mojo::Base';

use Carp;
use Mojo::Loader;

__PACKAGE__->attr('handler',
    chained => 1,
    default => sub {
        return sub {
            my ($self, $tx) = @_;

            # Hello world!
            $ENV{MOJO_APP} ||= 'Mojo::HelloWorld';

            # Reload
            my $env = $ENV{MOJO_ENV} || '';
            Mojo::Loader->reload if $env eq 'development';

            # Application
            my $app = $self->{_mojo_app};
            $app = $self->{_mojo_app} = Mojo::Loader->new
              ->mods($ENV{MOJO_APP})
              ->inst
              if ($env eq 'development') || !$app;
            $app->handler($tx);

            return $tx;
        };
    }
);

# It's up to the subclass to decide where log messages go
sub log {
    my ($self, $msg) = @_;
    my $time = localtime(time);
    warn "[$time] [$$] $msg\n";
}

# Are you saying you're never going to eat any animal again? What about bacon?
# No.
# Ham?
# No.
# Pork chops?
# Dad, those all come from the same animal.
# Heh heh heh. Ooh, yeah, right, Lisa. A wonderful, magical animal.
sub run { croak 'Method "run" not implemented by subclass' }

1;
__END__

=head1 NAME

Mojo::Server - Server Base Class

=head1 SYNOPSIS

    use base 'Mojo::Server';

=head1 DESCRIPTION

L<Mojo::Server> is a generic server base class.

=head1 ATTRIBUTES

=head2 C<handler>

    my $handler = $server->handler;
    $server     = $server->handler(sub {
        my ($self, $tx) = @_;
        return $tx;
    });

=head1 METHODS

L<Mojo::Server> inherits all methods from L<Mojo::Base> and implements the
following new ones.

=head2 C<log>

    $server->log('Test 123');

=head2 C<run>

    $server->run;

=cut