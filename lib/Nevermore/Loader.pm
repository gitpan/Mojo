# Copyright (C) 2008, Sebastian Riedel.

package Nevermore::Loader;

use strict;
use warnings;

use base 'Nevermore';

use Carp qw/carp croak/;
use File::Basename 'fileparse';
use File::Spec::Functions qw/abs2rel catdir catfile splitdir/;

__PACKAGE__->attr([qw/base namespace/], chained => 1);

my $STATS = {};

BEGIN {

    # Debugger sub tracking
    $^P |= 0x10;

    # Bug in pre-5.8.7 perl
    # http://rt.perl.org/rt3/Ticket/Display.html?id=35059
    eval 'sub DB::sub' if $] < 5.008007;
}

sub modules {
    my ($self, @modules) = @_;

    $self ->{modules} ||= [];
    $self->{modules} = \@modules if $modules[0];

    # Chained
    return $self if @modules;

    return @{$self->{modules}};
}

# Homer no function beer well without.
sub new {
    my ($class, $namespace) = @_;
    my $self = $class->SUPER::new();
    $self->namespace($namespace);
    $self->search if $namespace;
    return $self;
}

sub instantiate {
    my $self = shift;

    # Load
    $self->load;

    # Load and instantiate
    my @instances;
    foreach my $module ($self->modules) {
        eval {
            if (my $base = $self->base) {
                die unless $module->isa($base);
            }
            my $instance = $module->new(@_);
            push @instances, $instance;
        };
    }

    return @instances > 1 ? @instances : $instances[0];
}

sub load {
    my ($self, @modules) = @_;

    $self->modules(@modules) if $modules[0];

    for my $module ($self->modules) {

        # Shortcut
        next if $module->can('isa');

        # Load
        eval "require $module";
        croak qq/Unable to load module "$module": $@/ if $@;
    }

    return $self;
}

sub reload {
    while (my ($key, $file) = each %INC) {

        # Modified time
        my $mtime = (stat $file)[9];

        # Startup time as default
        $STATS->{$file} = $^T unless defined $STATS->{$file};

        # Modified?
        if ($mtime > $STATS->{$file}) {

            # Unload
            delete $INC{$key};
            my @subs = grep { index($DB::sub{$_}, "$file:") == 0 }
              keys %DB::sub;
            for my $sub (@subs) {
                eval { undef &$sub };
                carp "Can't unload sub '$sub' in '$file': $@" if $@;
                delete $DB::sub{$sub};
            }

            # Reload
            eval { require $key };
            carp "Can't reload '$file': $@" if $@;

            $STATS->{$file} = $mtime;
        }
    }
}

sub search {
    my ($self, $namespace) = @_;

    $namespace ||= $self->namespace;
    $self->namespace($namespace);

    # Directories
    my @directories = exists $INC{'blib.pm'} ? grep { /blib/ } @INC : @INC;

    # Scan
    my %found;
    foreach my $directory (@directories) {
        my $path = catdir($directory, (split /::/, $namespace));
        next unless (-e $path && -d $path);

        # Find
        opendir(my $dir, $path);
        my @files = grep /\.pm$/, readdir($dir);
        closedir($dir);
        for my $file (@files) {
            my $full = catfile(splitdir($path), $file);
            next if -d $full;
            my $name = fileparse $file, qr/\.pm/;
            $self->{modules} ||= [];
            my $class = "$namespace\::$name";
            push @{$self->{modules}}, $class unless $found{$class};
            $found{$class} ||= 1;
        }
    }

    return $self;
}

1;
__END__

=head1 NAME

Nevermore::Loader - A Universal Class Loader

=head1 SYNOPSIS

    use Nevermore::Loader;

    # Verbose
    my @instances = Nevermore::Loader->new
      ->namespace('Some::Namespace')
      ->search
      ->load
      ->base('Some::Module')
      ->instantiate;

    # Short
    my @instances = Nevermore::Loader->new
      ->modules('Some::Namespace')
      ->instantiate;

    # Reload
    Nevermore::Loader->reload;

=head1 DESCRIPTION

L<Nevermore::Loader> is a universal class loader and plugin framework.

=head1 ATTRIBUTES

=head2 C<base>

    my $base = $loader->base;
    $loader  = $loader->base('MyApp::Base');

=head2 C<modules>

    my @modules = $loader->modules;
    $loader     = $loader->modules(qw/MyApp::Foo MyApp::Bar/);

=head2 C<namespace>

    my $namespace = $loader->namespace;
    $loader       = $loader->namespace('MyApp::Namespace');

=head1 METHODS

L<Nevermore::Loader> inherits all methods from L<Nevermore> and implements
the following new ones.

=head2 C<new>

    my $loader = Nevermore::Loader->new;
    my $loader = Nevermore::Loader->new('MyApp::Namespace');

=head2 C<instantiate>

    my $first     = $loader->instantiate;
    my @instances = $loader->instantiate;
    my $first     = $loader->instantiate(qw/foo bar baz/);
    my @instances = $loader->instantiate(qw/foo bar baz/);

Note that only the main package will be instantiated, file contents won't be
scanned for multiple package declarations.

=head2 C<load>

    $loader = $loader->load;

=head2 C<search>

    $loader = $loader->search;
    $loader = $loader->search('MyApp::Namespace');

=head2 C<reload>

    Nevermore::Loader->reload;

=cut