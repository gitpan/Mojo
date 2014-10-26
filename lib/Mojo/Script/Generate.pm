# Copyright (C) 2008-2009, Sebastian Riedel.

package Mojo::Script::Generate;

use strict;
use warnings;

use base 'Mojo::Scripts';

__PACKAGE__->attr('description', default => <<'EOF');
Generate files and directories from templates.
EOF
__PACKAGE__->attr('hint', default => <<"EOF");

See '$0 generate help GENERATOR' for more information on a specific generator.
EOF
__PACKAGE__->attr('message', default => <<"EOF");
usage: $0 generate GENERATOR [OPTIONS]

These generators are currently available:
EOF
__PACKAGE__->attr('namespaces',
    default => sub { ['Mojo::Script::Generate'] });
__PACKAGE__->attr('usage', default => <<"EOF");
usage: $0 generate GENERATOR [OPTIONS]
EOF

# If The Flintstones has taught us anything,
# it's that pelicans can be used to mix cement.

1;
__END__

=head1 NAME

Mojo::Script::Generate - Generator Script

=head1 SYNOPSIS

    use Mojo::Script::Generate;

    my $generator = Mojo::Script::Generate->new;
    $generator->run(@ARGV);

=head1 DESCRIPTION

L<Mojo::Script::Generate> lists available generators.

=head1 ATTRIBUTES

L<Mojo::Script::Generate> inherits all attributes from L<Mojo::Scripts> and
implements the following new ones.

=head2 C<description>

    my $description = $generator->description;
    $generator      = $generator->description('Foo!');

=head2 C<hint>

    my $hint   = $generator->hint;
    $generator = $generator->hint('Foo!');

=head2 C<message>

    my $message = $generator->message;
    $generator  = $generator->message('Bar!');

=head2 C<namespaces>

    my $namespaces = $generator->namespaces;
    $generator     = $generator->namespaces(['Mojo::Script::Generate']);

=head1 METHODS

L<Mojo::Script::Generate> inherits all methods from L<Mojo::Scripts>.

=cut
