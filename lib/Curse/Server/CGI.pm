# Copyright (C) 2008, Sebastian Riedel.

package Curse::Server::CGI;

use strict;
use warnings;

use base 'Curse::Server';

use Curse::Transaction;
use IO::Select;

__PACKAGE__->attr('non_parsed_header', chained => 1, default => sub { 0 });

# Lisa, you're a Buddhist, so you believe in reincarnation.
# Eventually, Snowball will be reborn as a higher lifeform... like a snowman.
sub run {
    my $self = shift;

    my $tx  = Curse::Transaction->new;
    my $req = $tx->req;

    # Environment
    $req->parse(\%ENV);

    # Request body
    $req->state('body');
    my $select = IO::Select->new(\*STDIN);
    while (!$req->is_state(qw/done error/)) {
        last unless $select->can_read(0);
        my $read = STDIN->sysread(my $buffer, 4096, 0);
        $req->parse($buffer);
    }

    # Handle
    $self->handler->($self, $tx);

    my $res = $tx->res;

    # Response start line
    my $offset = 0;
    if ($self->non_parsed_header) {
        while ($offset < $res->start_line_length) {
            my $chunk = $res->get_start_line_chunk($offset);
            my $written = STDOUT->syswrite($chunk);
            $offset += $written;
        }
    }

    # Response headers
    $res->headers->header('Status', $res->code . ' ' . $res->message)
      unless $self->non_parsed_header;
    $offset = 0;
    while ($offset < $res->header_length) {
        my $written = STDOUT->syswrite($res->get_header_chunk($offset));
        $offset += $written;
    }

    # Response body
    $offset = 0;
    while (1) {
        my $chunk = $res->get_body_chunk($offset);

        # No content yet, try again
        unless (defined $chunk) {
            sleep 1;
            next;
        }

        # End of content
        last unless length $chunk;

        # Content
        my $written = STDOUT->syswrite($chunk);
        $offset += $written;
    }

    return $res->code;
}

1;

__END__

=head1 NAME

Curse::Server::CGI - CGI Server

=head1 SYNOPSIS

    use Curse::Server::CGI;
    my $cgi = Curse::Server::CGI->new;
    $cgi->run;

=head1 DESCRIPTION

L<Curse::Server::CGI> is a simple and portable CGI implementation.

=head1 ATTRIBUTES

L<Curse::Server::CGI> inherits all attributes from L<Curse::Server> and
implements the following new ones.

=head2 C<non_parsed_header>

    my $non_parsed_header = $cgi->non_parsed_header;
    $cgi                  = $cgi->non_parsed_header(1);

=head1 METHODS

L<Curse::Server::CGI> inherits all methods from L<Curse::Server> and
implements the following new ones.

=head2 C<run>

    $cgi->run;

=cut