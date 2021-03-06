package Mojo;
use Mojo::Base -base;

# "Professor: These old Doomsday devices are dangerously unstable. I'll rest
#             easier not knowing where they are."
use Carp 'croak';
use Mojo::Home;
use Mojo::Log;
use Mojo::Transaction::HTTP;
use Mojo::UserAgent;
use Mojo::Util;
use Scalar::Util 'weaken';

has home => sub { Mojo::Home->new };
has log  => sub { Mojo::Log->new };
has ua   => sub {
  my $ua = Mojo::UserAgent->new;
  weaken $ua->server->app(shift)->{app};
  return $ua;
};

sub build_tx { Mojo::Transaction::HTTP->new }

sub config { Mojo::Util::_stash(config => @_) }

sub handler { croak 'Method "handler" not implemented in subclass' }

sub new {
  my $self = shift->SUPER::new(@_);

  # Check if we have a log directory
  my $home = $self->home;
  $home->detect(ref $self) unless @{$home->parts};
  $self->log->path($home->rel_file('log/mojo.log'))
    if -w $home->rel_file('log');

  return $self;
}

1;

=encoding utf8

=head1 NAME

Mojo - Duct tape for the HTML5 web!

=head1 SYNOPSIS

  package MyApp;
  use Mojo::Base 'Mojo';

  # All the complexities of CGI, PSGI, HTTP and WebSockets get reduced to a
  # single method call!
  sub handler {
    my ($self, $tx) = @_;

    # Request
    my $method = $tx->req->method;
    my $path   = $tx->req->url->path;

    # Response
    $tx->res->code(200);
    $tx->res->headers->content_type('text/plain');
    $tx->res->body("$method request for $path!");

    # Resume transaction
    $tx->resume;
  }

=head1 DESCRIPTION

A flexible runtime environment for Perl real-time web frameworks, with all the
basic tools and helpers needed to write simple web applications and higher
level web frameworks, such as L<Mojolicious>.

See L<Mojolicious::Guides> for more!

=head1 ATTRIBUTES

L<Mojo> implements the following attributes.

=head2 home

  my $home = $app->home;
  $app     = $app->home(Mojo::Home->new);

The home directory of your application, defaults to a L<Mojo::Home> object
which stringifies to the actual path.

  # Generate portable path relative to home directory
  my $path = $app->home->rel_file('data/important.txt');

=head2 log

  my $log = $app->log;
  $app    = $app->log(Mojo::Log->new);

The logging layer of your application, defaults to a L<Mojo::Log> object.

  # Log debug message
  $app->log->debug('It works!');

=head2 ua

  my $ua = $app->ua;
  $app   = $app->ua(Mojo::UserAgent->new);

A full featured HTTP user agent for use in your applications, defaults to a
L<Mojo::UserAgent> object.

  # Perform blocking request
  say $app->ua->get('example.com')->res->body;

=head1 METHODS

L<Mojo> inherits all methods from L<Mojo::Base> and implements the following
new ones.

=head2 build_tx

  my $tx = $app->build_tx;

Transaction builder, defaults to building a L<Mojo::Transaction::HTTP>
object.

=head2 config

  my $hash = $app->config;
  my $foo  = $app->config('foo');
  $app     = $app->config({foo => 'bar'});
  $app     = $app->config(foo => 'bar');

Application configuration.

  # Remove value
  my $foo = delete $app->config->{foo};

=head2 handler

  $app->handler(Mojo::Transaction::HTTP->new);

The handler is the main entry point to your application or framework and will
be called for each new transaction, which will usually be a
L<Mojo::Transaction::HTTP> or L<Mojo::Transaction::WebSocket> object. Meant to
be overloaded in a subclass.

  sub handler {
    my ($self, $tx) = @_;
    ...
  }

=head2 new

  my $app = Mojo->new;

Construct a new L<Mojo> application. Will automatically detect your home
directory if necessary and set up logging to C<log/mojo.log> if there's a
C<log> directory.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
