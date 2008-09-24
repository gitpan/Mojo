# Copyright (C) 2008, Sebastian Riedel.

package Curse::Date;

use strict;
use warnings;

use base 'Nevermore';
use overload '""' => sub { shift->as_string }, fallback => 1;

require Time::Local;

__PACKAGE__->attr('epoch', chained => 1);

sub new {
    my $self = shift->SUPER::new();
    $self->parse(@_);
    return $self;
}

# I suggest you leave immediately.
# Or what? You'll release the dogs or the bees?
# Or the dogs with bees in their mouths and when they bark they shoot bees at
# you?
sub as_string {
    my $self = shift;
    my $epoch = shift || $self->{epoch} || time;

    my ($second, $minute, $hour, $mday, $month, $year, $wday)
      = gmtime $epoch;

    my $days   = [qw/Sun Mon Tue Wed Thu Fri Sat/];
    my $months = [qw/Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/];

    # Format
    return sprintf("%s, %02d %s %04d %02d:%02d:%02d GMT", $days->[$wday],
      $mday, $months->[$month], $year+1900, $hour, $minute, $second);
}

sub parse {
    my ($self, $date) = @_;

    $self = $self->new unless ref $self;

    # Shortcut
    return unless $date;

    # epoch - 784111777
    if ($date =~ /^\d+$/) {
        $self->epoch($date);
        return $self;
    }

    # Remove spaces, weekdays and timezone
    $date =~ s/^\s+//;
    $date =~ s/^(?:Sun|Mon|Tue|Wed|Thu|Fri|Sat)[a-z]*,?\s*//i;
    $date =~ s/GMT\s*$//i;
    $date =~ s/\s+$//;

    my ($day, $month, $year, $hour, $minute, $second);
    my $months = {};
    my $i      = 0;
    for my $m (qw/Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/) {
        $months->{$m} = $i;
        $i++;
    }

    # RFC822/1123 - Sun, 06 Nov 1994 08:49:37 GMT
    if ($date =~ /^(\d+)\s+(\w+)\s+(\d+)\s+(\d+):(\d+):(\d+)$/) {
        $day    = $1;
        $month  = $months->{$2} || 1;
        $year   = $3;
        $hour   = $4;
        $minute = $5;
        $second = $6;
    }

    # RFC850/1036 - Sunday, 06-Nov-94 08:49:37 GMT
    elsif ($date =~ /^(\d+)-(\w+)-(\d+)\s+(\d+):(\d+):(\d+)$/) {
        $day    = $1;
        $month  = $months->{$2} || 1;
        $year   = $3;
        $hour   = $4;
        $minute = $5;
        $second = $6;
    }

    # ANSI C asctime() - Sun Nov  6 08:49:37 1994
    elsif ($date =~ /^(\w+)\s+(\d+)\s+(\d+):(\d+):(\d+)\s+(\d+)$/) {
        $month  = $months->{$1} || 1;
        $day    = $2;
        $hour   = $3;
        $minute = $4;
        $second = $5;
        $year   = $6;
    }

    # Invalid format
    else { return undef }
    
    $self->epoch(
      Time::Local::timegm($second, $minute, $hour, $day, $month, $year));
    return $self;
}

1;
__END__

=head1 NAME

Curse::Date - HTTP Dates

=head1 SYNOPSIS

    use Curse::Date;

    my $date = Curse::Date->new(784111777);
    my $http_date = $date->as_string;
    $date->parse('Sun, 06 Nov 1994 08:49:37 GMT');
    my $epoch = $date->epoch;

=head1 DESCRIPTION

L<Curse::Date> implements HTTP date and time functions according to RFC2616.

    Sun, 06 Nov 1994 08:49:37 GMT  ; RFC 822, updated by RFC 1123
    Sunday, 06-Nov-94 08:49:37 GMT ; RFC 850, obsoleted by RFC 1036
    Sun Nov  6 08:49:37 1994       ; ANSI C's asctime() format

=head1 ATTRIBUTES

=head2 C<epoch>

    my $epoch = $date->epoch;
    $date     = $date->epoch(time);

=head1 METHODS

L<Curse::Date> inherits all methods from L<Nevermore> and implements the
following new ones.

=head2 C<new>

    my $date = Curse::Date->new($string);

=head2 C<as_string>

    my $http_date = $date->as_string;

=head2 C<parse>

    $date = $date->parse('Sun Nov  6 08:49:37 1994');

=cut