#!perl

# Copyright (C) 2008, Sebastian Riedel.

use strict;
use warnings;

use Test::More tests => 160;

# When will I learn?
# The answer to life's problems aren't at the bottom of a bottle,
# they're on TV!
use_ok('Curse::Cache::File');
use_ok('Curse::Content');
use_ok('Curse::Content::MultiPart');
use_ok('Curse::Cookie::Request');
use_ok('Curse::Cookie::Response');
use_ok('Curse::Headers');
use_ok('Curse::Message::Request');
use_ok('Curse::Message::Response');

# Parse HTTP 1.1 start line, no headers and body
my $req = Curse::Message::Request->new;
$req->parse("GET / HTTP/1.1\x0d\x0a\x0d\x0a");
is($req->state, 'done');
is($req->method, 'GET');
is($req->major_version, 1);
is($req->minor_version, 1);
is($req->url, '/');

# Parse HTTP 1.0 start line and headers, no body
$req = Curse::Message::Request->new;
$req->parse("GET /foo/bar/baz.html HTTP/1.0\x0d\x0a");
$req->parse("Content-Type: text/plain\x0d\x0a");
$req->parse("Content-Length: 0\x0d\x0a\x0d\x0a");
is($req->state, 'done');
is($req->method, 'GET');
is($req->major_version, 1);
is($req->minor_version, 0);
is($req->url, '/foo/bar/baz.html');
is($req->headers->content_type, 'text/plain');
is($req->headers->content_length, 0);

# Parse full HTTP 1.0 request
$req = Curse::Message::Request->new;
$req->parse('GET /foo/bar/baz.html?fo');
$req->parse("o=13#23 HTTP/1.0\x0d\x0aContent");
$req->parse('-Type: text/');
$req->parse("plain\x0d\x0aContent-Length: 27\x0d\x0a\x0d\x0aHell");
$req->parse("o World!\n1234\nlalalala\n");
is($req->state, 'done');
is($req->method, 'GET');
is($req->major_version, 1);
is($req->minor_version, 0);
is($req->url, '/foo/bar/baz.html?foo=13#23');
is($req->headers->content_type, 'text/plain');
is($req->headers->content_length, 27);

# Parse HTTP 0.9 request
$req = Curse::Message::Request->new;
$req->parse("GET /\x0d\x0a\x0d\x0a");
is($req->state, 'done');
is($req->method, 'GET');
is($req->major_version, 0);
is($req->minor_version, 9);
is($req->url, '/');

# Parse HTTP 1.1 chunked request
$req = Curse::Message::Request->new;
$req->parse("POST /foo/bar/baz.html?foo=13#23 HTTP/1.1\x0d\x0a");
$req->parse("Content-Type: text/plain\x0d\x0a");
$req->parse("Transfer-Encoding: chunked\x0d\x0a\x0d\x0a");
$req->parse("4\x0d\x0a");
$req->parse("abcd\x0d\x0a");
$req->parse("9\x0d\x0a");
$req->parse("abcdefghi\x0d\x0a");
$req->parse("0\x0d\x0a");
is($req->state, 'done');
is($req->method, 'POST');
is($req->major_version, 1);
is($req->minor_version, 1);
is($req->url, '/foo/bar/baz.html?foo=13#23');
is($req->headers->content_type, 'text/plain');
is($req->content->cache->cache_size, 13);
is($req->content->cache->slurp, 'abcdabcdefghi');

# Parse HTTP 1.1 chunked request with trailing headers
$req = Curse::Message::Request->new;
$req->parse("POST /foo/bar/baz.html?foo=13#23 HTTP/1.1\x0d\x0a");
$req->parse("Content-Type: text/plain\x0d\x0a");
$req->parse("Transfer-Encoding: chunked\x0d\x0a");
$req->parse("Trailer: X-Trailer1; X-Trailer2\x0d\x0a\x0d\x0a");
$req->parse("4\x0d\x0a");
$req->parse("abcd\x0d\x0a");
$req->parse("9\x0d\x0a");
$req->parse("abcdefghi\x0d\x0a");
$req->parse("0\x0d\x0a");
$req->parse("X-Trailer1: test\x0d\x0a");
$req->parse("X-Trailer2: 123\x0d\x0a\x0d\x0a");
is($req->state, 'done');
is($req->method, 'POST');
is($req->major_version, 1);
is($req->minor_version, 1);
is($req->url, '/foo/bar/baz.html?foo=13#23');
is($req->headers->content_type, 'text/plain');
is($req->headers->header('X-Trailer1'), 'test');
is($req->headers->header('X-Trailer2'), '123');
is($req->content->cache->cache_size, 13);
is($req->content->cache->slurp, 'abcdabcdefghi');

