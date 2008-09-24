# Copyright (C) 2008, Sebastian Riedel.

package Curse::Server;

use strict;
use warnings;

use base 'Nevermore';

use Carp;
use Nevermore::Loader;

__PACKAGE__->attr('handler',
    chained => 1,
    default => sub {
        return sub {
            my ($self, $tx) = @_;

            # Hello world!
            $ENV{MOJO_APP} ||= 'Mojo::HelloWorld';

            # Reload
            my $env = $ENV{MOJO_ENV} || '';
            if ($env eq 'development') {
                Nevermore::Loader->reload;
            }

            # Application
            my $app = $self->{_mojo_app};
            $app = $self->{_mojo_app} = Nevermore::Loader->new
              ->modules($ENV{MOJO_APP})
              ->instantiate
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

Curse::Server - Server Base Class

=head1 SYNOPSIS

    use base 'Curse::Server';

=head1 DESCRIPTION

L<Curse::Server> is a generic server base class.

=head1 ATTRIBUTES

=head2 C<handler>

    my $handler = $server->handler;
    $server     = $server->handler(sub {
        my ($self, $tx) = @_;
        return $tx;
    });

=head1 METHODS

L<Curse::Server> inherits all methods from L<Nevermore> and implements the
following new ones.

=head2 C<log>

    $server->log('Test 123');

=head2 C<run>

    $server->run;

=cut