# Copyright (C) 2008, Sebastian Riedel.

package Curse::Cookie::Request;

use strict;
use warnings;

use base 'Curse::Cookie';

use Curse::ByteStream;

sub as_string {
    my $self = shift;

    return '' unless $self->name;

    my $name   = $self->name;
    my $value  = $self->value;
    my $cookie = "$name=$value";

    if (my $path = $self->path) { $cookie .= "; \$Path=$path" }

    return $cookie;
}

sub as_string_with_prefix {
    my $self = shift;
    my $prefix = $self->prefix;
    my $cookie = $self->as_string;
    return "$prefix; $cookie";
}

# Lisa, would you like a donut?
# No thanks. Do you have any fruit?
# This has purple in it. Purple is a fruit.
sub parse {
    my ($self, $string) = @_;

    my @cookies;
    my $version = 1;

    for my $knot ($self->_tokenize($string)) {
        for my $token (@{$knot}) {

            my $name  = $token->[0];
            my $value = $token->[1];

            # Value might be quoted
            $value = Curse::ByteStream->new($value)->unquote if $value;

            # Path
            if ($name =~ /^\$Path$/i) { $cookies[-1]->path($value) }

            # Version
            elsif ($name =~ /^\$Version$/i) { $version = $value }

            # Name and value
            else {
                push @cookies, Curse::Cookie::Request->new;
                $cookies[-1]->name($name);
                $cookies[-1]->value(Curse::ByteStream->new($value)->unquote);
                $cookies[-1]->version($version);
            }
        }
    }

    return @cookies;
}

sub prefix {
    my $self    = shift;
    my $version = $self->version || 1;
    return "\$Version=$version";
}

1;
__END__

=head1 NAME

Curse::Cookie::Request - Request Cookies

=head1 SYNOPSIS

    use Curse::Cookie::Request;

    my $cookie = Curse::Cookie::Request->new;
    $cookie->name('foo');
    $cookie->value('bar');

    print "$cookie";

=head1 DESCRIPTION

L<Curse::Cookie::Request> is a generic container for HTTP request cookies.

=head1 ATTRIBUTES

L<Curse::Cookie::Request> inherits all attributes from L<Curse::Cookie>.

=head1 METHODS

L<Curse::Cookie::Request> inherits all methods from L<Curse::Cookie> and
implements the following new ones.

=head2 C<as_string>

    my $string = $cookie->as_string;

=head2 C<as_string_with_prefix>

    my $string = $cookie->as_string_with_prefix;

=head2 C<parse>

    my @cookies = $cookie->parse('$Version=1; f=b; $Path=/');

=head2 C<prefix>

    my $prefix = $cookie->prefix;

=cut