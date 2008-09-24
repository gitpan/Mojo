# Copyright (C) 2008, Sebastian Riedel.

package Mojo::Script::Test;

use strict;
use warnings;

use base 'Mojo::Script';

use Cwd 'realpath';
use FindBin;
use File::Spec::Functions qw/abs2rel catdir catfile splitdir/;
use Test::Harness;

__PACKAGE__->attr('description', chained => 1, default => <<'EOF');
* Run unit tests. *
Takes a list of tests as options, by default it will try to detect a 't'
directory.
    test
    test t/*.t ../t/something.t
EOF

# My eyes! The goggles do nothing!
sub run {
    my ($self, @tests) = @_;

    # Search tests
    unless (@tests) {
        my @base = splitdir(abs2rel($FindBin::Bin));
        # Test directory in the same directory as mojo.pl (t)
        my $path = catdir(@base, 't');

        # Test dirctory in the directory above mojo.pl (../t)
        $path = catdir(@base, '..', 't') unless -d $path;
        unless (-d $path) {
            print "Can't find test directory.\n";
            return 0;
        }

        # List test files
        my @dirs = ($path);
        while (my $dir = shift @dirs) {
            opendir(my $fh, $dir);
            for my $file (readdir($fh)) {
                next if $file eq '.';
                next if $file eq '..';
                my $fpath = catfile($dir, $file);
                push @dirs, catdir($dir, $file) if -d $fpath;
                push @tests, abs2rel(realpath(catfile(splitdir($fpath))))
                  if (-f $fpath) && ($fpath =~ /\.t$/);
            }
            closedir $fh;
        }

        $path = realpath($path);
        print "Running tests from '$path'.\n";
    }

    # Run tests
    runtests(@tests);

    return $self;
}

1;
__END__

=head1 NAME

Mojo::Script::Test - Test Script

=head1 SYNOPSIS

    use Mojo::Script::Test;
    my $test = Mojo::Script::Test->new;
    $test->run(@ARGV);

=head1 DESCRIPTION

L<Mojo::Script::Test> is a simple test script.

=head1 ATTRIBUTES

L<Mojo::Script::Test> inherits all attributes from L<Mojo::Script> and
implements the following new ones.

=head2 C<description>

    my $description = $test->description;
    $test           = $test->description('Foo!');

=head1 METHODS

L<Mojo::Script::Test> inherits all methods from L<Mojo::Script> and
implements the following new ones.

=head2 C<run>

    $test = $test->run(@ARGV);

=cut