# Parse HTTP 1.1 multipart request
$req = Curse::Message::Request->new;
$req->parse("GET /foo/bar/baz.html?foo=13#23 HTTP/1.1\x0d\x0a");
$req->parse("Content-Length: 814\x0d\x0a");
$req->parse('Content-Type: multipart/form-data; bo');
$req->parse("undary=----------0xKhTmLbOuNdArY\x0d\x0a\x0d\x0a");
$req->parse("\x0d\x0a------------0xKhTmLbOuNdArY\x0d\x0a");
$req->parse("Content-Disposition: form-data; name=\"text1\"\x0d\x0a");
$req->parse("\x0d\x0ahallo welt test123\n");
$req->parse("\x0d\x0a------------0xKhTmLbOuNdArY\x0d\x0a");
$req->parse("Content-Disposition: form-data; name=\"text2\"\x0d\x0a");
$req->parse("\x0d\x0a\x0d\x0a------------0xKhTmLbOuNdArY\x0d\x0a");
$req->parse('Content-Disposition: form-data; name="upload"; file');
$req->parse("name=\"hello.pl\"\x0d\x0a");
$req->parse("Content-Type: application/octet-stream\x0d\x0a\x0d\x0a");
$req->parse("#!/usr/bin/perl\n\n");
$req->parse("use strict;\n");
$req->parse("use warnings;\n\n");
$req->parse("print \"Hello World :)\\n\"\n");
$req->parse("\x0d\x0a------------0xKhTmLbOuNdArY--");
is($req->state, 'done');
is($req->method, 'GET');
is($req->major_version, 1);
is($req->minor_version, 1);
is($req->url, '/foo/bar/baz.html?foo=13#23');
like($req->headers->content_type, qr/multipart\/form-data/);
is(ref $req->content->parts->[0], 'Curse::Content');
is(ref $req->content->parts->[1], 'Curse::Content');
is(ref $req->content->parts->[2], 'Curse::Content');
is($req->content->parts->[0]->cache->slurp, "hallo welt test123\n");

# Build minimal HTTP 1.1 request
$req = Curse::Message::Request->new;
$req->method('GET');
$req->url->parse('http://127.0.0.1/');
is($req->build, "GET / HTTP/1.1\x0d\x0aHost: 127.0.0.1\x0d\x0a\x0d\x0a");

# Build HTTP 1.1 start line and header
$req = Curse::Message::Request->new;
$req->method('GET');
$req->url->parse('http://127.0.0.1/foo/bar');
$req->headers->expect('100-continue');
is($req->build,
    "GET /foo/bar HTTP/1.1\x0d\x0a"
  . "Expect: 100-continue\x0d\x0a"
  . "Host: 127.0.0.1\x0d\x0a\x0d\x0a"
);

# Build full HTTP 1.1 request
$req = Curse::Message::Request->new;
$req->method('GET');
$req->url->parse('http://127.0.0.1/foo/bar');
$req->headers->expect('100-continue');
$req->body("Hello World!\n");
is($req->build,
    "GET /foo/bar HTTP/1.1\x0d\x0a"
  . "Expect: 100-continue\x0d\x0a"
  . "Host: 127.0.0.1\x0d\x0a"
  . "Content-Length: 13\x0d\x0a\x0d\x0a"
  . "Hello World!\n"
);

# Build full HTTP 1.1 proxy request
my $backup = $ENV{HTTP_PROXY};
$ENV{HTTP_PROXY} = 'http://foo:bar@127.0.0.1:8080';
$req = Curse::Message::Request->new;
$req->method('GET');
$req->url->parse('http://127.0.0.1/foo/bar');
$req->headers->expect('100-continue');
$req->body("Hello World!\n");
is($req->build,
    "GET http://127.0.0.1/foo/bar HTTP/1.1\x0d\x0a"
  . "Expect: 100-continue\x0d\x0a"
  . "Host: 127.0.0.1\x0d\x0a"
  . "Proxy-Authorization: Basic Zm9vOmJhcg==\x0d\x0a"
  . "Content-Length: 13\x0d\x0a\x0d\x0a"
  . "Hello World!\n"
);
$ENV{HTTP_PROXY} = $backup;

