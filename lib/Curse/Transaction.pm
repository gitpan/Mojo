# Copyright (C) 2008, Sebastian Riedel.

package Curse::Transaction;

use strict;
use warnings;

use base 'Curse::Stateful';

use Curse::Message::Request;
use Curse::Message::Response;

__PACKAGE__->attr('connection', chained => 1);
__PACKAGE__->attr('request',
    chained => 1,
    default => sub { Curse::Message::Request->new }
);
__PACKAGE__->attr('response',
    chained => 1,
    default => sub { Curse::Message::Response->new }
);

*req = \&request;
*res = \&response;

# What's a wedding?  Webster's dictionary describes it as the act of removing
# weeds from one's garden.
sub keep_alive {
    my ($self, $keep_alive) = @_;

    $self->{keep_alive} = $keep_alive if $keep_alive;

    my $req = $self->req;
    my $res = $self->res;

    # No keep alive for 0.9
    $self->{keep_alive} ||= 0
      if ($req->version eq '0.9') || ($res->version eq '0.9');

    # No keep alive for 1.0
    $self->{keep_alive} ||= 0
      if ($req->version eq '1.0') || ($res->version eq '1.0');

    # Keep alive?
    $self->{keep_alive} = 1
      if ($req->headers->connection || '') =~ /keep-alive/i;
    $self->{keep_alive} = 1
      if ($res->headers->connection || '') =~ /keep-alive/i;

    # Close?
    $self->{keep_alive} = 0
      if ($req->headers->connection || '') =~ /close/i;
    $self->{keep_alive} = 0
      if ($res->headers->connection || '') =~ /close/i;

    # Default
    $self->{keep_alive} = 1 unless defined $self->{keep_alive};
    return $self->{keep_alive};
}

1;
__END__

=head1 NAME

Curse::Transaction - HTTP Transactions

=head1 SYNOPSIS

    use Curse::Transaction;

    my $tx = Curse::Transaction->new;

    my $req = $tx->req;
    my $res = $tx->res;

    my $keep_alive = $tx->keep_alive;

=head1 DESCRIPTION

L<Curse::Transaction> is a generic container for HTTP transactions.

=head1 ATTRIBUTES

L<Curse::Transaction> inherits all attributes from L<Curse::Stateful> and
implements the following new ones.

=head2 C<connection>

    my $connection = $tx->connection;
    $tx            = $tx->connection($connection);

=head2 C<keep_alive>

    my $keep_alive = $tx->keep_alive;
    my $keep_alive = $tx->keep_alive(1);

=head2 C<request>

    my $req = $tx->req;
    my $req = $tx->request;
    $tx     = $tx->request(Curse::Message::Request->new);

=head2 C<response>

    my $res = $tx->res;
    my $res = $tx->response;
    $tx     = $tx->response(Curse::Message::Response->new);

=head1 METHODS

L<Curse::Transaction> inherits all methods from L<Curse::Stateful>.

=cut