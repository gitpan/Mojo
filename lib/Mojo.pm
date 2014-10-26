# Copyright (C) 2008-2009, Sebastian Riedel.

package Mojo;

use strict;
use warnings;

use base 'Mojo::Base';

# No imports to make subclassing a bit easier
require Carp;

use Mojo::Home;
use Mojo::Log;
use Mojo::Transaction;

__PACKAGE__->attr('home', default => sub { Mojo::Home->new });
__PACKAGE__->attr('log',  default => sub { Mojo::Log->new });

# Oh, so they have internet on computers now!
our $VERSION = '0.991238';

sub new {
    my $self = shift->SUPER::new(@_);

    # Home
    $self->home->detect(ref $self);

    # Log directory
    $self->log->path($self->home->rel_file('log/mojo.log'))
      if -w $self->home->rel_file('log');

    return $self;
}

sub build_tx {
    my $tx = Mojo::Transaction->new;
    $tx->res->headers->header('X-Powered-By' => 'Mojo (Perl)');
    return $tx;
}

sub handler { Carp::croak('Method "handler" not implemented in subclass') }

1;
__END__

=head1 NAME

Mojo - The Web In A Box!

=head1 SYNOPSIS

    use base 'Mojo';

    sub handler {
        my ($self, $tx) = @_;

        # Hello world!
        $tx->res->code(200);
        $tx->res->headers->content_type('text/plain');
        $tx->res->body('Congratulations, your Mojo is working!');
    }

=head1 DESCRIPTION

L<Mojo> is a collection of libraries and example web frameworks for web
framework developers.

If you are searching for a higher level MVC web framework you should take a
look at L<Mojolicious>.

Don't be scared by the amount of different modules in the distribution, they
are all very loosely coupled.
You can just pick the ones you like and ignore the rest, there is no
tradeoff.

For userfriendly documentation see L<Mojo::Manual>.

=head1 ATTRIBUTES

L<Mojo> implements the following attributes.

=head2 C<home>

    my $home = $mojo->home;
    $mojo    = $mojo->home(Mojo::Home->new);

=head2 C<log>

    my $log = $mojo->log;
    $mojo   = $mojo->log(Mojo::Log->new);

=head1 METHODS

L<Mojo> inherits all methods from L<Mojo::Base> and implements the following
new ones.

=head2 C<new>

    my $mojo = Mojo->new;

=head2 C<build_tx>

    my $tx = $mojo->build_tx;

=head2 C<handler>

    $tx = $mojo->handler($tx);

=head1 SUPPORT

=head2 Web

    http://mojolicious.org

=head2 IRC

    #mojo on irc.perl.org

=head2 Mailing-List

    http://lists.kraih.com/listinfo/mojo

=head1 DEVELOPMENT

=head2 Repository

    http://github.com/kraih/mojo/commits/master

=head1 SEE ALSO

L<Mojolicious>

=head1 AUTHOR

Sebastian Riedel, C<sri@cpan.org>.

=head1 CREDITS

In alphabetical order:

Anatoly Sharifulin

Andreas Koenig

Andy Grundman

Aristotle Pagaltzis

Ask Bjoern Hansen

Audrey Tang

Breno G. de Oliveira

Burak Gursoy

Ch Lamprecht

Christian Hansen

Gisle Aas

Graham Barr

James Duncan

Jesse Vincent

Lars Balker Rasmussen

Leon Brocard

Maik Fischer

Marcus Ramberg

Mark Stosberg

Maxym Komar

Pascal Gaudette

Pedro Melo

Randal Schwartz

Robert Hicks

Shu Cho

Uwe Voelker

vti

Yuki Kimoto

And thanks to everyone else i might have forgotten. (Please send me a mail)

=head1 COPYRIGHT

Copyright (C) 2008-2009, Sebastian Riedel.

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl 5.10.

=cut
