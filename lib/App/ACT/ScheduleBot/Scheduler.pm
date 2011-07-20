package App::ACT::ScheduleBot::Scheduler;
use Moose;
use LWP::Simple;
use Data::ICal;
use Data::ICal::DateTime;
use App::ACT::ScheduleBot::Event;
use POE;

with 'App::ACT::ScheduleBot::POERole';

sub poe_states {
  qw/_start refresh schedule_events announce/
}

has '_alarms' => (
  is => 'ro',
  isa => 'ArrayRef',
  default => sub { [] },
  traits => ['Array'],
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
  my ($self, $kernel, $session) = @_[OBJECT, KERNEL, SESSION];

  $self->bot->schedule->get_schedule(
    postback => $session->postback("schedule_events")
  );
}

sub schedule_events {
  my ($self, $kernel, $schedule) = @_[OBJECT, KERNEL, ARG0];

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
  my @entries = @{ $parser->entries };

  return
    map App::ACT::ScheduleBot::Event->new(ics_entry => $_), 
    grep $_->isa('Data::ICal::Entry::Event'), 
    @entries;
}

no Moose;
__PACKAGE__->meta->make_immutable;
