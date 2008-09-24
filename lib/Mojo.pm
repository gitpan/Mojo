# Copyright (C) 2008, Sebastian Riedel.

package Mojo;

use strict;
use warnings;

use base 'Nevermore';

# No imports to make subclassing a bit easier
require Carp;
require Cwd;
require File::Spec;

# Oh, so they have internet on computers now!
our $VERSION = '0.2';

sub handler { Carp::croak('Method "handler" not implemented in subclass') }

sub home {
    my ($self, $home) = @_;

    # Set
    if ($home) {
        $self->{home} = $home;
        return $self;
    }

    # Default to MOJO_HOME environment variable
    $self->{home} ||= $ENV{MOJO_HOME};

    # Get
    return $self->{home} if $self->{home};

    # Try to detect a home directory
    my $class = ref $self;
    my $file = "$class.pm";
    $file =~ s/::/\//g;

    if (my $entry = $INC{$file}) {
        my $path = $entry;
        $path =~ s/$file$//;
        my @home = File::Spec->splitdir($path);

        # Remove "lib" and "blib"
        pop @home while $home[-1] =~ /^b?lib$/ || $home[-1] eq '';

        # Check for "mojo.pl"
        return Cwd::realpath(File::Spec->catdir(@home))
          if -f File::Spec->catfile(@home, 'mojo.pl')
          || -f File::Spec->catfile(@home, qw/script mojo.pl/);
    }

    return undef;
}

1;
__END__

=head1 NAME

Mojo - Yeah, Baby, Yeah!

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

=head1 ATTRIBUTES

=head2 C<home>

    my $home = $mojo->home;
    my $mojo = $mojo->home('/home/sri/mojoapp');

=head1 METHODS

L<Mojo> inherits all methods from L<Nevermore> and implements the following
new ones.

=head2 C<handler>

    $tx = $mojo->handler($tx);

=head1 SUPPORT

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
