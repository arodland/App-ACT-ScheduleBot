package App::ACT::ScheduleBot::Event;
use Moose;
use DateTime;
use DateTime::Format::ISO8601;
use WWW::Shorten qw(TinyURL :short);

has 'ics_entry' => (
  is => 'ro',
  predicate => 'has_ics_entry',
);

has 'csv_entry' => (
  is => 'ro',
  predicate => 'has_csv_entry',
);

sub BUILD {
  my ($self) = @_;
  die "No ICS or CSV entry" unless $self->has_ics_entry or $self->has_csv_entry;
}

my %map = (
    organizer => 'Name',
    location => 'Track',
    summary => 'Title',
);

for my $prop (qw/start end/) {
  has $prop => (
    is => 'ro',
    isa => 'DateTime',
    lazy => 1,
    default => sub { shift->build_start_time },
  );
}

for my $prop (qw/organizer location summary tzid/) {
  has $prop => (
    is => 'ro',
    isa => 'Maybe[Str]',
    lazy => 1,
    default => sub { shift->build_strval($prop) },
  );
}

has 'url' => (
  is => 'ro',
  isa => 'Maybe[Str]',
  lazy => 1,
  default => sub { shift->build_url },
);

has 'short_url' => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->build_short_url },
);

sub get_property {
  my ($self, $propname) = @_;

  my $prop = $self->ics_entry->property($propname);
  die "Unknown prop type ", ref($prop) unless  ref($prop) eq 'ARRAY';
  $prop = $prop->[0];
  return $prop;
}

sub get_prop_value {
  my ($self, $propname) = @_;
  
  if ($self->has_ics_entry) {
    my $prop = $self->get_property($propname);
    return unless defined $prop;
    return $prop->value;
  } else {
    my $prop = $self->csv_entry->{ $map{$propname} };
    return $prop;
  }
}

sub build_start_time {
  my ($self, $propname) = @_;

  if ($self->has_ics_entry) {
    my $prop = $self->get_property("dtstart");
    my $dt = DateTime::Format::ISO8601->parse_datetime($prop->value);
    my $time_zone = $prop->parameters->{TZID};

    if (defined $time_zone) {
      $dt->set_time_zone($time_zone);
    }
    return $dt;
  } elsif ($self->has_csv_entry) {
    my $day = $self->csv_entry->{Day};
    my $time = $self->csv_entry->{Time};
    my $iso = sprintf "%sT%s:00", $day, $time;
    my $dt = DateTime::Format::ISO8601->parse_datetime($iso);
    $dt->set_time_zone('America/New_York');
    return $dt;
  }

}

sub build_strval {
  my ($self, $propname) = @_;

  return $self->get_prop_value($propname);
}

sub build_url {
  my ($self) = @_;
  if ($self->has_ics_entry) {
    return $self->build_strval('url');
  } else {
    my $title = $self->summary;
    $title = lc $title;
    $title =~ tr/a-z0-9/_/cs;
    return "http://www.perlconference.us/tpc-2017-dc/talks/#$title";
    return $title;
  }
}

sub build_short_url {
  my ($self) = @_;

  return short_link($self->url);
}

no Moose;
__PACKAGE__->meta->make_immutable;