# Build HTTP 1.1 multipart request
$req = Curse::Message::Request->new;
$req->method('GET');
$req->url->parse('http://127.0.0.1/foo/bar');
$req->content(Curse::Content::MultiPart->new);
$req->headers->content_type('multipart/mixed; boundary=7am1X');
push @{$req->content->parts}, Curse::Content->new;
$req->content->parts->[-1]->cache->add_chunk('Hallo Welt lalalala!');
my $content = Curse::Content->new;
$content->cache->add_chunk("lala\nfoobar\nperl rocks\n");
$content->headers->content_type('text/plain');
push @{$req->content->parts}, $content;
is($req->build,
    "GET /foo/bar HTTP/1.1\x0d\x0a"
  . "Host: 127.0.0.1\x0d\x0a"
  . "Content-Length: 104\x0d\x0a"
  . "Content-Type: multipart/mixed; boundary=7am1X\x0d\x0a\x0d\x0a"
  . "\x0d\x0a--7am1X\x0d\x0a"
  . "Hallo Welt lalalala!"
  . "\x0d\x0a--7am1X\x0d\x0a"
  . "Content-Type: text/plain\x0d\x0a\x0d\x0a"
  . "lala\nfoobar\nperl rocks\n"
  . "\x0d\x0a--7am1X--"
);

# Build HTTP 1.1 chunked request
$req = Curse::Message::Request->new;
$req->method('GET');
$req->url->parse('http://127.0.0.1:8080/foo/bar');
$req->headers->transfer_encoding('chunked');
my $counter = 1;
$req->body(sub {
    my $self = shift;
    my $chunk = '';
    $chunk = "hello world!" if $counter == 1;
    $chunk = "hello world2!\n\n" if $counter == 2;
    $counter++;
    return $chunk;
});
is($req->build,
    "GET /foo/bar HTTP/1.1\x0d\x0a"
  . "Transfer-Encoding: chunked\x0d\x0a"
  . "Host: 127.0.0.1:8080\x0d\x0a\x0d\x0a"
  . "c\x0d\x0a"
  . "hello world!"
  . "\x0d\x0af\x0d\x0a"
  . "hello world2!\n\n"
  . "\x0d\x0a0\x0d\x0a"
);

# Build HTTP 1.1 chunked request with trailing headers
$req = Curse::Message::Request->new;
$req->method('GET');
$req->url->parse('http://127.0.0.1/foo/bar');
$req->headers->transfer_encoding('chunked');
$req->headers->trailer('X-Test; X-Test2');
$counter = 1;
$req->body(sub {
    my $self = shift;
    my $chunk = Curse::Headers->new;
    $chunk->header('X-Test', 'test');
    $chunk->header('X-Test2', '123');
    $chunk = "hello world!" if $counter == 1;
    $chunk = "hello world2!\n\n" if $counter == 2;
    $counter++;
    return $chunk;
});
is($req->build,
    "GET /foo/bar HTTP/1.1\x0d\x0a"
  . "Trailer: X-Test; X-Test2\x0d\x0a"
  . "Transfer-Encoding: chunked\x0d\x0a"
  . "Host: 127.0.0.1\x0d\x0a\x0d\x0a"
  . "c\x0d\x0a"
  . "hello world!"
  . "\x0d\x0af\x0d\x0a"
  . "hello world2!\n\n"
  . "\x0d\x0a0\x0d\x0a"
  . "X-Test: test\x0d\x0a"
  . "X-Test2: 123\x0d\x0a\x0d\x0a"
);

# Status code and message
my $res = Curse::Message::Response->new;
is($res->code, 200);
is($res->default_message, 'OK');
is($res->message, undef);
$res->message('Test');
is($res->message, 'Test');
$res->code(500);
is($res->code, 500);
is($res->message, 'Test');
is($res->default_message, 'Internal Server Error');
$res = Curse::Message::Response->new;
is($res->code(400)->default_message, 'Bad Request');

