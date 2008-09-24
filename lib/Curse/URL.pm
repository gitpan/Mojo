# Copyright (C) 2008, Sebastian Riedel.

package Curse::URL;

use strict;
use warnings;

use base 'Nevermore';
use overload '""' => sub { shift->as_string }, fallback => 1;

use Curse::ByteStream;
use Curse::Parameters;
use Curse::Path;

__PACKAGE__->attr([qw/fragment host password port scheme user/],
    chained => 1
);
__PACKAGE__->attr('base', chained => 1, default => sub { Curse::URL->new });
__PACKAGE__->attr('path', chained => 1, default => sub { Curse::Path->new });
__PACKAGE__->attr('query',
    chained => 1,
    default => sub { Curse::Parameters->new }
);

sub new {
    my $self = shift->SUPER::new();
    $self->parse(@_);
    return $self;
}

sub as_absolute {
    my $self = shift;
    my $base = shift || $self->base->clone;

    my $abs = $self->clone;

    # Add scheme and authority
    $abs->scheme($base->scheme);
    $abs->authority($base->authority);

    $abs->base($base->clone);
    my $path = $base->path->clone;

    # Characters after the right-most '/' need to go
    pop @{$path->parts} unless $path->trailing_slash;

    $path->append($_) for @{$abs->path->parts};
    $path->leading_slash(1);
    $path->trailing_slash($abs->path->trailing_slash);
    $abs->path($path);
    
    return $abs;
}

sub as_relative {
    my $self = shift;
    my $base = shift || $self->base->clone;

    my $rel = $self->clone;

    # Different locations
    return $rel
      unless lc $base->scheme eq lc $rel->scheme
      && $base->authority eq $rel->authority;

    # Remove scheme and authority
    $rel->scheme('');
    $rel->authority('');

    $rel->base($base->clone);
    my $splice = @{$base->path->parts};

   # Characters after the right-most '/' need to go
    $splice -= 1 unless $base->path->trailing_slash;

    my $path = $rel->path->clone;
    splice @{$path->parts}, 0, $splice if $splice;

    $rel->path($path);
    $rel->path->leading_slash(0) if $splice;
    
    return $rel;
}

# Dad, what's a Muppet?
# Well, it's not quite a mop, not quite a puppet, but man... *laughs*
# So, to answer you question, I don't know.
sub as_string {
    my $self = shift;

    my $scheme    = Curse::ByteStream->new($self->scheme)->url_escape;
    my $authority = $self->authority;
    my $path      = $self->path;
    my $query     = $self->query;
    my $fragment  = Curse::ByteStream->new($self->fragment)->url_escape;

    # Format
    my $url = '';

    $url .= lc "$scheme://" if $scheme && $authority;
    $url .= "$authority$path";
    $url .= "?$query" if @{$query->params};
    $url .= "#$fragment" if $fragment->length;

    return $url;
}

sub authority {
    my ($self, $authority) = @_;

    # Set
    if (defined $authority) {
        my $userinfo = '';
        my $host     = $authority;

        # Userinfo
        if ($authority =~ /^([^\@]*)\@(.*)$/) {
            $userinfo = $1;
            $host     = $2;
        }

        # Port
        my $port = '';
        if ($host =~ /^([^\:]*)\:(.*)$/) {
            $host = $1;
            $port = $2;
        }

        $self->userinfo($userinfo);
        $self->host(Curse::ByteStream->new($host)->url_unescape->as_string);
        $self->port(Curse::ByteStream->new($port)->url_unescape->as_string);

        return $self;
    }

    # Get
    my $userinfo = $self->userinfo;
    my $host     = Curse::ByteStream->new($self->host)->url_escape;
    my $port     = $self->port;

    # Format
    $authority .= "$userinfo\@" if $userinfo;
    $authority .= lc($host || '');
    $authority .= ":$port" if $port;

    return $authority;
}

sub clone {
    my $self = shift;

    my $clone = Curse::URL->new;
    $clone->scheme($self->scheme);
    $clone->authority($self->authority);
    $clone->path($self->path->clone);
    $clone->query($self->query->clone);
    $clone->fragment($self->fragment);

    return $clone;
}

sub is_absolute {
    my $self = shift;
    return 1 if $self->scheme && $self->authority;
    return 0;
}

