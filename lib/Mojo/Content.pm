# Copyright (C) 2008, Sebastian Riedel.

package Mojo::Content;

use strict;
use warnings;

use base 'Mojo::Stateful';
use bytes;

use Mojo::Buffer;
use Mojo::Cache;
use Mojo::Content::MultiPart;
use Mojo::Headers;

__PACKAGE__->attr([qw/buffer filter_buffer/],
    chained => 1,
    default => sub { Mojo::Buffer->new }
);
__PACKAGE__->attr('cache',
    chained => 1,
    default => sub { Mojo::Cache->new }
);
__PACKAGE__->attr('headers',
    chained => 1,
    default => sub { Mojo::Headers->new }
);
__PACKAGE__->attr('raw_header_length', default => sub { 0 });

sub build_headers {
    my $self = shift;
    my $headers = $self->headers->as_string;
    return '' unless $headers;
    return $self->buffer->replace("$headers\x0d\x0a\x0d\x0a")->as_string;
}

sub body_contains {
    my ($self, $chunk) = @_;
    return $self->cache->contains($chunk);
}

sub body_length { shift->cache->cache_length }

sub get_body_chunk {
    my ($self, $offset) = @_;
    return $self->cache->get_chunk($offset);
}

sub get_header_chunk {
    my ($self, $offset) = @_;
    my $copy = $self->buffer || $self->build_header;
    return substr($copy, $offset, 4096);
}

sub header_length { return length shift->build_headers }

sub is_chunked {
    my $self = shift;
    my $encoding = $self->headers->transfer_encoding || '';
    return $encoding =~ /chunked/i ? 1 : 0;
}

sub is_multipart {
    my $self = shift;
    my $type = $self->headers->content_type || '';
    return $type =~ /multipart/i ? 1 : 0;
}

sub parse {
    my $self = shift;

    # Buffer
    $self->filter_buffer->add_chunk(join '', @_) if @_;
    my $buffer = $self->filter_buffer;

    # Parser started
    if ($self->is_state('start')) {
        my $length = length($self->filter_buffer->{buffer});
        my $raw_length = $self->filter_buffer->raw_length;
        my $raw_header_length =  $raw_length - $length;
        $self->raw_header_length($raw_header_length);
        $self->state('headers');
    }

    # Parse headers
    $self->_parse_headers if $self->is_state('headers');

    # Still parsing headers
    return $self if $self->is_state('headers');

    # Chunked
    if ($self->is_chunked && !$self->is_state('headers')) {
        $self->_filter_chunked_body;
    }

    # Not chunked
    else { $self->buffer->add_chunk($self->filter_buffer->empty) }

    # Content needs to be upgraded to multipart
    return Mojo::Content::MultiPart->new($self) if $self->is_multipart;

    # Parse body
    $self->cache->add_chunk($self->buffer->empty);

    # Done
    unless ($self->is_chunked) {
        my $length = $self->headers->content_length || 0;
        $self->state('done') if $length <= $self->raw_body_length;
    }

    return $self;
}

sub raw_body_length {
    my $self = shift;
    my $length = $self->filter_buffer->raw_length;
    my $header_length = $self->raw_header_length;
    return $length - $header_length;
}

sub _filter_chunked_body {
    my $self = shift;

    # Trailing headers
   if ($self->is_state('trailing_headers')) {
       $self->_parse_trailing_headers;
       return $self;
   }

    # Got a chunk (we ignore the chunk extension)
    my $filter = $self->filter_buffer;
    while ($filter->{buffer} =~ /^(([\da-fA-F]+).*\x0d?\x0a)/) {
        my $length = hex($2);

        # Last chunk
        if ($length == 0) {
            $filter->{buffer} =~ s/^$1//;

            # Trailing headers
            if ($self->headers->trailer) {
                $self->state('trailing_headers');
            }

            # Done
            else {
                $self->_remove_chunked_encoding;
                $filter->empty;
                $self->state('done');
            }
            last;
        }

        # Read chunk
        else {

            # We have a whole chunk
            if (length $filter->{buffer} >= (length($1) + $length)) {
                $filter->{buffer} =~ s/^$1//;
                $self->buffer->add_chunk($filter->remove($length));

                # Remove newline at end of chunk
                $filter->{buffer} =~ s/^\x0d?\x0a//;
            }

            # Not a whole chunk, need to wait for more data
            else { last }
        }
    }

    # Trailing headers
    $self->_parse_trailing_headers if $self->is_state('trailing_headers');
}

sub _parse_headers {
    my $self = shift;
    $self->headers->buffer($self->filter_buffer);
    $self->headers->parse;
    my $length = length($self->headers->buffer->{buffer});
    my $raw_length = $self->headers->buffer->raw_length;
    my $raw_header_length =  $raw_length - $length;
    $self->raw_header_length($raw_header_length);
    $self->state('body') if $self->headers->is_state('done');
}

sub _parse_trailing_headers {
    my $self = shift;
    $self->headers->state('headers');
    $self->headers->parse;
    if ($self->headers->is_state('done')) {
        $self->_remove_chunked_encoding;
        $self->state('done');
    }
}

sub _remove_chunked_encoding {
    my $self = shift;
    my $encoding = $self->headers->transfer_encoding;
    $encoding =~ s/,?\s*chunked//ig;
    $self->headers->transfer_encoding($encoding);
}

1;
__END__

=head1 NAME

Mojo::Content - HTTP Content

=head1 SYNOPSIS

    use Mojo::Content;

    my $content = Mojo::Content->new;
    $content->parse("Content-Length: 12\r\n\r\nHello World!");

=head1 DESCRIPTION

L<Mojo::Content> is a generic container for HTTP content.

=head1 ATTRIBUTES

L<Mojo::Content> inherits all attributes from L<Mojo::Stateful> and
implements the following new ones.

=head2 C<body_length>

    my $body_length = $content->body_length;

=head2 C<buffer>

    my $buffer = $content->buffer;
    $content   = $content->buffer(Mojo::Buffer->new);

=head2 C<cache>

    my $cache = $content->cache;
    $content  = $content->cache(Mojo::Cache->new);

=head2 C<filter_buffer>

    my $filter_buffer = $content->filter_buffer;
    $content          = $content->filter_buffer(Mojo::Buffer->new);

=head2 C<header_length>

    my $header_length = $content->header_length;

=head2 C<headers>

    my $headers = $content->headers;
    $content    = $content->headers(Mojo::Headers->new);

=head2 C<raw_header_length>

    my $raw_header_length = $content->raw_header_length;

=head2 C<raw_body_length>

    my $raw_body_length = $content->raw_body_length;

=head1 METHODS

L<Mojo::Content> inherits all methods from L<Mojo::Stateful> and implements
the following new ones.

=head2 C<build_headers>

    my $string = $content->build_headers;

=head2 C<body_contains>

    my $found = $content->body_contains;

=head2 C<get_body_chunk>

    my $chunk = $content->get_body_chunk(0);

=head2 C<get_header_chunk>

    my $chunk = $content->get_header_chunk(13);

=head2 C<is_chunked>

    my $chunked = $content->is_chunked;

=head2 C<is_multipart>

    my $multipart = $content->is_multipart;

=head2 C<parse>

    $content = $content->parse("Content-Length: 12\r\n\r\nHello World!");

=cut