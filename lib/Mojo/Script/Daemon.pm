# Copyright (C) 2008-2009, Sebastian Riedel.

package Mojo::Script::Daemon;

use strict;
use warnings;

use base 'Mojo::Script';

use Mojo::Server::Daemon;

use Getopt::Long 'GetOptionsFromArray';

__PACKAGE__->attr('description', default => <<'EOF');
Start application with HTTP 1.1 backend.
EOF
__PACKAGE__->attr('usage', default => <<"EOF");
usage: $0 daemon [OPTIONS]

These options are available:
  --clients <limit>       Set maximum number of concurrent clients, defaults
                          to 1000.
  --group <name>          Set group name of process.
  --keepalive <seconds>   Set keep-alive timeout, defaults to 15.
  --port <port>           Set port to start daemon on, defaults to 3000.
  --queue <size>          Set listen queue size, defaults to SOMAXCONN.
  --requests <limit>      Set the maximum number of requests per keep-alive
                          connection, defaults to 100.
  --user <name>           Set user name of process.
EOF


# This is the worst thing you've ever done.
# You say that so often that it lost its meaning.
sub run {
    my $self   = shift;
    my $daemon = Mojo::Server::Daemon->new;

    # Options
    my @options = @_ ? @_ : @ARGV;
    GetOptionsFromArray(
        \@options,
        'clients=i'   => sub { $daemon->max_clients($_[1]) },
        'group=s'     => sub { $daemon->group($_[1]) },
        'keepalive=i' => sub { $daemon->keep_alive_timeout($_[1]) },
        'port=i'      => sub { $daemon->port($_[1]) },
        'queue=i'     => sub { $daemon->listen_queue_size($_[1]) },
        'requests=i'  => sub { $daemon->max_keep_alive_requests($_[1]) },
        'user=s'      => sub { $daemon->user($_[1]) },
    );

    # Run
    $daemon->run;

    return $self;
}

1;
__END__

=head1 NAME

Mojo::Script::Daemon - Daemon Script

=head1 SYNOPSIS

    use Mojo::Script::Daemon;

    my $daemon = Mojo::Script::Daemon->new;
    $daemon->run(@ARGV);

=head1 DESCRIPTION

L<Mojo::Script::Daemon> is a script interface to
L<Mojo::Server::Daemon>.

=head1 ATTRIBUTES

L<Mojo::Script::Daemon> inherits all attributes from L<Mojo::Script> and
implements the following new ones.

=head2 C<description>

    my $description = $daemon->description;
    $daemon         = $daemon->description('Foo!');

=head2 C<usage>

    my $usage = $daemon->usage;
    $daemon   = $daemon->usage('Foo!');

=head1 METHODS

L<Mojo::Script::Daemon> inherits all methods from L<Mojo::Script> and
implements the following new ones.

=head2 C<run>

    $daemon = $daemon->run(@ARGV);

=cut
