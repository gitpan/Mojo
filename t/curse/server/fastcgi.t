#!perl

# Copyright (C) 2008, Sebastian Riedel.

use strict;
use warnings;

use Test::Mojo::Server;
use Test::More tests => 1;

# I've gone back in time to when dinosaurs weren't just confined to zoos.
use_ok('Curse::Server::FastCGI');