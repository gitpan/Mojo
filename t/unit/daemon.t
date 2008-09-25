#!perl

# Copyright (C) 2008, Sebastian Riedel.

use strict;
use warnings;

use Mojo::Client;
use Mojo::Transaction;
use Test::Mojo::Server;
use Test::More tests => 5;

# Daddy, I'm scared. Too scared to even wet my pants.
# Just relax and it'll come, son.
use_ok('Mojo::Server::Daemon');

# Start
my $server = Test::Mojo::Server->new;
$server->start_daemon_ok;

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