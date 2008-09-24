# Copyright (C) 2008, Sebastian Riedel.

package Test::Mojo::Server;

use strict;
use warnings;

use base 'Nevermore';

use FindBin;
use lib "$FindBin::Bin/lib";

use Cwd 'realpath';
use File::Path qw/mkpath rmtree/;
use File::Spec::Functions qw/catdir catfile splitdir/;
use FindBin;
use IO::Socket::INET;
use Test::Builder::Module;
use Voodoo;

__PACKAGE__->attr('command', chained => 1);
__PACKAGE__->attr('debug',   chained => 1, default => sub { 0 });
__PACKAGE__->attr('pid',     chained => 1);
__PACKAGE__->attr('port',    chained => 1);
__PACKAGE__->attr('script',  chained => 1, default => sub { 'mojo.pl' });
__PACKAGE__->attr('timeout', chained => 1, default => sub { 5 });
__PACKAGE__->attr('tmpdir',  chained => 1);

# Hello, my name is Barney Gumble, and I'm an alcoholic.
# Mr Gumble, this is a girl scouts meeting.
# Is it, or is it you girls can't admit that you have a problem?
sub new {
    my $self = shift->SUPER::new();
    $self->{_tb} = Test::Builder->new;
    return $self;
}

sub detect_lib_ok {
    my ($self, $desc) = @_;
    my $tb = $self->{_tb};

    my $script = $self->_detect_script;
    return $tb->ok(0, $desc) unless $script;

    my @dir = splitdir $script;
    pop @dir;

    # Detect mojo.pl
    my $path = catdir @dir, 'lib';
    return $path if -d $path;
    for my $i (1 .. 5) {
        $path = catdir @dir, ('..') x $i, 'lib';
        last if -d $path;
    }
    if (-d $path) {
        $tb->ok(1, $desc);
        return $path;
    }
    return $tb->ok(0, $desc);
}

sub detect_script_ok {
    my ($self, $desc) = @_;
    my $tb = $self->{_tb};

    my $path = $self->_detect_script;

    # mojo.pl not found
    unless ($path) {
        $tb->diag('Unable to find mojo.pl');
        return $tb->ok(0, $desc);
    }

    $tb->ok(1, $desc);
    return $path;
}

sub generate_port_ok {
    my ($self, $desc) = @_;
    my $tb = $self->{_tb};

    my $port = $self->_generate_port;
    if ($port) {
        $tb->ok(1, $desc);
        return $port;
    }

    $tb->ok(0, $desc);
    return 0;
}

sub mk_tmpdir_ok {
    my ($self, $desc) = @_;
    my $tb = $self->{_tb};
    my $path = $self->tmpdir(
        realpath(catdir(splitdir($FindBin::Bin), 'tmp'))
    )->tmpdir;
    rmtree($path) if -e $path;
    mkpath($path) or return $tb->ok(0, $desc);
    $tb->ok(1, $desc);
    return $path;
}

sub render_to_file_ok {
    my ($self, $src, $file, $args, $desc) = @_;
    my $tb = $self->{_tb};

    return $tb->ok(0, $desc) unless $self->tmpdir;

    # File
    my $path = catfile $self->tmpdir, $file;

    # Render
    my @args = $args ? @{$args} : ();
    my $voodoo = Voodoo->new;
    $voodoo->render_to_file($src, $path, @args)
      ? $tb->ok(1, $desc)
      : $tb->ok(0, $desc);
    return $path;
}

sub render_to_tmpfile_ok {
    my ($self, $src, $args, $desc) = @_;
    my $tb = $self->{_tb};

    return $tb->ok(0, $desc) unless $self->tmpdir;

    # Generate file
    my $file;
    my $i = 1;
    while ($i++) {
        $file = $i;
        last unless -e catfile($self->tmpdir, $i);
    }

    return $self->render_to_file_ok($src, $file, $args, $desc);
}

