# Copyright (C) 2008, Sebastian Riedel.

package Curse::Message;

use strict;
use warnings;

use base 'Curse::Stateful';
use overload '""' => sub { shift->as_string }, fallback => 1;
use bytes;

use Carp 'croak';
use Curse::Buffer;
use Curse::ByteStream;
use Curse::Content;
use Curse::URL;

__PACKAGE__->attr('buffer',
    chained => 1,
    default => sub { Curse::Buffer->new }
);
__PACKAGE__->attr('content',
    chained => 1,
    default => sub { Curse::Content->new }
);
__PACKAGE__->attr([qw/major_version minor_version/],
    chained => 1,
    default => sub { 1 }
);

*as_string = \&build;

# I'll keep it short and sweet. Family. Religion. Friendship.
# These are the three demons you must slay if you wish to succeed in
# business.
sub body {
    my ($self, $content) = @_;

    # External content generator
    $self->{body} = $content if ref $content eq 'CODE';

    # Plain old content
    unless ($self->is_multipart) {

        # Get/Set content
        if ($content) {
            $self->content->cache(Curse::Cache->new);
            $self->content->cache->add_chunk($content);
        }
        return $self->content->cache->slurp;
    }

    $self->content($content);
    return $self->content;
}

sub body_length { shift->content->body_length }

# Quick Smithers. Bring the mind eraser device!
# You mean the revolver, sir?
# Precisely.
sub build {
    my $self = shift;
    my $message = '';

    # Start line
    my $offset = 0;
    while ($offset < $self->start_line_length) {
        my $chunk = $self->get_start_line_chunk($offset);
        $offset += length $chunk;
        $message .= $chunk;
    }

    # Headers
    $offset = 0;
    while ($offset < $self->header_length) {
        my $chunk = $self->get_header_chunk($offset);
        $offset += length $chunk;
        $message .= $chunk;
    }

    # Body
    $message .= $self->build_body;

    return $message;
}

sub build_body {
    my $self = shift;

    my $body = '';
    my $offset = 0;
    while (1) {
        my $chunk = $self->get_body_chunk($offset);

        # No content yet, try again
        next unless defined $chunk;

        # End of content
        last unless length $chunk;

        # Content
        $offset += length $chunk;
        $body .= $chunk;
    }

    return $body;
}

sub build_headers {
    my $self = shift;

    # HTTP 0.9 has no headers
    return '' if $self->version eq '0.9';

    # Fix headers
    $self->fix_headers;

    return $self->buffer->replace($self->content->build_headers)->as_string;
}

sub build_start_line {
    croak 'Method "build_start_line" not implemented by subclass';
}

# B-6
# You sunk my scrabbleship!
# This game makes no sense.
# Tell that to the good men who just lost their lives... SEMPER-FI!
sub fix_headers {
    my $self = shift;

    # Content-Length header is required in HTTP 1.0 messages
    my $length = $self->body_length;
    if ($self->is_version('1.0') && !$self->is_chunked && $length) {
        $self->headers->content_length($length)
          unless $self->headers->content_length;
    }

    return $self;
}

sub get_body_chunk {
    my $self = shift;

    return $self->is_chunked
      ? $self->_get_chunked_body_chunk(@_)
      : $self->content->get_body_chunk(@_);
}

sub get_header_chunk {
    my ($self, $offset) = @_;
    my $copy = $self->buffer->raw_length
      ? $self->buffer->empty
      : $self->build_headers;
    return substr($copy, $offset, 4096);
}

sub get_start_line_chunk {
    my ($self, $offset) = @_;
    my $copy = $self->buffer || $self->build_start_line;
    return substr($copy, $offset, 4096);
}

sub header_length { return length shift->build_headers }

sub headers { shift->content->headers(@_) }

sub is_chunked { shift->content->is_chunked }

sub is_multipart { shift->content->is_multipart }

sub is_version {
    my ($self, $version) = @_;
    my ($major, $minor) = split /\./, $version;

    # Version is equal or newer
    return 1 if $major > $self->major_version;
    if ($major == $self->major_version) {
        return 1 if $minor <= $self->minor_version;
    }

    # Version is older
    return 0;
}

# Please don't eat me! I have a wife and kids. Eat them!
sub parse {
    my $self = shift;

    # Buffer
    $self->buffer->add_chunk(join '', @_) if @_;

    # Content
    if ($self->is_state(qw/content done/)) {
        my $content = $self->content;
        $content->state('body') if $self->version eq '0.9';
        $content->filter_buffer($self->buffer);
        $self->content($content->parse);
    }

    # Done
    $self->state('done') if $self->content->is_state('done');

    return $self;
}

