#!perl

# Copyright (C) 2008, Sebastian Riedel.

use strict;
use warnings;

use Test::More;

plan skip_all => 'set TEST_CLIENT to enable this test'
  unless $ENV{TEST_CLIENT};
plan tests => 4;

# So then I said to the cop, "No, you're driving under the influence...
# of being a jerk".
use_ok('Curse::Client');
use_ok('Curse::Transaction');

# Parallel async io
my $client = Curse::Client->new;
my $tx = Curse::Transaction->new;
$tx->req->method('POST');
$tx->req->url->parse('http://kraih.com');
$tx->req->headers->expect('100-continue');
$tx->req->body('foo bar baz');
my $tx2 = Curse::Transaction->new;
$tx2->req->method('GET');
$tx2->req->url->parse('http://labs.kraih.com');
$tx2->req->headers->expect('100-continue');
$tx2->req->body('foo bar baz');
my @transactions = ($tx, $tx2);
while (1) {
    $client->spin(@transactions);
    my @buffer;
    while (my $transaction = shift @transactions) {
        unless ($transaction->is_state(qw/done error/)) {
            push @buffer, $transaction;
        }
    }
    push @transactions, @buffer;
    last unless @transactions;
}
is($tx->res->code, 200);
is($tx2->res->code, 301);