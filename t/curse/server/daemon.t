#!perl

# Copyright (C) 2008, Sebastian Riedel.

use strict;
use warnings;

use Test::Mojo::Server;
use Test::More tests => 3;

# Daddy, I'm scared. Too scared to even wet my pants.
# Just relax and it'll come, son.
use_ok('Curse::Server::Daemon');

my $server = Test::Mojo::Server->new;
$server->start_daemon_ok;
$server->stop_server_ok;