# Copyright (C) 2008-2009, Sebastian Riedel.

package Mojo::Cookie::Response;

use strict;
use warnings;

use base 'Mojo::Cookie';

use Mojo::ByteStream 'b';

# Regex
my $FIELD_RE = qr/
    (
      Comment
    | Domain
    | expires
    | HttpOnly   # IE6 FF3 Opera 9.5
    | Max-Age
    | Path
    | Port
    | Secure
    | Version
    )
/xmsi;
my $FLAG_RE = qr/(?:Secure|HttpOnly)/i;

# Remember the time he ate my goldfish?
# And you lied and said I never had goldfish.
# Then why did I have the bowl Bart? Why did I have the bowl?
sub parse {
    my ($self, $string) = @_;
    my @cookies;

    for my $knot ($self->_tokenize($string)) {
        for my $i (0 .. $#{$knot}) {
            my ($name, $value) = @{$knot->[$i]};

            # Value might be quoted
            $value = b($value)->unquote->to_string if $value;

            # This will only run once
            if (not $i) {
                push @cookies, Mojo::Cookie::Response->new;
                $cookies[-1]->name($name);
                $cookies[-1]->value($value);
                next;
            }

            # Field
            if (my @match = $name =~ /$FIELD_RE/) {

                # Underscore
                (my $id = lc $match[0]) =~ tr/-/_/;

                # Flag?
                $cookies[-1]->$id($id =~ /$FLAG_RE/ ? 1 : $value);
            }
        }
    }

    return \@cookies;
}

sub to_string {
    my $self = shift;

    return '' unless $self->name;

    my $cookie = sprintf "%s=%s; Version=%d",
      $self->name, $self->value, ($self->version || 1);

    if (my $domain = $self->domain) { $cookie .= "; Domain=$domain" }
    if (my $path   = $self->path)   { $cookie .= "; Path=$path" }
    if (defined(my $max_age = $self->max_age)) {
        $cookie .= "; Max-Age=$max_age";
    }
    if (defined(my $expires = $self->expires)) {
        $cookie .= "; expires=$expires";
    }
    if (my $port     = $self->port)     { $cookie .= qq/; Port="$port"/ }
    if (my $secure   = $self->secure)   { $cookie .= "; Secure" }
    if (my $httponly = $self->httponly) { $cookie .= "; HttpOnly" }
    if (my $comment  = $self->comment)  { $cookie .= "; Comment=$comment" }

    return $cookie;
}

1;
__END__

=head1 NAME

Mojo::Cookie::Response - Response Cookies

=head1 SYNOPSIS

    use Mojo::Cookie::Response;

    my $cookie = Mojo::Cookie::Response->new;
    $cookie->name('foo');
    $cookie->value('bar');

    print "$cookie";

=head1 DESCRIPTION

L<Mojo::Cookie::Response> is a generic container for HTTP response cookies.

=head1 ATTRIBUTES

L<Mojo::Cookie::Response> inherits all attributes from L<Mojo::Cookie>.

=head1 METHODS

L<Mojo::Cookie::Response> inherits all methods from L<Mojo::Cookie> and
implements the following new ones.

=head2 C<parse>

    my @cookies = $cookie->parse('f=b; Version=1; Path=/');

=head2 C<to_string>

    my $string = $cookie->to_string;

=cut
