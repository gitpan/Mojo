#!perl

# Copyright (C) 2008, Sebastian Riedel.

use strict;
use warnings;

use Test::Mojo::Server;
use Test::More tests => 18;

use File::Spec::Functions qw/catfile splitdir/;
use FindBin;

# When I held that gun in my hand, I felt a surge of power...
# like God must feel when he's holding a gun.
use_ok('Voodoo');

# All tags
my $voodoo = Voodoo->new;
$voodoo->parse(<<'EOF');
<html foo="bar">
<%= $_[0] + 1 %> test <%= 2 + 2 %> lala <%# comment lalala %>
%# This is a comment!
% my $i = 2;
%= $i * 2
%
</html>
EOF
$voodoo->compile;
is($voodoo->interpret(2), "<html foo=\"bar\">\n3 test 4 lala \n4\%\n</html>\n");

# Arguments
$voodoo = Voodoo->new;
is($voodoo->render(<<'EOF', 'test', {foo => 'bar'}), "<html>\ntest bar</html>\n");
% my $message = shift;
<html><% my $hash = $_[0]; %>
%= $message . ' ' . $hash->{foo}
</html>
EOF

# Ugly multiline loop
$voodoo = Voodoo->new;
is($voodoo->render(<<'EOF'), "<html>1234</html>\n");
% my $nums = '';
<html><% for my $i (1..4) {
    $nums .= "$i";
} %><%= $nums%></html>
EOF

# Clean multiline loop
$voodoo = Voodoo->new;
is($voodoo->render(<<'EOF'), "<html>\n1234</html>\n");
<html>
%  for my $i (1..4) {
%=    $i
%  }
</html>
EOF

# Escaped line ending
$voodoo = Voodoo->new;
is($voodoo->render(<<'EOF'), "<html>2222</html>\\\\\\\n");
<html>\
%= '2' x 4
</html>\\\\
EOF

# Multiline comment
$voodoo = Voodoo->new;
is($voodoo->render(<<'EOF'), "<html>this not\n1234</html>\n");
<html><%# this is
a
comment %>this not
%  for my $i (1..4) {
%=    $i
%  }
</html>
EOF

# Oneliner
$voodoo = Voodoo->new;
is($voodoo->render('<html><%= 3 * 3 %></html>\\'), '<html>9</html>');

# Different line start
$voodoo = Voodoo->new;
$voodoo->line_start('$');
is($voodoo->render(<<'EOF'), "<html>2222</html>\\\\\\\n");
<html>\
$= '2' x 4
</html>\\\\
EOF

# Multiline expression
$voodoo = Voodoo->new;
is($voodoo->render(<<'EOF'), "<html>2222</html>");
<html><%= do { my $i = '2';
$i x 4; } %>\
</html>\
EOF

# Different tags and line start
$voodoo = Voodoo->new;
$voodoo->tag_start('[$-');
$voodoo->tag_end('-$]');
$voodoo->line_start('$-');
is($voodoo->render(<<'EOF', 'test', {foo => 'bar'}), "<html>\ntest bar</html>\n");
$- my $message = shift;
<html>[$- my $hash = $_[0]; -$]
$-= $message . ' ' . $hash->{foo}
</html>
EOF

# Different expression and comment marks
$voodoo = Voodoo->new;
$voodoo->comment_mark('@@@');
$voodoo->expression_mark('---');
is($voodoo->render(<<'EOF', 'test', {foo => 'bar'}), "<html>\ntest bar</html>\n");
% my $message = shift;
<html><% my $hash = $_[0]; %><%@@@ comment lalala %>
%--- $message . ' ' . $hash->{foo}
</html>
EOF

# File
$voodoo = Voodoo->new;
is($voodoo->render_file(
    catfile(splitdir($FindBin::Bin), qw/lib test.voodoo/), 3),
    "23Hello World!\n"
);

# File to file
my $server = Test::Mojo::Server->new;
$server->mk_tmpdir_ok;
$voodoo = Voodoo->new;
$voodoo->tag_start('[$-');
$voodoo->tag_end('-$]');
my $tmpfile = catfile $server->tmpdir, 'test.voodoo';
is($voodoo->render_to_file(<<'EOF', $tmpfile), 1);
<% my $i = 23 %> foo bar
baz <%= $i %>
test
EOF
$voodoo = Voodoo->new;
is($voodoo->render_file_to_file($tmpfile, "$tmpfile.2"), 1);
$voodoo = Voodoo->new;
is($voodoo->render_file("$tmpfile.2"), " foo bar\nbaz 23\ntest\n");
$server->rm_tmpdir_ok;