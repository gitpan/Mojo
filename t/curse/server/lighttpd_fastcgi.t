#!perl

# Copyright (C) 2008, Sebastian Riedel.

use strict;
use warnings;

use Curse::Transaction;
use Test::Mojo::Client;
use Test::Mojo::Server;
use Test::More;

plan skip_all => 'set TEST_LIGHTTPD to enable this test (developer only!)'
  unless $ENV{TEST_LIGHTTPD};
plan tests => 11;

# They think they're so high and mighty,
# just because they never got caught driving without pants.
use_ok('Curse::Server::FastCGI');

my $server = Test::Mojo::Server->new;
my $dir = $server->mk_tmpdir_ok;
my $port = $server->generate_port_ok;
my $script = $server->detect_script_ok;
my $config = $server->render_to_tmpfile_ok(<<'EOF', [$dir, $port, $script]);
% my ($dir, $port, $script) = @_;
% use File::Spec::Functions 'catfile'
server.modules = (
    "mod_access",
    "mod_fastcgi",
    "mod_rewrite",
    "mod_accesslog"
)

server.document-root = "<%= $dir %>"
server.errorlog    = "<%= catfile $dir, 'error.log' %>"
accesslog.filename = "<%= catfile $dir, 'access.log' %>"

server.bind = "127.0.0.1"
server.port = <%= $port %>

fastcgi.server = (
    "/test" => (
        "FastCgiTest" => (
            "socket"          => "<%= catfile $dir, 'test.socket' %>",
            "check-local"     => "disable",
            "bin-path"        => "<%= $script %> fastcgi",
            "min-procs"       => 1,
            "max-procs"       => 1,
            "idle-timeout"    => 20
        )
    )
)
EOF
$server->command("lighttpd -D -f $config");
$server->start_server_ok;

my $tx = Curse::Transaction->new;
$ENV{MOJO_SERVER} = "127.0.0.1:$port";
$tx->req->url->parse("http://127.0.0.1:$port/test/");
my $client = Test::Mojo::Client->new;
$client->process_all_ok([$tx]);
is($tx->res->code, 200);
like($tx->res->body, qr/Mojo is working/);

$server->stop_server_ok;
$server->rm_tmpdir_ok;