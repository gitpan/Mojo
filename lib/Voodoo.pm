# Copyright (C) 2008, Sebastian Riedel.

package Voodoo;

use strict;
use warnings;

use base 'Nevermore';

use Carp 'croak';
use IO::File;

__PACKAGE__->attr('code'           , chained => 1, default => sub {''  });
__PACKAGE__->attr('comment_mark'   , chained => 1, default => sub {'#' });
__PACKAGE__->attr('debug'          , chained => 1, default => sub {1   });
__PACKAGE__->attr('expression_mark', chained => 1, default => sub {'=' });
__PACKAGE__->attr('line_start'     , chained => 1, default => sub {'%' });
__PACKAGE__->attr('template'       , chained => 1, default => sub {''  });
__PACKAGE__->attr('tree'           , chained => 1, default => sub {[]  });
__PACKAGE__->attr('tag_start'      , chained => 1, default => sub {'<%'});
__PACKAGE__->attr('tag_end'        , chained => 1, default => sub {'%>'});

sub compile {
    my $self = shift;

    # Compile
    my @lines;
    for my $line (@{$self->tree}) {

        # New line
        push @lines, '';
        for (my $j = 0; $j < @{$line}; $j += 2) {
            my $type  = $line->[$j];
            my $value = $line->[$j + 1];

            # Need to fix line ending?
            my $newline = chomp $value;

            # Text
            if ($type eq 'text') {

                # Quote and fix line ending
                $value = quotemeta($value);
                $value .= '\n' if $newline;

                $lines[-1] .= "\$_VOODOO .= \"" . $value . "\";";
            }

            # Code
            if ($type eq 'code') {
                $lines[-1] .= "$value;";
            }

            # Expression
            if ($type eq 'expr') {
                $lines[-1] .= "\$_VOODOO .= $value;";
            }
        }
    }

    # Wrap
    $lines[0]   = q/sub { my $_VOODOO = '';/ . $lines[0];
    $lines[-1] .= q/return $_VOODOO; };/;

    $self->code(join "\n", @lines);
    return $self;
}

sub interpret {
    my $self = shift;

    # Shortcut
    my $code = $self->code;
    return undef unless $code;

    # Catch warnings
    local $SIG{__WARN__} = sub {
        my $error = shift;
        warn $self->_error($error);
    };

    # Prepare
    my $sub  = eval $code;
    return $self->_error($@) if $@;

    # Interpret
    my $result = eval { $sub->(@_) };
    return $self->_error($@) if $@;

    return $result;
}

# I am so smart! I am so smart! S-M-R-T! I mean S-M-A-R-T...
sub parse {
    my ($self, $tmpl) = @_;
    $self->template($tmpl);

    # Clean start
    delete $self->{tree};

    # Tags
    my $line_start = quotemeta $self->line_start;
    my $tag_start  = quotemeta $self->tag_start;
    my $tag_end    = quotemeta $self->tag_end;
    my $cmnt_mark  = quotemeta $self->comment_mark;
    my $expr_mark  = quotemeta $self->expression_mark;

    # Tokenize
    my $state = 'text';
    my $multiline_expression = 0;
    for my $line (split /\n/, $tmpl) {

        # Perl line without return value
        if ($line =~ /^$line_start\s+(.+)$/) {
            push @{$self->tree}, ['code', $1];
            $multiline_expression = 0;
            next;
        }

        # Perl line with return value
        if ($line =~ /^$line_start$expr_mark\s+(.+)$/) {
            push @{$self->tree}, ['expr', $1];
            $multiline_expression = 0;
            next;
        }

        # Comment line, dummy token needed for line count
        if ($line =~ /^$line_start$cmnt_mark\s+(.+)$/) {
            push @{$self->tree}, [];
            $multiline_expression = 0;
            next;
        }

        # Escaped line ending?
        if ($line =~ /(\\+)$/) {
            my $length = length $1;

            # Newline escaped
            if ($length == 1) {
                $line =~ s/\\$//;
            }

            # Backslash escaped
            if ($length >= 2) {
                $line =~ s/\\\\$/\\/;
                $line .= "\n";
            }
        }

        # Normal line ending
        else { $line .= "\n" }

        # Mixed line
        my @token;
        for my $token (split /
            (
                $tag_start$expr_mark   # Expression
            |
                $tag_start$cmnt_mark   # Comment
            |
                $tag_start             # Code
            |
                $tag_end               # End
            )
        /x, $line) {

            # Garbage
            next unless $token;

            # End
            if ($token =~ /^$tag_end$/) {
                $state = 'text';
                $multiline_expression = 0;
            }

            # Code
            elsif ($token =~ /^$tag_start$/) { $state = 'code' }

            # Comment
            elsif ($token =~ /^$tag_start$cmnt_mark$/) { $state = 'cmnt' }

            # Expression
            elsif ($token =~ /^$tag_start$expr_mark$/) {
                $state = 'expr';
            }

            # Value
            else {

                # Comments are ignored
                next if $state eq 'cmnt';

                # Multiline expressions are a bit complicated,
                # only the first line can be compiled as 'expr'
                $state = 'code' if $multiline_expression;
                $multiline_expression = 1 if $state eq 'expr';

                # Store value
                push @token, $state, $token;
            }
        }
        push @{$self->tree}, \@token;
    }

    return $self;
}

