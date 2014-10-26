#!perl

# Copyright (C) 2008-2009, Sebastian Riedel.

package Test::Foo;

use strict;
use warnings;

use base 'MojoX::Dispatcher::Routes::Controller';

sub bar {
    return 1;
}

# I was all of history's greatest acting robots -- Acting Unit 0.8,
# Thespomat, David Duchovny!
package main;

use strict;
use warnings;

use Test::More tests => 5;

use Mojo;
use MojoX::Dispatcher::Routes;
use MojoX::Dispatcher::Routes::Context;

my $c = MojoX::Dispatcher::Routes::Context->new(app => Mojo->new);

# Silence
$c->app->log->path(undef);
$c->app->log->level('error');

my $d = MojoX::Dispatcher::Routes->new;
ok($d);

$d->namespace('Test');
$d->route('/foo/:capture')->to(controller => 'foo', action => 'bar');

# No escaping
$c->tx(_tx('/foo/hello'));
is($d->dispatch($c), 1);
is_deeply($c->stash,
    {controller => 'foo', action => 'bar', capture => 'hello'});

# Escaping
$c->tx(_tx('/foo/hello%20there'));
is($d->dispatch($c), 1);
is_deeply($c->stash,
    {controller => 'foo', action => 'bar', capture => 'hello there'});

# Helper
sub _tx {
    my $tx = Mojo::Transaction->new_post;
    $tx->req->url->path->parse(@_);
    return $tx;
}