sub rm_tmpdir_ok {
    my ($self, $desc) = @_;
    my $tb = $self->{_tb};
    my $path = $self->tmpdir;
    rmtree($path) or return $tb->ok(0, $desc);
    return $tb->ok(1, $desc);
}

sub server_ok {
    my ($self, $desc) = @_;
    my $tb = $self->{_tb};

    # Not running
    unless ($self->port) {
        $tb->diag('No port specified for testing');
        return $tb->ok(0, $desc);
    }

    # Test
    my $ok = $self->_check_server(1) ? 1 : 0;
    $tb->ok($ok, $desc);
}

sub start_daemon_ok {
    my ($self, $desc) = @_;
    my $tb = $self->{_tb};

    # Port
    my $port = $self->port || $self->_generate_port;
    return $tb->ok(0, $desc) unless $port;

    # Path
    my $path = $self->_detect_script;
    return $tb->ok(0, $desc) unless $path;

    # Prepare command
    $self->command("$^X $path daemon $port");

    return $self->start_server_ok($desc);
}

sub start_daemon_prefork_ok {
    my ($self, $desc) = @_;
    my $tb = $self->{_tb};

    # Port
    my $port = $self->port || $self->_generate_port;
    return $tb->ok(0, $desc) unless $port;

    # Path
    my $path = $self->_detect_script;
    return $tb->ok(0, $desc) unless $path;

    # Prepare command
    $self->command("$^X $path daemon_prefork $port");
    

    return $self->start_server_ok($desc);
}

sub start_server_ok {
    my ($self, $desc) = @_;
    my $tb = $self->{_tb};

    # Start server
    my $pid = $self->_start_server;
    return $tb->ok(0, $desc) unless $pid;

    # Wait for server
    my $timeout = $self->timeout;
    my $time_before = time;
    while ($self->_check_server != 1) {

        # Timeout
        $timeout -= time - $time_before;
        if ($timeout <= 0) {
            $self->_stop_server;
            $tb->diag('Server timed out');
            return $tb->ok(0, $desc);
        }

        # Wait
        sleep 1;
    }

    # Done
    $tb->ok(1, $desc);

    return $self->port;
}

sub start_server_untested_ok {
    my ($self, $desc) = @_;
    my $tb = $self->{_tb};

    # Start server
    my $pid = $self->_start_server($desc);
    return $tb->ok(0, $desc) unless $pid;

    # Done
    $tb->ok(1, $desc);

    return $self->port;
}

sub stop_server_ok {
    my ($self, $desc) = @_;
    my $tb = $self->{_tb};

    # Running?
    unless ($self->pid && kill 0, $self->pid) {
        $tb->diag('Server not running');
        return $tb->ok(0, $desc);
    }

    # Debug
    sysread $self->{_server}, my $buffer, 4096;
    warn "\nSERVER STDOUT: $buffer\n" if $self->debug;

    # Stop server
    $self->_stop_server();
    if ($self->_check_server) {
        $tb->diag("Can't stop server");
        $tb->ok(0, $desc);
    }
    else { $tb->ok(1, $desc) }
}

sub _check_server {
    my ($self, $diag) = @_;

    # Create socket
    my $server = IO::Socket::INET->new(
        Proto    => 'tcp',
        PeerAddr => 'localhost',
        PeerPort => $self->port
    );

    # Close socket
    if ($server) {
        close $server;
        return 1;
    }
    else {
        $self->{_tb}->diag("Server check failed: $!") if $diag;
        return 0
    }
}

sub _detect_script {
    my $self = shift;

    # Detect mojo.pl
    my $path;
    my $script = $self->script;
    for my $i (1 .. 5) {
        $path = catfile(splitdir($FindBin::Bin), ('..') x $i, $script);
        last if -f $path;
        $path = catfile(
            splitdir($FindBin::Bin), ('..') x $i, 'script', $script
        );
        last if -f $path;
    }
    $path = realpath($path);
    return -f $path ? $path : 0;
}