sub render {
    my $self = shift;
    my $tmpl  = shift;

    # Parse
    $self->parse($tmpl);

    # Compile
    $self->compile;

    # Interpret
    return $self->interpret(@_);
}

sub render_file {
    my $self = shift;
    my $path = shift;

    # Open file
    my $file = IO::File->new;
    $file->open("< $path") || croak "Can't open template '$path': $!";

    # Slurp file
    my $tmpl = '';
    while ($file->sysread(my $buffer, 4096, 0)) {
        $tmpl .= $buffer;
    }

    # Render
    return $self->render($tmpl, @_);
}

sub render_file_to_file {
    my $self = shift;
    my $spath = shift;
    my $tpath = shift;

    # Render
    my $result = $self->render_file($spath, @_);

    # Write to file
    return $self->_write_file($tpath, $result);
}

sub render_to_file {
    my $self = shift;
    my $tmpl = shift;
    my $path = shift;

    # Render
    my $result = $self->render($tmpl, @_);

    # Write to file
    return $self->_write_file($path, $result);
}

sub _context {
    my ($self, $text, $line) = @_;

    $line     -= 1;
    my $nline  = $line + 1;
    my $pline  = $line - 1;
    my $nnline = $line + 2;
    my $ppline = $line - 2;
    my @lines  = split /\n/, $text;

    # Context
    my $context = (($line + 1) . ': ' . $lines[$line] . "\n");

    # -1
    $context = (($pline + 1) . ': ' . $lines[$pline] . "\n" . $context)
      if $lines[$pline];

    # -2
    $context = (($ppline + 1) . ': ' . $lines[$ppline] . "\n" . $context)
      if $lines[$ppline];

    # +1
    $context = ($context . ($nline + 1) . ': ' . $lines[$nline] . "\n")
      if $lines[$nline];

    # +2
    $context = ($context . ($nnline + 1) . ': ' . $lines[$nnline] . "\n")
      if $lines[$nnline];

    return $context;
}

# Debug goodness
sub _error {
    my ($self, $error) = @_;

    # No trace in production mode
    return undef unless $self->debug;

    # Line
    if ($error =~ /at\s+\(eval\s+\d+\)\s+line\s+(\d+)/) {
        my $line  = $1;
        my $delim = '-' x 76;

        my $report = "\nYa Voodoo seem weak aroun line $line, mon.\n";
        my $template = $self->_context($self->template, $line);
        $report .= "$delim\n$template$delim\n";

        # Advanced debugging
        if ($self->debug >= 2) {
            my $code = $self->_context($self->code, $line);
            $report .= "$code$delim\n";
        }

        $report .= "$error\n";
        return $report;
    }

    # No line found
    return "Voodoo error: $error";
}

sub _write_file {
    my ($self, $path, $result) = @_;

    # Write to file
    my $file = IO::File->new;
    $file->open("> $path") or croak "Can't open file '$path': $!";
    $file->syswrite($result) or croak "Can't write to file '$path': $!";
    return 1;
}

1;
__END__

=head1 NAME

Voodoo - Beware Of The Zombies!

=head1 SYNOPSIS

    use Voodoo;
    my $voodoo = Voodoo->new;

    # Simple
    print $voodoo->render(<<'EOF');
    <html>
      <head></head>
      <body>
        Time: <%= localtime(time) %>
      </body>
    </html>
    EOF

    # More complicated
    print $voodoo->render(<<'EOF', 23, 'foo bar');
    %= 5 * 5
    % my ($number, $text) = @_;
    test 123
    foo <% my $i = $number + 2 %>
    % for (1 .. 23) {
    * some text <%= $i++ %>
    % }
    EOF

=head1 DESCRIPTION

