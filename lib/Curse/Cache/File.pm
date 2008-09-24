# Copyright (C) 2008, Sebastian Riedel.

package Curse::Cache::File;

use strict;
use warnings;

use base 'Curse::Cache';
use bytes;

use File::Temp;

__PACKAGE__->attr('handle',
    chained => 1, 
    default => sub { File::Temp->new }
);

# Hi, Super Nintendo Chalmers!
sub add_chunk {
    my $self  = shift;
    my $chunk = join '', @_ if @_;

    # Shortcut
    return unless $chunk;

    # Seek to end
    $self->handle->seek(0, SEEK_END);

    # Store
    $self->handle->syswrite($chunk, length $chunk);

    return $self;
}

sub cache_size { return -s shift->handle->filename }

sub contains {
    my ($self, $bytestream) = @_;
    my ($buffer, $window);

    # Seek to start
    $self->handle->seek(0, SEEK_SET);

    # Read
    my $read = $self->handle->sysread($window, length($bytestream) * 2);
    my $offset = $read;

    # Moving window search
    while ($offset < $self->cache_size) {
        $read = $self->handle->sysread($buffer, length($bytestream));
        $offset += $read;
        $window .= $buffer;
        my $pos = index $window, $bytestream;
        return 1 if $pos >= 0;
        substr $window, 0, $read, '';
    }

    return 0;
}

sub get_chunk {
    my ($self, $offset) = @_;

    # Seek to start
    $self->handle->seek(0, SEEK_SET);

    # Read
    $self->handle->sysread(my $buffer, 4096, $offset);
    return $buffer;
}

sub slurp {
    my $self = shift;

    # Seek to start
    $self->handle->seek(0, SEEK_SET);

    # Slurp
    my $content = '';
    while ($self->handle->sysread(my $buffer, 4096)) {
        $content .= $buffer;
    }

    return $content;
}

1;
__END__

=head1 NAME

Curse::Cache::File - File Cache

=head1 SYNOPSIS

    use Curse::Cache::File;

    my $cache = Curse::Cache::File->new('Hello!');
    $cache->add_chunk('World!');
    print $cache->slurp;

=head1 DESCRIPTION

L<Curse::Cache::File> is a generic container for files.

=head1 ATTRIBUTES

L<Curse::Cache::File> inherits all attributes from L<Curse::Cache> and
implements the following new ones.

=head2 C<handle>

    my $handle = $cache->handle;
    $cache     = $cache->handle(IO::File->new);

=head2 C<cache_size>

    my $cache_size = $cache->cache_size;

=head1 METHODS

L<Curse::Cache::File> inherits all methods from L<Curse::Cache> and
implements the following new ones.

=head2 C<add_chunk>

    $cache = $cache->add_chunk('test 123');

=head2 C<contains>

    my $contains = $cache->contains('random string');

=head2 C<get_chunk>

    my $chunk = $cache->get_chunk($offset);

=head2 C<slurp>

    my $string = $cache->slurp;

=cut