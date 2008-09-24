# Copyright (C) 2008, Sebastian Riedel.

package Mojo::Script::Generate::Application;

use strict;
use warnings;

use base 'Mojo::Script';

use Curse::ByteStream;

__PACKAGE__->attr('description', chained => 1, default => <<'EOF');
* Generate application directory structure. *
Takes a name as option, by default MyMojoApp will be used.
    generate application TestApp
EOF

# Okay folks, show's over. Nothing to see here, show's... Oh my god!
# A horrible plane crash! Hey everybody, get a load of this flaming wreckage!
# Come on, crowd around, crowd around!
sub run {
    my ($self, $class) = @_;
    $class ||= 'MyMojoApp';

    my $name = $class;
    $name =~ s/:://g;
    $name = Curse::ByteStream->new($name)->decamelize->as_string;

    # Root
    my $root = $self->get_path($name);
    $self->make_dir($root);

    # "lib"
    my $lib = $self->get_path($name, 'lib');
    $self->make_dir($lib);

    # "t"
    my $t = $self->get_path($name, 't');
    $self->make_dir($t);

    # "mojo.pl"
    my $script = $self->get_path($name, 'mojo.pl');
    my $content = $self->render_data('mojo.pl', $class);
    $self->write_file($script, $content);
    $self->chmod_file($script, 0744);

     # "MyApp.pm"
    my @current;
    my @namespaces = split /::/, $class;
    for my $namespace (@namespaces) {
        push @current, $namespace;
        my $path = $self->get_path($name, 'lib', @current);
        last if @current == @namespaces;
        $self->make_dir($path);
    }
    $current[-1] .= '.pm';
    my $appclass = $self->get_path($name, 'lib', @current);
    $content = $self->render_data('appclass', $class);
    $self->write_file($appclass, $content);

    # "basic.t"
    my $basic = $self->get_path($name, 't', 'basic.t');
    $content = $self->render_data('test', $class);
    $self->write_file($basic, $content);
}

1;

=head1 NAME

Mojo::Script::Generate::Application - Application Generator Script

=head1 SYNOPSIS

    use Mojo::Script::Generate::Application;
    my $app = Mojo::Script::Generate::Application->new;
    $app->run(@ARGV);

=head1 DESCRIPTION

L<Mojo::Script::Generate::Application> is a simple application generator.

=head1 ATTRIBUTES

L<Mojo::Script::Generate::Application> inherits all attributes from
L<Mojo::Scripts> and implements the following new ones.

=head2 C<description>

    my $description = $app->description;
    $app            = $app->description('Foo!');

=head2 C<run>

    $app = $app->run(@ARGV);

=cut

__DATA__
__mojo.pl__
% my $class = shift;
#!<%= $^X %>

# Copyright (C) 2008, Sebastian Riedel.

use strict;
use warnings;

use FindBin;

use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../../lib";

$ENV{MOJO_APP} = '<%= $class %>';

# Check if Mojo is installed
eval 'use Mojo::Scripts';
if ($@) {
    print <<EOF;
It looks like you don't have the Mojo Framework installed.
Please visit http://getmojo.kraih.com for detailed installation instructions.

EOF
    exit;
}

# Start the script system
my $scripts = Mojo::Scripts->new;
$scripts->run(@ARGV);
__appclass__
% my $class = shift;
package <%= $class %>;

use strict;
use warnings;

use base 'Mojo';

sub handler {
    my ($self, $tx) = @_;

    # $tx is a Curse::Transaction instance
    $tx->res->code(200);
    $tx->res->headers->content_type('text/plain');
    $tx->res->body('Hello Mojo!');

    return $tx;
}

1;
__test__
% my $class = shift;
#!perl

use strict;
use warnings;

use Test::More tests => 1;

use_ok('<%= $class %>');