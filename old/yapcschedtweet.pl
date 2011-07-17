#!perl
#
use strict;
use warnings;

use POE qw/Component::IRC/;
use DateTime;
use DateTime::Format::ISO8601;
use Data::ICal;
use LWP::Simple 'get';
use Net::Twitter;

my $TZ = 'America/New_York';
my $LEADTIME = 10 * 60;
my $REFRESH_SCHED = 30 * 60;
my $CHANNEL = "#yapc";

my $ics_url = "http://www.yapc2011.us/yn2011/timetable.ics";

my $twitter = Net::Twitter->new(
  traits => [qw/OAuth API::REST RetryOnError/],
  consumer_key => 'XXX',
  consumer_secret => 'XXX',
  access_token => 'XXX',
  access_token_secret => 'XXX',
);

my $irc = POE::Component::IRC->spawn(
  nick => 'schedule',
  ircname => 'YAPC Schedule Bot',
  server => 'irc.perl.org',
  alias => 'irc', 
);

sub refresh {
  my ($kernel, $heap, $sessio) = @_[KERNEL, HEAP, SESSION];
  my $ics = get($ics_url);


  print "Loading schedule... ";

  my $parser = Data::ICal->new(data => $ics);
  my @events = @{ $parser->entries };

  print scalar @events, " events\n";
  $kernel->alarm_remove_all;
  for my $event (@events) {
    my $time = $event->property('dtstart')->[0]->value;
    my $announce = DateTime::Format::ISO8601->parse_datetime($time)->set_time_zone($TZ)->epoch() - $LEADTIME;
    next if $announce < time;
    $kernel->alarm_add(tweet => $announce, $event);
  }
  $kernel->alarm_add(refresh => time() + $REFRESH_SCHED);
}

sub tweet {
  my ($kernel, $heap, $session, $event) = @_[KERNEL, HEAP, SESSION, ARG0];
  my $tweet = to_tweet($event);
  $twitter->update($tweet);
  $kernel->post(irc => notice => $CHANNEL => to_irc($event));
  print $tweet, "\n";
}

sub to_tweet {
  my $event = shift;
  my $time = $event->property('dtstart')->[0]->value;
  my $dt = DateTime::Format::ISO8601->parse_datetime($time)->set_time_zone($TZ);
  $time = $dt->format_cldr('h:mm');
  $time .= ($dt->hour < 12) ? 'a' : 'p';
  my $speaker = $event->property('organizer') ? $event->property('organizer')->[0]->value : '';
  my $when_where = $time;
  $when_where .= ' in ' . $event->property('location')->[0]->value if $event->property('location') && $event->property('location')->[0]->value;
  my $url = $event->property('url')->[0]->value;

  my $len = length($url) + 1 + 6; # space, url, space, #yapc
  if ($speaker) {
    $len += length($speaker) + 2;
  }
  my $remain = 140 - $len;
  my $summary = $event->property('summary')->[0]->value;
  if (length $summary > $remain) {
    substr($summary, $remain - 1) = "\x{2026}";
  }

  my $pretty = $speaker ? "$speaker: " : "";
  $pretty .= "$summary $when_where $url #yapc";
  return $pretty;
}


sub to_irc {
  my $event = shift;
  my $time = $event->property('dtstart')->[0]->value;
  my $dt = DateTime::Format::ISO8601->parse_datetime($time)->set_time_zone($TZ);
  $time = $dt->format_cldr('h:mm');
  $time .= ($dt->hour < 12) ? 'a' : 'p';
  my $speaker = $event->property('organizer') ? $event->property('organizer')->[0]->value : '';
  my $when_where = $time;
  $when_where .= ' in ' . $event->property('location')->[0]->value if $event->property('location');
  my $url = $event->property('url')->[0]->value;

  my $len = length($url) + 1;
  if ($speaker) {
    $len += length($speaker) + 2;
  }
  my $remain = 140 - $len;
  my $summary = $event->property('summary')->[0]->value;
  if (length $summary > $remain) {
    substr($summary, $remain - 1) = "\x{2026}";
  }

  my $pretty = $speaker ? "$speaker: " : "";
  $pretty .= "$summary $when_where $url";
  return $pretty;
}

sub init {
  my ($kernel, $heap, $session) = @_[KERNEL, HEAP, SESSION];
  $kernel->post(irc => register => '001');
  $kernel->post(irc => connect => { });
  $kernel->yield('refresh');
}

sub irc_connected {
  my ($kernel, $heap, $session) = @_[KERNEL, HEAP, SESSION];
  $kernel->post(irc => join => $CHANNEL);
  print "Connected to IRC...\n";
}

my $session = POE::Session->create(
  inline_states => {
    tweet => \&tweet,
    refresh => \&refresh,
    irc_001 => \&irc_connected,
    _start => \&init,
  }
);

POE::Kernel->run;
