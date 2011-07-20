package App::ACT::ScheduleBot::Event;
use Moose;
use DateTime;
use DateTime::Format::ISO8601;

has 'ics_entry' => (
  is => 'ro',
  required => 1,
);

for my $prop (qw/start end/) {
  has $prop => (
    is => 'ro',
    isa => 'DateTime',
    lazy => 1,
    default => sub { shift->build_datetime($prop) },
  );
}

for my $prop (qw/organizer location url summary tzid/) {
  has $prop => (
    is => 'ro',
    isa => 'Str',
    lazy => 1,
    default => sub { shift->build_strval($prop) },
  );
}

sub get_property {
  my ($self, $propname) = @_;

  my $prop = $self->ics_entry->property($propname);
  return unless defined $prop;
  die "Unknown prop type ", ref($prop) unless  ref($prop) eq 'ARRAY';
  $prop = $prop->[0];
  return $prop;
}

sub get_prop_value {
  my ($self, $propname) = @_;
  
  my $prop = $self->get_property($propname);
  return unless defined $prop;
  return $prop->value;
}

sub build_datetime {
  my ($self, $propname) = @_;

  my $prop = $self->get_property($propname);
  my $dt = $prop->value;
  my $time_zone = $prop->parameters->{TZID};

  if (defined $time_zone) {
    $dt->set_time_zone($time_zone);
  }
  return $dt;
}

no Moose;
__PACKAGE__->meta->make_immutable;
