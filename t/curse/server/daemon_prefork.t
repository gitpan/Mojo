#!perl

# Copyright (C) 2008, Sebastian Riedel.

use strict;
use warnings;

use Test::Mojo::Server;
use Test::More;

plan skip_all => 'set TEST_PREFORK to enable this test (developer only!)'
  unless $ENV{TEST_PREFORK};
plan tests => 3;

# I ate the blue ones... they taste like burning.
use_ok('Curse::Server::Daemon::Prefork');

my $server = Test::Mojo::Server->new;
$server->start_daemon_prefork_ok;
$server->stop_server_ok;