# Parse HTTP 1.1 response start line, no headers and body
$res = Curse::Message::Response->new;
$res->parse("HTTP/1.1 200 OK\x0d\x0a\x0d\x0a");
is($res->state, 'done');
is($res->code, 200);
is($res->message, 'OK');
is($res->major_version, 1);
is($res->minor_version, 1);

# Parse HTTP 0.9 response
$res = Curse::Message::Response->new;
$res->parse("HTT... this is just a document and valid HTTP 0.9\n\n");
is($res->state, 'done');
is($res->major_version, 0);
is($res->minor_version, 9);
is($res->body, "HTT... this is just a document and valid HTTP 0.9\n\n");

# Parse HTTP 1.0 response start line and headers but no body
$res = Curse::Message::Response->new;
$res->parse("HTTP/1.0 404 Damn it\x0d\x0a");
$res->parse("Content-Type: text/plain\x0d\x0a");
$res->parse("Content-Length: 0\x0d\x0a\x0d\x0a");
is($res->state, 'done');
is($res->code, 404);
is($res->message, 'Damn it');
is($res->major_version, 1);
is($res->minor_version, 0);
is($res->headers->content_type, 'text/plain');
is($res->headers->content_length, 0);

# Parse full HTTP 1.0 response
$res = Curse::Message::Response->new;
$res->parse("HTTP/1.0 500 Internal Server Error\x0d\x0a");
$res->parse("Content-Type: text/plain\x0d\x0a");
$res->parse("Content-Length: 27\x0d\x0a\x0d\x0a");
$res->parse("Hello World!\n1234\nlalalala\n");
is($res->state, 'done');
is($res->code, 500);
is($res->message, 'Internal Server Error');
is($res->major_version, 1);
is($res->minor_version, 0);
is($res->headers->content_type, 'text/plain');
is($res->headers->content_length, 27);

# Parse HTTP 1.1 chunked response
$res = Curse::Message::Response->new;
$res->parse("HTTP/1.1 500 Internal Server Error\x0d\x0a");
$res->parse("Content-Type: text/plain\x0d\x0a");
$res->parse("Transfer-Encoding: chunked\x0d\x0a\x0d\x0a");
$res->parse("4\x0d\x0a");
$res->parse("abcd\x0d\x0a");
$res->parse("9\x0d\x0a");
$res->parse("abcdefghi\x0d\x0a");
$res->parse("0\x0d\x0a");
is($res->state, 'done');
is($res->code, 500);
is($res->message, 'Internal Server Error');
is($res->major_version, 1);
is($res->minor_version, 1);
is($res->headers->content_type, 'text/plain');
is($res->content->body_length, 13);

# Parse HTTP 1.1 multipart response
$res = Curse::Message::Response->new;
$res->parse("HTTP/1.1 200 OK\x0d\x0a");
$res->parse("Content-Length: 814\x0d\x0a");
$res->parse('Content-Type: multipart/form-data; bo');
$res->parse("undary=----------0xKhTmLbOuNdArY\x0d\x0a\x0d\x0a");
$res->parse("\x0d\x0a------------0xKhTmLbOuNdArY\x0d\x0a");
$res->parse("Content-Disposition: form-data; name=\"text1\"\x0d\x0a");
$res->parse("\x0d\x0ahallo welt test123\n");
$res->parse("\x0d\x0a------------0xKhTmLbOuNdArY\x0d\x0a");
$res->parse("Content-Disposition: form-data; name=\"text2\"\x0d\x0a");
$res->parse("\x0d\x0a\x0d\x0a------------0xKhTmLbOuNdArY\x0d\x0a");
$res->parse('Content-Disposition: form-data; name="upload"; file');
$res->parse("name=\"hello.pl\"\x0d\x0a\x0d\x0a");
$res->parse("Content-Type: application/octet-stream\x0d\x0a\x0d\x0a");
$res->parse("#!/usr/bin/perl\n\n");
$res->parse("use strict;\n");
$res->parse("use warnings;\n\n");
$res->parse("print \"Hello World :)\\n\"\n");
$res->parse("\x0d\x0a------------0xKhTmLbOuNdArY--");
is($res->state, 'done');
is($res->code, 200);
is($res->message, 'OK');
is($res->major_version, 1);
is($res->minor_version, 1);
ok($res->headers->content_type =~ /multipart\/form-data/);
is(ref $res->content->parts->[0], 'Curse::Content');
is(ref $res->content->parts->[1], 'Curse::Content');
is(ref $res->content->parts->[2], 'Curse::Content');
is($res->content->parts->[0]->cache->slurp, "hallo welt test123\n");