sub _generate_port {
    my $self = shift;

    # Try ports
    my $port = 1 . int(rand 10) . int(rand 10) . int(rand 10) . int(rand 10);
    while ( $port++ < 30000 ) {
        my $server = IO::Socket::INET->new(
            Listen    => 5,
            LocalAddr => '127.0.0.1',
            LocalPort => $port,
            Proto     => 'tcp'
        );
        return $self->port($port)->port;
    }

    return 0;
}

sub _start_server {
    my $self = shift;
    my $tb = $self->{_tb};

    my $command = $self->command;
    warn "\nSERVER COMMAND: $command\n" if $self->debug;

    # Run server
    my $pid = open($self->{_server}, "$command |");
    $self->pid($pid);

    # Process started?
    unless ($pid) { 
        $tb->diag("Can't start server: $!");
        return 0;
    }

    $self->{_server}->blocking(0);

    return $pid;
}

sub _stop_server {
    my $self = shift;

    # Kill server
    kill 'INT', $self->pid;
    close $self->{_server};
    $self->pid(undef);
    undef $self->{_server};
}

1;
__END__

=head1 NAME

Test::Mojo::Server - Server Tests

=head1 SYNOPSIS

    use Curse::Transaction;
    use Mojo::Test::Server;

    my $server = Test::Mojo::Server->new;
    $server->start_daemon_ok;
    $server->stop_server_ok;

=head1 DESCRIPTION

L<Mojo::Test::Server> is a test harness for server tests.

=head1 ATTRIBUTES

=head2 C<command>

    my $command = $server->command;
    $server     = $server->command("lighttpd -D -f $config");

=head2 C<debug>

    my $debug = $server->debug;
    $server   = $server->debug(1);

=head2 C<pid>

    my $pid = $server->pid;

=head2 C<port>

    my $port = $server->port;
    $server  = $server->port(3000);

=head2 C<script>

    my $script = $server->script;
    $server    = $server->script('mojo.pl');

=head2 C<timeout>

    my $timeout = $server->timeout;
    $server     = $server->timeout(5);

=head2 C<tmpdir>

    my $tmpdir = $server->tmpdir;
    $server    = $server->tmpdir('/tmp/foo');

=head1 METHODS

L<Mojo::Test::Server> inherits all methods from L<Nevermore> and implements
the following new ones.

=head2 C<new>

    my $server = Mojo::Test::Server->new;

=head2 C<detect_lib_ok>

    my $lib = $server->detect_lib_ok;
    my $lib = $server->detect_lib_ok('lib test');

=head2 C<detect_script_ok>

    my $script = $server->detect_script_ok;
    my $script = $server->detect_script_ok('script test');

=head2 C<generate_port_ok>

    my $port = $server->generate_port_ok;
    my $port = $server->generate_port_ok('port test');

=head2 C<mk_tmpdir_ok>

    my $tmpdir = $server->mk_tmpdir_ok;
    my $tmpdir = $server->mk_tmpdir_ok('tmpdir test');

=head2 C<render_to_file_ok>

    my $file = $server->render_to_file_ok($template, '/tmp/file.txt');
    my $file = $server->render_to_file_ok(
        $template,
        '/tmp/file.txt',
        [qw/foo bar/],
        'file test'
    );

=head2 C<render_to_tmpfile_ok>

    my $tmpfile = $server->render_to_tmpfile_ok($template);
    my $tmpfile = $server->render_to_tmpfile_ok(
        $template,
        [qw/foo bar/],
        'file test'
    );

=head2 C<rm_tmpdir_ok>

    $server->rm_tmpdir_ok('cleanup test');

=head2 C<server_ok>

    $server->server_ok('server running');

=head2 C<start_daemon_ok>

    my $port = $server->start_daemon_ok('daemon test');

=head2 C<start_daemon_prefork_ok>

    my $port = $server->start_daemon_prefork_ok('prefork daemon test');

=head2 C<start_server_ok>

    my $port = $server->start_server_ok('server test');

=head2 C<start_server_untested_ok>

    my $port = $server->start_server_untested_ok('server test');

=head2 C<stop_server_ok>

    $server->stop_server_ok('server stopped');

=cut