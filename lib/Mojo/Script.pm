# Copyright (C) 2008, Sebastian Riedel.

package Mojo::Script;

use strict;
use warnings;

use base 'Mojo::Base';

require Carp;
require Cwd;
require File::Path;
require File::Spec;
require IO::File;

use Mojo::Template;

__PACKAGE__->attr('description',
    chained => 1,
    default => sub { 'No description.' }
);
__PACKAGE__->attr('quiet', chained => 1, default => sub { 0 });

sub chmod_file {
    my ($self, $path, $mod) = @_;
    chmod $mod, $path or die qq/Can't chmod path "$path": $!/;

    $mod = sprintf '%lo', $mod;
    print "  [chmod] $path $mod\n" unless $self->quiet;
    return $self;
}

sub cwd_dir {
    my $self = shift;
    my @parts;
    for my $part (@_) {
        push @parts, File::Spec->splitdir($part);
    }
    return File::Spec->catdir(Cwd::getcwd(), @parts);
}

sub cwd_file {
    my $self = shift;
    my @parts;
    for my $part (@_) {
        push @parts, File::Spec->splitdir($part);
    }
    return File::Spec->catfile(Cwd::getcwd(), @parts);
}

sub get_data {
    my ($self, $data, $class) = @_;
    $class ||= ref $self;

    # Cache
    my $sections = $self->{data};

    # Slurp
    $sections = do {
        local $/;
        eval "package $class; <DATA>";
    } unless $sections;

    $self->{data} ||= $sections;

    # Split
    my @data = split /^__(.+)__\r?\n/m, $sections;

    # Remove split garbage
    shift @data;

    # Find data
    while (@data) {
        my ($name, $content) = splice @data, 0, 2;
        return $content if $name eq $data;
    }

    return undef;
}

sub make_dir {
    my ($self, $path) = @_;

    # Exists
    if (-d $path) {
        print "  [exist] $path\n" unless $self->quiet;
        return $self;
    }

    # Make
    File::Path::mkpath($path) or die qq/Can't make directory "$path": $!/;
    print "  [mkdir] $path\n" unless $self->quiet;
    return $self;
}

sub render_data {
    my $self = shift;
    my $data = shift;

    # Get data
    my $template = $self->get_data($data);

    # Render
    my $mt = Mojo::Template->new;
    return $mt->render($template, @_);
}

# My cat's breath smells like cat food.
sub run { Carp::croak('Method "run" not implemented by subclass') }

sub write_file {
    my ($self, $path, $data) = @_;

    # Open file
    my $file = IO::File->new;
    $file->open(">$path") or die qq/Can't open file "$path": $!/;

    # Write unbuffered
    $file->syswrite($data);

    print "  [write] $path\n" unless $self->quiet;
    return $self;
}

1;
__END__

=head1 NAME

Mojo::Script - Script Base Class

=head1 SYNOPSIS

    use base 'Mojo::Script';

    sub run {
        my $self = shift;
        my $data = $self->render_data('foo_bar');
        $self->write_file('/foo/bar.txt', $data);
    }

    1;
    __DATA__
    __foo_bar__
    % for (1 .. 5) {
        Hello World!
    % }

=head1 DESCRIPTION

L<Mojo::Script> is a generic base class for scripts.

=head1 ATTRIBUTES

=head2 C<description>

    my $description = $script->description;
    $script         = $script->description('Foo!');

=head2 C<quiet>

    my $quiet = $script->quiet;
    $script   = $script->quiet(1);

=head1 METHODS

L<Mojo::Script> inherits all methods from L<Mojo::Base> and implements the
following new ones.

=head2 C<chmod_file>

    $script = $script->chmod_file('/foo/bar.txt', 0644);


=head2 C<cwd_dir>

    my $path = $script->cwd_dir(qw/foo bar/);

=head2 C<cwd_file>

    my $path = $script->cwd_file(qw/foo bar.html/);

=head2 C<get_data>

    my $data = $script->get_data('foo_bar');

=head2 C<make_dir>

    $script = $script->make_dir('/foo/bar/baz');

=head2 C<render_data>

    my $data = $script->render_data('foo_bar', @arguments);

=head2 C<run>

    $script = $script->run(@ARGV);

=head2 C<write_file>

    $script = $script->write_file('/foo/bar.txt', 'Hello World!');

=cut