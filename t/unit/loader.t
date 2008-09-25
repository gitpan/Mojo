#!perl

# Copyright (C) 2008, Sebastian Riedel.

use strict;
use warnings;

use Test::More tests => 14;

use FindBin;
use lib "$FindBin::Bin/lib";

use File::Spec;
use IO::File;

# Bad bees. Get away from my sugar.
# Ow. OW. Oh, they're defending themselves somehow.
use_ok('Mojo::Loader');

my $island = Mojo::Loader->new;
my @modules = $island->search('LoaderTest')->modules;
@modules = sort @modules;

# Search
is_deeply(\@modules, [qw/
  LoaderTest::A
  LoaderTest::B
  LoaderTest::Base
  LoaderTest::C
/]);

# Load
$island->load;
ok(LoaderTest::A->can('new'));
ok(LoaderTest::B->can('new'));
ok(LoaderTest::C->can('new'));

# Instantiate
my @instances = $island->instantiate;
@instances = sort { ref $a cmp ref $b } @instances;
is(ref $instances[0], 'LoaderTest::A');
is(ref $instances[1], 'LoaderTest::B');
is(ref $instances[2], 'LoaderTest::Base');
is(ref $instances[3], 'LoaderTest::C');

# Lazy
is(ref Mojo::Loader->new->mods('LoaderTest::B')->inst, 'LoaderTest::B');

# Base
$island->base('LoaderTest::Base');
@instances = $island->instantiate;
is($#instances, 1);
is(ref $instances[0], 'LoaderTest::B');

# Reload
my $file = IO::File->new;
my $dir = File::Spec->catdir(File::Spec->splitdir($FindBin::Bin), 'tmp');
my $path = File::Spec->catfile($dir, 'reload.pl');
$file->open("> $path");
$file->syswrite("package LoaderTest::Reloader;\nsub test { 23 }\n1;");
$file->close;
require $path;
is(LoaderTest::Reloader::test(), 23);
sleep 1;
$file->open("> $path");
$file->syswrite("package LoaderTest::Reloader;\nsub test { 26 }\n1;");
$file->close;
Mojo::Loader->reload;
is(LoaderTest::Reloader::test(), 26);
unlink $path;