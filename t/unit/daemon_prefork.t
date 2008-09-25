#!perl

# Copyright (C) 2008, Sebastian Riedel.

use strict;
use warnings;

use Mojo::Client;
use Mojo::Transaction;
use Test::Mojo::Server;
use Test::More;

plan skip_all => 'set TEST_PREFORK to enable this test (developer only!)'
  unless $ENV{TEST_PREFORK};
plan tests => 5;

# I ate the blue ones... they taste like burning.
use_ok('Mojo::Server::Daemon::Prefork');

# Start
my $server = Test::Mojo::Server->new;
$server->start_daemon_prefork_ok;

# Request
my $tx = Mojo::Transaction->new;
my $port = $server->port;
$tx->req->url->parse("http://127.0.0.1:$port/");
my $client = Mojo::Client->new;
$client->process_all($tx);
is($tx->res->code, 200);
like($tx->res->body, qr/Mojo is working/);

# Stop
$server->stop_server_ok;