L<Voodoo> is a minimalistic and very Perl-ish template engine, designed
specifically for all those small tasks that come up during big projects.
Like preprocessing a config file, generating text from heredocs and stuff
like that.
For bigger tasks you might want to use L<HTML::Mason> or L<Template>.

    <% Inline Perl %>
    <%= Perl expression, replaced with result %>
    <%# Comment, useful for debugging %>
    % Perl line
    %= Perl expression line, replaced with result
    %# Comment line, useful for debugging

L<Voodoo> templates work just like Perl subs (actually they get compiled to a
Perl sub internally).
That means you can access arguments simply via C<@_>.

    % my ($foo, $bar) = @_;
    % my $x = shift;
    test 123 <%= $foo %>

Note that you can't escape L<Voodoo> tags, instead we just replace them if
neccessary.

    my $voodoo = Voodoo->new;
    $voodoo->line_start('@@');
    $voodoo->tag_start('[@@');
    $voodoo->tag_end('@@]');
    $voodoo->expression_mark('&');
    $voodoo->render(<<'EOF', 23);
    @@ my $i = shift;
    <% no code just text [@@& $i @@]
    EOF

There is only one case that we can escape with a backslash, and thats a
newline at the end of a template line.

   This is <%= 23 * 3 %> a\
   single line

If for some strange reason you absolutely need a backslash in front of a
newline you can escape the backslash with another backslash.

    % use Data::Dumper;
    This will\\
    result <%=  Dumper {foo => 'bar'} %>\\
    in multiple lines

Templates get compiled to Perl code internally, this can make debugging a bit
tricky.
But by setting the C<debug> attribute to C<1>, you can tell L<Voodoo> to
trace all errors that might occur and present them in a very convenient way
with context.

    Ya Voodoo seem weak aroun line 4, mon.
    -----------------------------------------------------------------
    2: </head>
    3: <body>
    4: % my $i = 2; xx
    5: %= $i * 2
    6: </body>
    -----------------------------------------------------------------
    Bareword "xx" not allowed while "strict subs" in use at (eval 13)
    line 4.

L<Voodoo> does not support caching by itself, but you can easily build a
wrapper around it.

    # Compile and store code somewhere
    my $voodoo = $voodoo->new;
    $voodoo->parse($template);
    $voodoo->compile;
    my $code = $voodoo->code;

    # Load code and template (template for debug trace only)
    $voodoo->template($template);
    $voodoo->code($code);
    my $result = $voodoo->interpret(@arguments);

=head1 ATTRIBUTES

=head2 C<code>

    my $code = $voodoo->code;
    $voodoo  = $voodoo->code($code);

=head2 C<comment_mark>

    my $comment_mark = $voodoo->comment_mark;
    $voodoo          = $voodoo->comment_mark('#');

=head2 C<debug>

    my $debug = $voodoo->debug;
    $voodoo   = $voodoo->debug(1);
    $voodoo   = $voodoo->debug(2);

=head2 C<expression_mark>

    my $expression_mark = $voodoo->expression_mark;
    $voodoo             = $voodoo->expression_mark('=');

=head2 C<line_start>

    my $line_start = $voodoo->line_start;
    $voodoo        = $voodoo->line_start('%');

=head2 C<template>

    my $template = $voodoo->template;
    $voodoo      = $voodoo->template($template);

=head2 C<tree>

    my $tree = $voodoo->tree;
    $voodoo  = $voodoo->tree($tree);

=head2 C<tag_start>

    my $tag_start = $voodoo->tag_start;
    $voodoo       = $voodoo->tag_start('<%');

=head2 C<tag_end>

    my $tag_end = $voodoo->tag_end;
    $voodoo     = $voodoo->tag_end('%>');

=head1 METHODS

L<Voodoo> inherits all methods from L<Nevermore> and implements the following
new ones.

=head2 C<new>

    my $voodoo = Voodoo->new;

=head2 C<compile>

    $voodoo = $voodoo->compile;

=head2 C<interpret>

    my $result = $voodoo->interpret;
    my $result = $voodoo->interpret(@arguments);

=head2 C<parse>

    $voodoo = $voodoo->parse($template);

=head2 C<render>

    my $result = $voodoo->render($template);
    my $result = $voodoo->render($template, @arguments);

=head2 C<renter_file>

    my $result = $voodoo->render($template_file);
    my $result = $voodoo->render($template_file, @arguments);

=head2 C<renter_file_to_file>

    my $result = $voodoo->render($template_file, $result_file);
    my $result = $voodoo->render($template_file, $result_file, @arguments);

=head2 C<renter_to_file>

    my $result = $voodoo->render($template, $result_file);
    my $result = $voodoo->render($template, $result_file, @arguments);

=cut