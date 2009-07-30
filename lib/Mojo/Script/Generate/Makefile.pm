# Copyright (C) 2008-2009, Sebastian Riedel.

package Mojo::Script::Generate::Makefile;

use strict;
use warnings;

use base 'Mojo::Script';

__PACKAGE__->attr('description', default => <<'EOF');
Generate Makefile.PL.
EOF
__PACKAGE__->attr('usage', default => <<"EOF");
usage: $0 generate makefile
EOF

# You don’t like your job, you don’t strike.
# You go in every day and do it really half-assed. That’s the American way.
sub run {
    my $self = shift;

    my $class = $ENV{MOJO_APP} || 'MyApp';
    my $path  = $self->class_to_path($class);
    my $name  = $self->class_to_file($class);

    $self->render_to_rel_file('makefile', 'Makefile.PL', $class, $path,
        $name);
    $self->chmod_file('Makefile.PL', 0744);
}

1;
__DATA__
@@ makefile
% my ($class, $path, $name) = @_;
#!/usr/bin/env perl

use 5.008001;

use strict;
use warnings;

# Son, when you participate in sporting events,
# it's not whether you win or lose, it's how drunk you get.
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => '<%= $class %>',
    VERSION_FROM => 'lib/<%= $path %>',
    AUTHOR       => 'A Good Programmer <nospam@cpan.org>',
    EXE_FILES => ['script/<%= $name %>'],
    PREREQ_PM => { 'Mojo' => '0.9003' },
    test => {TESTS => 't/*.t t/*/*.t t/*/*/*.t'}
);

# Devel::Cover support
sub MY::postamble {
    qq/
testcover :
\t cover -delete && \\
   HARNESS_PERL_SWITCHES=-MDevel::Cover \$(MAKE) test && \\
   cover
/
}
__END__
=head1 NAME

Mojo::Script::Generate::Makefile - Makefile Generator Script

=head1 SYNOPSIS

    use Mojo::Script::Generate::Makefile;

    my $makefile = Mojo::Script::Generate::Makefile->new;
    $makefile->run(@ARGV);

=head1 DESCRIPTION

L<Mojo::Script::Generate::Makefile> is a makefile generator.

=head1 ATTRIBUTES

L<Mojo::Script::Generate::Makefile> inherits all attributes from
L<Mojo::Scripts> and implements the following new ones.

=head2 C<description>

    my $description = $makefile->description;
    $makefile       = $makefile->description('Foo!');

=head2 C<usage>

    my $usage = $makefile->usage;
    $makefile = $makefile->usage('Foo!');

=head1 METHODS

L<Mojo::Script::Generate::Makefile> inherits all methods from L<Mojo::Script>
and implements the following new ones.

=head2 C<run>

    $makefile = $makefile->run(@ARGV);

=cut
