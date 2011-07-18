package App::ACT::ScheduleBot::ScheduleFetcher;
use Moose;
use LWP::Simple;
use Data::ICal;

with 'App::ACT::ScheduleBot::POERole';

sub poe_states {
  qw/refresh announce/
}

has '_alarms' => (
  is => 'ro',
  isa => 'ArrayRef',
  default => sub { [] },
  trait => ['Array'],
  handles => {
    alarms => 'elements',
    add_alarm => 'push',
  },
);

has 'last_announcement' => (
  is => 'rw',
  isa => 'Int',
  default => sub { time() },
);

sub _start {
  my ($self, $kernel) = @_[OBJECT, KERNEL];

  $kernel->yield('refresh');
}

sub refresh {
  my ($self, $kernel) = @_[OBJECT, KERNEL];

  my $schedule = $self->get_schedule;

  for my $alarm ($self->alarms) {
    $kernel->alarm_remove($alarm);
  }

  for my $event (@$schedule) {
    my $announce_time = $event->start_time - $self->config->{General}{'Announcement Lead Time'};
    next if $self->last_announcement > $announce_time;
    my $alarm = $kernel->alarm_set( announce => $announce_time, $event );
  }
}

sub announce {
  my ($self, $kernel, $event) = @_[OBJECT, KERNEL, ARG0];

  $self->bot->announce_event($event);
}

sub get_schedule {
  my ($self) = @_;
  
  my $ics_url = $self->config->{General}{'ICS URL'};
  my $ics_data = get($ics_url);

  my $parser = Data::ICal->new(data => $ics_data);
  my $entries = @{ $parser->entries };

  return map App::ACT::ScheduleBot::Event->new(ics_entry => $_) @$entries;
}

no Moose;
__PACKAGE__->meta->make_immutable;