sub parse {
    my ($self, $url) = @_;

    # Shortcut
    return $self unless $url;

    # Official regex
    my ($scheme, $authority, $path, $query, $fragment)
      = $url
      =~ m|(?:([^:/?#]+):)?(?://([^/?#]*))?([^?#]*)(?:\?([^#]*))?(?:#(.*))?|;

    $self->scheme(Curse::ByteStream->new($scheme)->url_unescape->as_string);
    $self->authority($authority);
    $self->path->parse($path);
    $self->query->parse($query);
    $self->fragment(
        Curse::ByteStream->new($fragment)->url_unescape->as_string
    );

    return $self;
}

sub userinfo {
    my ($self, $userinfo) = @_;

    # Set
    if (defined $userinfo) {
        my $user     = $userinfo;
        my $password = '';

        if ($user =~ /^([^\:]*)\:(.*)$/) {
            $user     = $1;
            $password = $2;
        }

        $self->user(Curse::ByteStream->new($user)->url_unescape->as_string);
        $self->password(
            Curse::ByteStream->new($password)->url_unescape->as_string
        );

        return $self;
    }

    # Get
    my $user     = Curse::ByteStream->new($self->user)->url_escape;
    my $password = Curse::ByteStream->new($self->password)->url_escape;

    # Format
    return $user ? "$user:$password" : undef;
}

1;
__END__

=head1 NAME

Curse::URL - Uniform Resource Locators

=head1 SYNOPSIS

    use Curse::URL;

    # Parse
    my $url = Curse::URL->new(
        'http://sri:foobar@kraih.com:3000/foo/bar?foo=bar#23'
    );
    print $url->scheme;
    print $url->userinfo;
    print $url->user;
    print $url->password;
    print $url->host;
    print $url->port;
    print $url->path;
    print $url->query;
    print $url->fragment;

    # Build
    my $url = Curse::URL->new;
    $url->scheme('http');
    $url->userinfo('sri:foobar');
    $url->host('kraih.com');
    $url->port(3000);
    $url->path->parts(qw/foo bar/);
    $url->query->params(foo => 'bar');
    $url->fragment(23);
    print "$url";

=head1 DESCRIPTION

L<Curse::URL> implements a subset of RFC 3986 for Uniform Resource Locators.

=head1 ATTRIBUTES

=head2 C<authority>

    my $authority = $url->autority;
    $url          = $url->authority('root:pass%3Bw0rd@localhost:8080');

=head2 C<base>

    my $base = $url->base;
    $url     = $url->base(Curse::URL->new);

=head2 C<fragment>

    my $fragment = $url->fragment;
    $url         = $url->fragment('foo');

=head2 C<host>

    my $host = $url->host;
    $url     = $url->host('127.0.0.1');

=head2 C<password>

    my $password = $url->password;
    $url         = $url->password('pass;w0rd');

=head2 C<path>

    my $path = $url->path;
    $url     = $url->path(Curse::Path->new);

=head2 C<port>

    my $port = $url->port;
    $url     = $url->port(8080);

=head2 C<query>

    my $query = $url->query;
    $url      = $url->query(Curse::Parameters->new);

=head2 C<scheme>

    my $scheme = $url->scheme;
    $url       = $url->scheme('http');

=head2 C<user>

    my $user = $url->user;
    $url     = $url->userinfo('root');

=head2 C<userinfo>

    my $userinfo = $url->userinfo;
    $url         = $url->userinfo('root:pass%3Bw0rd');

=head1 METHODS

L<Curse::URL> inherits all methods from L<Nevermore> and implements the
following new ones.

=head2 C<new>

    my $url = Curse::URL->new;
    my $url = Curse::URL->new('http://127.0.0.1:3000/foo?f=b&baz=2#foo');

=head2 C<as_absolute>

    my $abs = $url->as_absolute;
    my $abs = $url->as_absolute(Curse::URL->new('http://kraih.com/foo'));

=head2 C<as_relative>

    my $rel = $url->as_relative;
    my $rel = $url->as_relative(Curse::URL->new('http://kraih.com/foo'));

=head2 C<as_string>

    my $string = $url->as_string;

=head2 C<is_absolute>

    my $is_absolute = $url->is_absolute;

=head2 C<parse>

    $url = $url->parse('http://127.0.0.1:3000/foo/bar?fo=o&baz=23#foo');

=cut