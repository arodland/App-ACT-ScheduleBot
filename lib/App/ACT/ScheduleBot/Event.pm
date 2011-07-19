package App::ACT::ScheduleBot::Event;
use Moose;
use DateTime;
use DateTime::Format::ISO8601;

has 'ics_entry' => (
  is => 'ro',
  required => 1,
  handles => [qw/start end/],
);

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