# Build HTTP 1.1 response start line with minimal headers
$res = Curse::Message::Response->new;
$res->code(404);
$res->headers->date('Sun, 17 Aug 2008 16:27:35 GMT');
is($res->build,
    "HTTP/1.1 404 Not Found\x0d\x0a"
  . "Date: Sun, 17 Aug 2008 16:27:35 GMT\x0d\x0a\x0d\x0a"
);

# Build HTTP 1.1 response start line and header
$res = Curse::Message::Response->new;
$res->code(200);
$res->headers->connection('keep-alive');
$res->headers->date('Sun, 17 Aug 2008 16:27:35 GMT');
is($res->build,
    "HTTP/1.1 200 OK\x0d\x0a"
  . "Connection: keep-alive\x0d\x0a"
  . "Date: Sun, 17 Aug 2008 16:27:35 GMT\x0d\x0a\x0d\x0a"
);

# Build full HTTP 1.1 response
$res = Curse::Message::Response->new;
$res->code(200);
$res->headers->connection('keep-alive');
$res->headers->date('Sun, 17 Aug 2008 16:27:35 GMT');
$res->body("Hello World!\n");
is($res->build,
    "HTTP/1.1 200 OK\x0d\x0a"
  . "Connection: keep-alive\x0d\x0a"
  . "Date: Sun, 17 Aug 2008 16:27:35 GMT\x0d\x0a"
  . "Content-Length: 13\x0d\x0a\x0d\x0a"
  . "Hello World!\n"
);

# Build HTTP 0.9 response
$res = Curse::Message::Response->new;
$res->major_version(0);
$res->minor_version(9);
$res->body("this is just a document and valid HTTP 0.9\nlalala\n");
is($res->build, "this is just a document and valid HTTP 0.9\nlalala\n");

# Build HTTP 1.1 multipart response
$res = Curse::Message::Response->new;
$res->content(Curse::Content::MultiPart->new);
$res->code(200);
$res->headers->content_type('multipart/mixed; boundary=7am1X');
$res->headers->date('Sun, 17 Aug 2008 16:27:35 GMT');
push @{$res->content->parts}, Curse::Content->new(
    cache => Curse::Cache::File->new
);
$res->content->parts->[-1]->cache->add_chunk('Hallo Welt lalalalalala!');
$content = Curse::Content->new;
$content->cache->add_chunk("lala\nfoobar\nperl rocks\n");
$content->headers->content_type('text/plain');
push @{$res->content->parts}, $content;
is($res->build,
    "HTTP/1.1 200 OK\x0d\x0a"
  . "Date: Sun, 17 Aug 2008 16:27:35 GMT\x0d\x0a"
  . "Content-Length: 108\x0d\x0a"
  . "Content-Type: multipart/mixed; boundary=7am1X\x0d\x0a\x0d\x0a"
  . "\x0d\x0a--7am1X\x0d\x0a"
  . 'Hallo Welt lalalalalala!'
  . "\x0d\x0a--7am1X\x0d\x0a"
  . "Content-Type: text/plain\x0d\x0a\x0d\x0a"
  . "lala\nfoobar\nperl rocks\n"
  . "\x0d\x0a--7am1X--"
);

# Parse CGI like environment variables and a body
$req = Curse::Message::Request->new;
$req->parse({
    HTTP_CONTENT_LENGTH => 11,
    HTTP_EXPECT         => '100-continue',
    PATH_INFO           => '/test/index.cgi/foo/bar',
    QUERY_STRING        => 'lalala=23&bar=baz',
    REQUEST_METHOD      => 'POST',
    SCRIPT_NAME         => '/test/index.cgi',
    SERVER_NAME         => 'localhost:8080',
    SERVER_PROTOCOL     => 'HTTP/1.0'
});
$req->parse('Hello World');
is($req->state, 'done');
is($req->method, 'POST');
is($req->headers->expect, '100-continue');
is($req->url->path, '/test/index.cgi/foo/bar');
is($req->url->base->path, '/test/index.cgi');
is($req->url->host, 'localhost');
is($req->url->port, 8080);
is($req->url->query, 'lalala=23&bar=baz');
is($req->minor_version, '0');
is($req->major_version, '1');
is($req->body, 'Hello World');

