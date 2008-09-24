#!perl

# Copyright (C) 2008, Sebastian Riedel.

use strict;
use warnings;

use Test::More tests => 31;

# What good is money if it can't inspire terror in your fellow man?
use_ok('Curse::Cookie::Request');
use_ok('Curse::Cookie::Response');

# Request cookie as string
my $cookie = Curse::Cookie::Request->new;
$cookie->name('foo');
$cookie->value('ba =r');
$cookie->path('/test');
$cookie->version(1);
is("$cookie", 'foo=ba =r; $Path=/test');
is($cookie->as_string_with_prefix, '$Version=1; foo=ba =r; $Path=/test');

# Parse normal request cookie
$cookie = Curse::Cookie::Request->new;
my @cookies = $cookie->parse('$Version=1; foo=bar; $Path="/test"');
is($cookies[0]->name, 'foo');
is($cookies[0]->value, 'bar');
is($cookies[0]->path, '/test');
is($cookies[0]->version, '1');

# Parse quoted request cookie
$cookie = Curse::Cookie::Request->new;
@cookies = $cookie->parse('$Version=1; foo="b a\" r\"\\"; $Path="/test"');
is($cookies[0]->name, 'foo');
is($cookies[0]->value, 'b a" r"\\');
is($cookies[0]->path, '/test');
is($cookies[0]->version, '1');

# Parse multiple cookie request
@cookies = Curse::Cookie::Request->parse(
  '$Version=1; foo=bar; $Path=/test; baz=la la; $Path=/tset'
);
is($cookies[0]->name, 'foo');
is($cookies[0]->value, 'bar');
is($cookies[0]->path, '/test');
is($cookies[0]->version, '1');
is($cookies[1]->name, 'baz');
is($cookies[1]->value, 'la la');
is($cookies[1]->path, '/tset');
is($cookies[1]->version, '1');

# Response cookie as string
$cookie = Curse::Cookie::Response->new;
$cookie->name('foo');
$cookie->value('ba r');
$cookie->path('/test');
$cookie->version(1);
is("$cookie", 'foo=ba r; Version=1; Path=/test');

# Full response cookie as string (full)
$cookie = Curse::Cookie::Response->new;
$cookie->name('foo');
$cookie->value('ba r');
$cookie->domain('kraih.com');
$cookie->path('/test');
$cookie->max_age(1218092879);
$cookie->expires(1218092879);
$cookie->secure(1);
$cookie->comment('lalalala');
$cookie->version(1);
is("$cookie", 'foo=ba r; Version=1; Domain=kraih.com; Path=/test;'
  . ' Max_Age=1218092879; expires=Thu, 07 Aug 2008 07:07:59 GMT;'
  . ' Secure=1; Comment=lalalala');

# Parse response cookie
@cookies = Curse::Cookie::Response->parse(
  'foo=ba r; Version=1; Domain=kraih.com; Path=/test; Max_Age=1218092879;'
  . ' expires=Thu, 07 Aug 2008 07:07:59 GMT; Secure=1; Comment=lalalala'
);
is($cookies[0]->name, 'foo');
is($cookies[0]->value, 'ba r');
is($cookies[0]->domain, 'kraih.com');
is($cookies[0]->path, '/test');
is($cookies[0]->max_age, 1218092879);
is($cookies[0]->expires, 'Thu, 07 Aug 2008 07:07:59 GMT');
is($cookies[0]->secure, '1');
is($cookies[0]->comment, 'lalalala');
is($cookies[0]->version, '1');