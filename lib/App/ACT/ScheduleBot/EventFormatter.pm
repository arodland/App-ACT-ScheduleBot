package App::ACT::ScheduleBot::EventFormatter;
use Moose;

has 'max_length' => (
  is => 'ro',
  isa => 'Int',
  required => 1,
);

has suffix => (
  is => 'ro',
  isa => 'Str',
  default => '',
);

sub format_event {
  my ($self, $event) = @_;

  my $speaker = $event->organizer;
  my $leading = defined $speaker ? "$speaker: " : "";

  my $dt = $event->start;
  my $time = $dt->format_cldr('h:mm');
  $time .= ($dt->hour < 12) ? 'a' : 'p';

  my $when_where = $time;
  $when_where .= ' in ' . $event->location if defined $event->location;

  my $url = $event->url;
  my $suffix = $self->suffix;
  my $trailing = " $when_where $url";
  if (length $suffix) {
    $trailing .= " $suffix";
  }

  my $avail = $self->max_length() - length($leading) - length($trailing);
  my $summary = $event->summary;

  if (length $summary > $avail) {
    substr($summary, $avail - 1) = "\x{2026}"; # one-char ellipsis
  }

  return $leading . $summary . $trailing;
}

no Moose;
__PACKAGE__->meta->make_immutable;