sub start_line_length { return length shift->build_start_line }

sub version {
    my ($self, $version) = @_;

    # Return normalized version
    unless ($version) {
        my $major = $self->major_version;
        $major = 1 unless defined $major;
        my $minor = $self->minor_version;
        $minor = 1 unless defined $minor;
        return "$major.$minor";
    }

    # New version
    my ($major, $minor) = split /\./, $version;
    $self->major_version($major);
    $self->minor_version($minor);

    return $self;
}

sub _get_chunked_body_chunk {
    my ($self, $offset) = @_;

    # Buffered?
    $self->{_chunk_offset} ||= 0;
    $self->{_buffer} = '' if $self->{_chunk_offset} == 0;
    substr $self->{_buffer}, 0, $offset - $self->{_chunk_offset}, '';
    return $self->{_buffer} if $self->{_buffer};

    # Generate more
    $self->{_chunk_offset} = $offset;
    unless ($self->{_chunks_done}) {
        my $chunk = $self->{body}->($self);
        return undef unless defined $chunk;
        my $chunk_length = length $chunk;

        # Trailing headers?
        my $headers = 1 if ref $chunk && $chunk->isa('Curse::Headers');

        # End
        if ($headers || ($chunk_length == 0)) {
            $self->{_buffer} .= "\x0d\x0a0\x0d\x0a";

            # Trailing headers
            $self->{_buffer} .= "$chunk\x0d\x0a\x0d\x0a" if $headers;
            $self->{_chunks_done} = 1;
        }

        # Separator
        else {

            # First chunk has no leading CRLF
            $self->{_buffer} .= "\x0d\x0a" unless $offset == 0;

            # Chunk
            $self->{_buffer} .= sprintf('%x', length $chunk)
              . "\x0d\x0a$chunk";
        }
    }
    return $self->{_buffer};
}

1;
__END__

=head1 NAME

Curse::Message - HTTP Message Base Class

=head1 SYNOPSIS

    use base 'Curse::Message';

=head1 DESCRIPTION

L<Curse::Message> is a generic base class for HTTP messages.

=head1 ATTRIBUTES

L<Curse::Message> inherits all attributes from L<Curse::Stateful> and
implements the following new ones.

=head2 C<body_length>

    my $body_length = $message->body_length;

=head2 C<buffer>

    my $buffer = $message->buffer;
    $message   = $message->buffer(Curse::Buffer->new);

=head2 C<content>

    my $content = $message->content;
    $message    = $message->content(Curse::Content->new);

=head2 C<header_length>

    my $header_length = $message->header_length;

=head2 C<headers>

    my $headers = $message->headers;
    $message    = $message->headers(Curse::Headers->new);

=head2 C<major_version>

    my $major_version = $message->major_version;
    $message          = $message->major_version(1);

=head2 C<minor_version>

    my $minor_version = $message->minor_version;
    $message          = $message->minor_version(1);

=head2 C<raw_body_length>

    my $raw_body_length = $message->raw_body_length;

=head2 C<start_line_length>

    my $start_line_length = $message->start_line_length;

=head2 C<version>

    my $version = $message->version;
    $message    = $message->version('1.1');

=head1 METHODS

L<Curse::Message> inherits all methods from L<Curse::Stateful> and implements
the following new ones.

=head2 C<as_string>

    my $string = $message->as_string;

=head2 C<body>

    my $string = $message->body;
    $message = $message->body('Hello!');

    $counter = 1;
    $message = $message->body(sub {
        my $self  = shift;
        my $chunk = '';
        $chunk    = "hello world!" if $counter == 1;
        $chunk    = "hello world2!\n\n" if $counter == 2;
        $counter++;
        return $chunk;
    });

=head2 C<build>

    my $string = $message->build;

=head2 C<build_body>

    my $string = $message->build_body;

=head2 C<build_headers>

    my $string = $message->build_headers;

=head2 C<build_start_line>

    my $string = $message->build_start_line;

=head2 C<fix_headers>

    $message = $message->fix_headers;

=head2 C<get_body_chunk>

    my $string = $message->get_body_chunk($offset);

=head2 C<get_header_chunk>

    my $string = $message->get_header_chunk($offset);

=head2 C<get_start_line_chunk>

    my $string = $message->get_start_line_chunk($offset);

=head2 C<is_chunked>

    my $is_chunked = $message->is_chunked;

=header2 C<is_multipart>

    my $is_multipart = $message->is_multipart;

=head2 C<is_version>

    my $is_version = $message->is_version('1.1);

=head2 C<parse>

    $message = $message->parse('HTTP/1.1 200 OK...');

=cut