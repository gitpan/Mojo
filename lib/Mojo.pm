# Copyright (C) 2008, Sebastian Riedel.

package Mojo;

use strict;
use warnings;

use base 'Mojo::Base';

# No imports to make subclassing a bit easier
require Carp;

# Oh, so they have internet on computers now!
our $VERSION = '0.5';

sub handler { Carp::croak('Method "handler" not implemented in subclass') }

1;
__END__

=head1 NAME

Mojo - Web Framework

=head1 SYNOPSIS

    use base 'Mojo';

    sub handler {
        my ($self, $tx) = @_;
        return $tx;
    }

=head1 DESCRIPTION

L<Mojo> is a framework for web framework developers.

*IMPORTANT!* This is beta software, don't use it for anything serious,
it might eat your puppy or cause the apocalypse. (You've been warned...)

=head1 METHODS

L<Mojo> inherits all methods from L<Mojo::Base> and implements the following
new ones.

=head2 C<handler>

    $tx = $mojo->handler($tx);

=head1 SUPPORT

=head2 Web

    http://getmojo.kraih.com

=head2 IRC

    #mojo on irc.freenode.org

=head2 Mailing-Lists

    http://lists.kraih.com/listinfo/mojo
    http://lists.kraih.com/listinfo/mojo-dev

=head1 AUTHOR

Sebastian Riedel, C<sri@cpan.org>.

=head1 CREDITS

Many parts of Mojo are based upon the work of others, thank you.
(In alphabetical order)

Andy Grundman
Audrey Tang
Christian Hansen
Gisle Aas
Jesse Vincent
Marcus Ramberg

And thanks to everyone else i might have forgotten. (Please send me a mail)

=head1 COPYRIGHT

Copyright (C) 2008, Sebastian Riedel.

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl 5.10.

=cut
