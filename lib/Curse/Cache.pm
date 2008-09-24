# Copyright (C) 2008, Sebastian Riedel.

package Curse::Cache;

use strict;
use warnings;
use bytes;

use base 'Nevermore';

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

sub cache_size { return length(shift->{content} || '') }

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

Curse::Cache - Memory Cache

=head1 SYNOPSIS

    use Curse::Cache;

    my $cache = Curse::Cache->new('Hello!');
    $cache->add_chunk('World!');
    print $cache->slurp;

=head1 DESCRIPTION

L<Curse::Cache> is a generic container for in-memory data.

=head1 ATTRIBUTES

=head2 C<cache_size>

    my $cache_size = $cache->cache_size;

=head2 C<content>

    my $handle = $cache->content;
    $cache     = $cache->content('Hello World!');

=head1 METHODS

L<Curse::Cache> inherits all methods from L<Nevermore> and implements the
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