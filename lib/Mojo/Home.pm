# Copyright (C) 2008, Sebastian Riedel.

package Mojo::Home;

use strict;
use warnings;

use base 'Mojo::Base';

use File::Spec;
use FindBin;

__PACKAGE__->attr('parts',  chained => 1, default => sub { [] });
__PACKAGE__->attr('script',
    chained => 1,
    default => sub { $ENV{MOJO_SCRIPT} || 'mojo' }
);

# I'm normally not a praying man, but if you're up there,
# please save me Superman.
sub new {
    my $self = shift->SUPER::new();

    # Parse
    if (@_) { $self->parse(@_) }

    # Detect
    else {
        my $class = (caller())[0];
        $self->detect($class);
    }

    return $self;
}

sub detect {
    my ($self, $class) = @_;

    # Environment variable
    if ($ENV{MOJO_HOME}) {
        my @parts = File::Spec->splitdir($ENV{MOJO_HOME});
        return $self->parts(\@parts);
    }

    # Try to find "mojo.pl" from lib directory
    if ($class) {
        my $file = "$class.pm";
        $file =~ s/::/\//g;

        if (my $entry = $INC{$file}) {
            my $path = $entry;
            $path =~ s/$file$//;
            my @home = File::Spec->splitdir($path);

            # Remove "lib" and "blib"
            pop @home while $home[-1] =~ /^b?lib$/ || $home[-1] eq '';

            # Check for "mojo.pl"
            my $script = $self->script;
            return $self->parts(@home)
              if -f File::Spec->catfile(@home, $script)
              || -f File::Spec->catfile(@home, "$script.pl")
              || -f File::Spec->catfile(@home, 'script', $script)
              || -f File::Spec->catfile(@home, 'script', "$script.pl");
        }
    }

    # Try to find "mojo.pl" from t directory
    my $path;
    my $script = $self->script;
    my @base = File::Spec->splitdir($FindBin::Bin);
    my $pop;
    for my $i (1 .. 5) {

        # "mojo" in root directory
        $pop = 1;
        $path = File::Spec->catfile(@base, '..' x $i, $script);
        last if -f $path;

        # "mojo.pl" in root directory
        $path = File::Spec->catfile(@base, '..' x $i, "$script.pl");
        last if -f $path;

        # "mojo" in bin directory
        $pop = 2;
        $path = File::Spec->catfile(@base, '..' x $i, 'bin', $script);
        last if -f $path;

        # "mojo.pl" in bin directory
        $path = File::Spec->catfile(@base, '..' x $i, 'bin', "$script.pl");
        last if -f $path;
    }

    # Found
    if (-f $path) {
        my @parts = File::Spec->splitdir($path);
        pop @parts;
        pop @parts if $pop == 2;
        $self->parts(\@parts);
    }

    return $self;
}

sub file_to_string {
    my $self = shift;
    return File::Spec->catfile(@{$self->parts}, @_);
}

sub lib_to_string {
    my $self = shift;

    # Directory found
    my $path = File::Spec->catdir(@{$self->parts}, 'lib');
    return $path if -d $path;

    # No lib directory
    return undef;
}

sub parse {
    my ($self, $path) = @_;
    my @parts = File::Spec->splitdir($path);
    $self->parts(\@parts);
    return $self;
}

sub script_to_string {
    my $self = shift;

    # "mojo" in root directory
    my $path = File::Spec->catfile(@{$self->parts}, $self->script);
    return $path if -f $path;

    # "mojo.pl" in root directory
    $path = File::Spec->catfile(@{$self->parts}, $self->script . '.pl');
    return $path if -f $path;

    # "mojo" in bin directory
    $path = File::Spec->catfile(@{$self->parts}, 'bin', $self->script);
    return $path if -f $path;

    # "mojo.pl" in bin directory
    $path = File::Spec->catfile(
        @{$self->parts}, 'bin', $self->script . '.pl'
    );
    return $path if -f $path;

    # No script
    return undef;
}

sub to_string {
    my $self = shift;
    return File::Spec->catdir(@{$self->parts}, @_);
}

1;
__END__

=head1 NAME

Mojo::Home - Home Sweet Home!

=head1 SYNOPSIS

    use Mojo::Home;

=head1 DESCRIPTION

L<Mojo::Home> is a container for home directories.

=head1 ATTRIBUTES

=head2 C<parts>

    my $parts = $home->parts;
    $home     = $home->parts([qw/foo bar baz/]);

=head2 C<script>

    my $script = $home->script;
    $home      = $home->script('mojo.pl');

=head1 METHODS

L<Mojo::Home> inherits all methods from L<Mojo::Base> and implements the
following new ones.

=head2 C<new>

    my $home = Mojo::Home->new;
    my $home = Mojo::Home->new('/foo/bar/baz');

=head2 C<detect>

    $home = $home->detect;
    $home = $home->detect('My::App');

=head2 C<file_to_string>

    my $string = $home->file_to_string(qw/foo bar.html/);

=head2 C<lib_to_string>

    my $string = $home->lib_to_string;

=head2 C<parse>

    $home = $home->parse('/foo/bar');

=head2 C<script_to_string>

    my $string = $home->script_to_string;

=head2 C<to_string>

    my $string = $home->to_string;
    my $string = $home->to_string(qw/foo bar/);
    my $string = "$home";

=cut