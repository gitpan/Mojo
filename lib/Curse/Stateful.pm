# Copyright (C) 2008, Sebastian Riedel.

package Curse::Stateful;

use strict;
use warnings;

use base 'Nevermore';

# Don't kid yourself, Jimmy. If a cow ever got the chance,
# he'd eat you and everyone you care about!
__PACKAGE__->attr('state', chained => 1, default => sub { 'start' });

sub error {
    my ($self, $message) = @_;
    return $self->{error} unless $message;
    $self->state('error');
    return $self->{error} = $message;
}

sub has_error { return defined shift->{error} }

sub is_state {
    my ($self, @states) = @_;
    for my $state (@states) { return 1 if $self->state eq $state }
    return 0;
}

1;
__END__

=head1 NAME

Curse::Stateful - State Keeping Base Class

=head1 SYNOPSIS

    use base 'Curse::Stateful';

=head1 DESCRIPTION

L<Curse::Stateful> is a generic base class for state keeping instances.

=head1 ATTRIBUTES

=head2 C<error>

    my $error = $stateful->error;
    $stateful = $stateful->error('Parser error: test 123');

=head2 C<state>

   my $state = $stateful->state;
   $stateful = $stateful->state('writing');

=head1 METHODS

L<Curse::Stateful> inherits all methods from L<Nevermore> and implements the
following new ones.

=head2 C<has_error>

    my $has_error = $stateful->has_error;

=head2 C<is_state>

    my $is_state = $stateful->is_state('writing');
    my $is_state = $stateful->is_state(qw/error reading writing/);

=cut