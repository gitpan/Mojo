# Copyright (C) 2008, Sebastian Riedel.

package Curse::Path;

use strict;
use warnings;

use base 'Nevermore';
use overload '""' => sub { shift->as_string }, fallback => 1;

use Curse::ByteStream;

__PACKAGE__->attr([qw/leading_slash trailing_slash/],
    chained => 1,
    default => sub { 0 }
);
__PACKAGE__->attr('parts', chained => 1, default => sub { [] });

sub new {
    my $self = shift->SUPER::new();
    $self->parse(@_);
    return $self;
}

sub append {
    my $self = shift;
    push @{$self->parts}, @_;
    return $self;
}

# Homer, the plant called.
# They said if you don't show up tomorrow don't bother showing up on Monday.
# Woo-hoo. Four-day weekend.
sub as_string {
    my $self = shift;

    # Escape
    my @path;
    for my $part (@{$self->parts}) {
        push @path, Curse::ByteStream->new($part)->url_escape->as_string;
    }

    # Format
    my $path = join '/', @path;
    $path = "/$path" if $self->leading_slash;
    $path = "$path/" if @path && $self->trailing_slash;

    return $path;
}

sub clone {
    my $self  = shift;
    my $clone = Curse::Path->new;

    $clone->parts([@{$self->parts}]);
    $clone->leading_slash($self->leading_slash);
    $clone->trailing_slash($self->trailing_slash);

    return $clone;
}

sub parse {
    my ($self, $path) = @_;
    $path ||= '';

    # Meta
    $self->leading_slash(1)  if $path =~ /^\//;
    $self->trailing_slash(1) if $path =~ /\/$/;

    # Parse
    my @parts;
    for my $part (split '/', $path) {

        # Garbage
        next unless $part;

        # Unescape
        push @parts, Curse::ByteStream->new($part)->url_unescape->as_string;
    }

    $self->parts(\@parts);

    return $self;
}

sub resolve {
    my $self = shift;

    # Resolve path
    my @path;
    for my $part (@{$self->parts}) {

        # ".."
        if ($part eq '..') {

            # Leading '..' can't be resolved
            unless (@path && $path[-1] ne '..') { push @path, '..' }

            # Uplevel
            else { pop @path }
            next;
        }

        # "."
        next if $part eq '.';

        # Part
        push @path, $part;
    }
    $self->parts(\@path);

    return $self;
}

1;
__END__

=head1 NAME

Curse::Path - URL Path

=head1 SYNOPSIS

    use Curse::Path;

    my $path = Curse::Path->new('/foo/bar%3B/baz.html');
    print "$path";

=head1 DESCRIPTION

L<Curse::Path> is a generic container for URL paths.

=head1 ATTRIBUTES

=head2 C<leading_slash>

    my $leading_slash = $path->leading_slash;
    $path             = $path->leading_slash(1);

=head2 C<parts>

    my $parts = $path->parts;
    $path     = $path->parts(qw/foo bar baz/);

=head2 C<trailing_slash>

    my $trailing_slash = $path->trailing_slash;
    $path              = $path->trailing_slash(1);

=head1 METHODS

L<Curse::Path> inherits all methods from L<Nevermore> and implements the
following new ones.

=head2 C<new>

    my $path = Curse::Path->new;
    my $path = Curse::Path->new('/foo/bar%3B/baz.html');

=head2 C<append>

    $path = $path->append(qw/foo bar/);

=head2 C<as_string>

    my $string = $path->as_string;

=head2 C<clone>

    my $clone = $path->clone;

=head2 C<parse>

    $path = $path->parse('/foo/bar%3B/baz.html');

=head2 C<resolve>

    $path = $path->resolve;

=cut