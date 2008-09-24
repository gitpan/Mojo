#!perl

# Copyright (C) 2008, Sebastian Riedel.

use strict;
use warnings;

use Test::More tests => 14;

use FindBin;
use lib "$FindBin::Bin/lib";

use File::Spec::Functions qw/catdir catfile splitdir/;
use File::Path 'rmtree';
use IO::File;

# Bad bees. Get away from my sugar.
# Ow. OW. Oh, they're defending themselves somehow.
use_ok('Nevermore::Loader');

my $island = Nevermore::Loader->new;
my @modules = $island->search('NevermoreTest')->modules;
@modules = sort @modules;

# Search
is_deeply(\@modules, [qw/
  NevermoreTest::A
  NevermoreTest::B
  NevermoreTest::Base
  NevermoreTest::C
/]);

# Load
$island->load;
ok(NevermoreTest::A->can('new'));
ok(NevermoreTest::B->can('new'));
ok(NevermoreTest::C->can('new'));

# Instantiate
my @instances = $island->instantiate;
@instances = sort { ref $a cmp ref $b } @instances;
is(ref $instances[0], 'NevermoreTest::A');
is(ref $instances[1], 'NevermoreTest::B');
is(ref $instances[2], 'NevermoreTest::Base');
is(ref $instances[3], 'NevermoreTest::C');

# Lazy
is(ref Nevermore::Loader->new->modules('NevermoreTest::B')->instantiate,
  'NevermoreTest::B');

# Base
$island->base('NevermoreTest::Base');
@instances = $island->instantiate;
is($#instances, 1);
is(ref $instances[0], 'NevermoreTest::B');

# Reload
rmtree 'tmp' if -e 'tmp';
my $file = IO::File->new;
my $dir = catdir(splitdir($FindBin::Bin), 'tmp');
mkdir $dir;
my $path = catfile($dir, 'reload.pl');
$file->open("> $path");
$file->syswrite("package NevermoreTest::Reloader;\nsub test { 23 }\n1;");
$file->close;
require $path;
is(NevermoreTest::Reloader::test(), 23);
sleep 1;
$file->open("> $path");
$file->syswrite(
    "package NevermoreTest::Reloader;\nsub test { 26 }\n1;"
);
$file->close;
Nevermore::Loader->reload;
is(NevermoreTest::Reloader::test(), 26);
rmtree $dir;