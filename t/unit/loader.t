#!perl

# Copyright (C) 2008, Sebastian Riedel.

use strict;
use warnings;

use Test::More tests => 14;

use FindBin;
use lib "$FindBin::Bin/lib";

use File::Spec;
use File::Temp;
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
my $dir = File::Temp::tempdir();
my $path = File::Spec->catfile($dir, 'MojoTestReloader.pm');
$file->open("> $path");
$file->syswrite("package MojoTestReloader;\nsub test { 23 }\n1;");
$file->close;
push @INC, $dir;
require MojoTestReloader;
is(MojoTestReloader::test(), 23);
sleep 1;
$file->open("> $path");
$file->syswrite("package MojoTestReloader;\nsub test { 26 }\n1;");
$file->close;
Mojo::Loader->reload;
is(MojoTestReloader::test(), 26);