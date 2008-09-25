# Copyright (C) 2008, Sebastian Riedel.

package Mojo::Cache;

use strict;
use warnings;
use bytes;

use base 'Mojo::Base';

__PACKAGE__->attr('content', default => sub { '' });

# There's your giraffe, little girl.
# I'm a boy.
# That's the spirit. Never give up.
sub new {
    my $self = shift->SUPER::new();
    $self->add_chunk(join '', @_) if @_;
    return $self;
}

sub add_chunk {
    my ($self, $chunk) = @_;
    $self->{content} ||= '';
    $self->{content}  .= $chunk;
    return $self;
}

sub cache_length { return length(shift->{content} || '') }

sub contains { return index(shift->{content}, shift) >= 0 ? 1 : 0 }

sub get_chunk {
    my ($self, $offset) = @_;
    my $copy = $self->content;
    return substr $copy, $offset, 4096;
}

sub slurp { return shift->content }

1;
__END__

=head1 NAME

Mojo::Cache - Memory Cache

=head1 SYNOPSIS

    use Mojo::Cache;

    my $cache = Mojo::Cache->new('Hello!');
    $cache->add_chunk('World!');
    print $cache->slurp;

=head1 DESCRIPTION

L<Mojo::Cache> is a generic container for in-memory data.

=head1 ATTRIBUTES

=head2 C<cache_length>

    my $cache_length = $cache->cache_length;

=head2 C<content>

    my $handle = $cache->content;
    $cache     = $cache->content('Hello World!');

=head1 METHODS

L<Mojo::Cache> inherits all methods from L<Mojo::Base> and implements the
following new ones.

=head2 C<add_chunk>

    $cache = $cache->add_chunk('test 123');

=head2 C<contains>

    my $contains = $cache->contains('random string');

=head2 C<get_chunk>

    my $chunk = $cache->get_chunk($offset);

=head2 C<slurp>

    my $string = $cache->slurp;

=cut