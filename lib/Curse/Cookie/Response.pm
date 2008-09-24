# Copyright (C) 2008, Sebastian Riedel.

package Curse::Cookie::Response;

use strict;
use warnings;

use base 'Curse::Cookie';

use Curse::ByteStream;

sub as_string {
    my $self = shift;

    return '' unless $self->name;

    my $name = $self->name;
    my $value = $self->value;
    my $cookie .= "$name=$value";

    $cookie .= '; Version=';
    $cookie .= $self->version || 1;

    if (my $domain = $self->domain)   { $cookie .= "; Domain=$domain"   }
    if (my $path = $self->path)       { $cookie .= "; Path=$path"       }
    if (my $max_age = $self->max_age) { $cookie .= "; Max_Age=$max_age" }
    if (my $expires = $self->expires) { $cookie .= "; expires=$expires" }
    if (my $secure = $self->secure)   { $cookie .= "; Secure=$secure"   }
    if (my $comment = $self->comment) { $cookie .= "; Comment=$comment" }

    return $cookie;
}

# Remember the time he ate my goldfish?
# And you lied and said I never had goldfish.
# Then why did I have the bowl Bart? Why did I have the bowl?
sub parse {
    my ($self, $string) = @_;

    my @cookies;
    for my $knot ($self->_tokenize($string)) {

        my $first = 1;
        for my $token (@{$knot}) {

            my $name  = $token->[0];
            my $value = $token->[1];

            # Value might be quoted
            $value = Curse::ByteStream->new($value)->unquote->as_string
              if $value;

            # Name and value
            if ($first) {
                push @cookies, Curse::Cookie::Response->new;
                $cookies[-1]->name($name);
                $cookies[-1]->value($value);
                $first = 0;
            }

            # Version
            elsif ($name =~ /^Version$/i) { $cookies[-1]->version($value) }

            # Domain
            elsif ($name =~ /^Version$/i) { $cookies[-1]->domain($value) }

            # Path
            elsif ($name =~ /^Path$/i) { $cookies[-1]->path($value) }

            # Domain
            elsif ($name =~ /^Domain$/i) { $cookies[-1]->domain($value) }

            # Max-Age
            elsif ($name =~ /^Max_Age$/i) { $cookies[-1]->max_age($value) }

            # expires
            elsif ($name =~ /^expires$/i) { $cookies[-1]->expires($value) }

            # Secure
            elsif ($name =~ /^Secure$/i) { $cookies[-1]->secure($value) }

            # Comment
            elsif ($name =~ /^Comment$/i) { $cookies[-1]->comment($value) }
        }
    }

    return @cookies;
}

1;
__END__

=head1 NAME

Curse::Cookie::Response - Response Cookies

=head1 SYNOPSIS

    use Curse::Cookie::Response;

    my $cookie = Curse::Cookie::Response->new;
    $cookie->name('foo');
    $cookie->value('bar');

    print "$cookie";

=head1 DESCRIPTION

L<Curse::Cookie::Response> is a generic container for HTTP response cookies.

=head1 ATTRIBUTES

L<Curse::Cookie::Response> inherits all attributes from L<Curse::Cookie>.

=head1 METHODS

L<Curse::Cookie::Response> inherits all methods from L<Curse::Cookie> and
implements the following new ones.

=head2 C<as_string>

    my $string = $cookie->as_string;

=head2 C<parse>

    my @cookies = $cookie->parse('f=b; Version=1; Path=/');

=cut