# Parse response with cookie
$res = Curse::Message::Response->new;
$res->parse("HTTP/1.0 200 OK\x0d\x0a");
$res->parse("Content-Type: text/plain\x0d\x0a");
$res->parse("Content-Length: 27\x0d\x0a");
$res->parse("Set-Cookie: foo=bar; Version=1; Path=/test\x0d\x0a\x0d\x0a");
$res->parse("Hello World!\n1234\nlalalala\n");
is($res->state, 'done');
is($res->code, 200);
is($res->message, 'OK');
is($res->major_version, 1);
is($res->minor_version, 0);
is($res->headers->content_type, 'text/plain');
is($res->headers->content_length, 27);
is($res->headers->set_cookie, 'foo=bar; Version=1; Path=/test');
my @cookies = $res->cookies;
is($cookies[0]->name, 'foo');
is($cookies[0]->value, 'bar');
is($cookies[0]->version, 1);
is($cookies[0]->path, '/test');

# Build HTTP 1.1 response with 2 cookies
$res = Curse::Message::Response->new;
$res->code(404);
$res->headers->date('Sun, 17 Aug 2008 16:27:35 GMT');
$res->cookies(
    Curse::Cookie::Response->new({
        name  => 'foo',
        value => 'bar',
        path  => '/foobar'
    }),
    Curse::Cookie::Response->new({
        name  => 'bar',
        value => 'baz',
        path  => '/test/23'
    })
);
is($res->build,
    "HTTP/1.1 404 Not Found\x0d\x0a"
  . "Date: Sun, 17 Aug 2008 16:27:35 GMT\x0d\x0a"
  . "Set-Cookie: foo=bar; Version=1; Path=/foobar\x0d\x0a"
  . "Set-Cookie: bar=baz; Version=1; Path=/test/23\x0d\x0a\x0d\x0a"
);

# Build full HTTP 1.1 request with cookies
$req = Curse::Message::Request->new;
$req->method('GET');
$req->url->parse('http://127.0.0.1/foo/bar');
$req->headers->expect('100-continue');
$req->cookies(
    Curse::Cookie::Request->new({
        name  => 'foo',
        value => 'bar',
        path  => '/foobar'
    }),
    Curse::Cookie::Request->new({
        name  => 'bar',
        value => 'baz',
        path  => '/test/23'
    })
);
$req->body("Hello World!\n");
is($req->build,
    "GET /foo/bar HTTP/1.1\x0d\x0a"
  . "Expect: 100-continue\x0d\x0a"
  . "Host: 127.0.0.1\x0d\x0a"
  . "Content-Length: 13\x0d\x0a"
  . 'Cookie: $Version=1; foo=bar; $Path=/foobar; bar=baz; $Path=/test/23'
  . "\x0d\x0a\x0d\x0a"
  . "Hello World!\n"
);

# Parse full HTTP 1.0 request with cookies
$req = Curse::Message::Request->new;
$req->parse('GET /foo/bar/baz.html?fo');
$req->parse("o=13#23 HTTP/1.0\x0d\x0aContent");
$req->parse('-Type: text/');
$req->parse("plain\x0d\x0a");
$req->parse('Cookie: $Version=1; foo=bar; $Path=/foobar; bar=baz; $Path=/t');
$req->parse("est/23\x0d\x0a");
$req->parse("Content-Length: 27\x0d\x0a\x0d\x0aHell");
$req->parse("o World!\n1234\nlalalala\n");
is($req->state, 'done');
is($req->method, 'GET');
is($req->major_version, 1);
is($req->minor_version, 0);
is($req->url, '/foo/bar/baz.html?foo=13#23');
is($req->headers->content_type, 'text/plain');
is($req->headers->content_length, 27);
@cookies = $req->cookies;
is($cookies[0]->name, 'foo');
is($cookies[0]->value, 'bar');
is($cookies[0]->version, 1);
is($cookies[0]->path, '/foobar');
is($cookies[1]->name, 'bar');
is($cookies[1]->value, 'baz');
is($cookies[1]->version, 1);
is($cookies[1]->path, '/test/23');