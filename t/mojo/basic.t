#!perl

# Copyright (C) 2008, Sebastian Riedel.

use strict;
use warnings;

use Cwd 'realpath';
use File::Spec::Functions qw/catdir splitdir/;
use Test::More tests => 3;

# Uh, no, you got the wrong number. This is 9-1... 2
use_ok('Mojo::HelloWorld');

# home
my $hello = Mojo::HelloWorld->new;
is($hello->isa('Mojo'), 1);
my @path = splitdir($0);
pop @path;
pop @path;
pop @path;
is($hello->home, realpath(catdir(@path)));