#!perl

# Copyright (C) 2008, Sebastian Riedel.

use strict;
use warnings;

use Curse::Transaction;
use File::Spec::Functions 'catfile';
use Test::Mojo::Client;
use Test::Mojo::Server;
use Test::More;

plan skip_all => 'set TEST_LIGHTTPD to enable this test (developer only!)'
  unless $ENV{TEST_LIGHTTPD};
plan tests => 13;

# Hey, we didn't have a message on our answering machine when we left.
# How very odd.
use_ok('Curse::Server::CGI');

# Lighttpd
my $server = Test::Mojo::Server->new;
my $dir = $server->mk_tmpdir_ok;
my $port = $server->generate_port_ok;
my $config = $server->render_to_tmpfile_ok(<<'EOF', [$dir, $port]);
% my ($dir, $port) = @_;
% use File::Spec::Functions 'catfile'
server.modules = (
    "mod_access",
    "mod_cgi",
    "mod_rewrite",
    "mod_accesslog"
)

server.document-root = "<%= $dir %>"
server.errorlog    = "<%= catfile $dir, 'error.log' %>"
accesslog.filename = "<%= catfile $dir, 'access.log' %>"

server.bind = "127.0.0.1"
server.port = <%= $port %>

cgi.assign = ( ".pl"  => "<%= $^X %>",
               ".cgi" => "<%= $^X %>" )
EOF
$server->command("lighttpd -D -f $config");

# CGI
my $lib = $server->detect_lib_ok;
my $cgi = $server->render_to_file_ok(<<'EOF', 'test.cgi', [$lib]);
#!<%= $^X %>

use strict;
use warnings;

use lib '<%= shift %>';

use Curse::Server::CGI;

Curse::Server::CGI->new->run;

1;
EOF
chmod 0777, $cgi;
ok(-x $cgi);

# Start
$server->start_server_ok;

my $tx = Curse::Transaction->new;
$ENV{MOJO_SERVER} = "127.0.0.1:$port";
$tx->req->url->parse("http://127.0.0.1:$port/test.cgi");
my $client = Test::Mojo::Client->new;
$client->process_all_ok([$tx]);
is($tx->res->code, 200);
like($tx->res->body, qr/Mojo is working/);

# Stop
$server->stop_server_ok;

# Cleanup
$server->rm_tmpdir_ok;