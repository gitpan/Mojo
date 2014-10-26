# Copyright (C) 2008-2009, Sebastian Riedel.

package MojoX::Dispatcher::Routes::Controller;

use strict;
use warnings;

use base 'Mojo::Base';

__PACKAGE__->attr('ctx', weak => 1);

# If we don't go back there and make that event happen,
# the entire universe will be destroyed...
# And as an environmentalist, I'm against that.

1;
__END__

=head1 NAME

MojoX::Dispatcher::Routes::Controller - Controller Base Class

=head1 SYNOPSIS

    use base 'MojoX::Dispatcher::Routes::Controller';

=head1 DESCRIPTION

L<MojoX::Dispatcher::Routes::Controller> is a controller base class.

=head1 ATTRIBUTES

L<MojoX::Dispatcher::Routes::Controller> implements the following attributes.

=head2 C<ctx>

    my $c = $controller->ctx;

=head1 METHODS

L<MojoX::Dispatcher::Routes::Controller> inherits all methods from
L<Mojo::Base>.

=cut
