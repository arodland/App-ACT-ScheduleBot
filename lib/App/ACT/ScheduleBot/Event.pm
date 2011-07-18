package App::ACT::ScheduleBot::Event;
use Moose;
use DateTime;
use DateTime::Format::ISO8601;

has 'ics_entry' => (
  is => 'ro',
  isa => 'HashRef',
  required => 1,
);

for my $prop (qw/dtstart dtend/) {
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

no Moose;
__PACKAGE__->meta->make_immutable;
