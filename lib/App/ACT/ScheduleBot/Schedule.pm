package App::ACT::ScheduleBot::Schedule;
use Moose;
use LWP::Simple;

use Data::ICal;
use Data::ICal::DateTime;
use App::ACT::ScheduleBot::Event;

with 'App::ACT::ScheduleBot::POERole';

sub poe_states {
  qw/get_schedule/
}

sub get_schedule {
  my ($self, %args) = @_;

  my $ics_url = $self->config->{General}{'ICS URL'};
  my $ics_data = get($ics_url);

  my $parser = Data::ICal->new(data => $ics_data);
  my @entries = @{ $parser->entries };

  my $schedule = [
    map App::ACT::ScheduleBot::Event->new(ics_entry => $_),
    grep $_->isa('Data::ICal::Entry::Event'),
    @entries
  ];

  if (defined $self->config->{General}{'Schedule Offset'}) {
    for my $event (@$schedule) {
      $event->start->add(minutes => $self->config->{General}{'Schedule Offset'});
    }
  }

  if (defined $args{postback}) {
    $args{postback}->($schedule);
  } else {
    return $schedule;
  }
}

