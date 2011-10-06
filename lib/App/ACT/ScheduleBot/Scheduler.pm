package App::ACT::ScheduleBot::Scheduler;
use Moose;
use LWP::Simple;
use POE;

with 'App::ACT::ScheduleBot::POERole';

sub poe_states {
  qw/START refresh schedule_events announce/
}

has 'debug_mode' => (
  is => 'rw',
  isa => 'Int',
  default => 0,
);

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

sub START {
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
  my ($self, $kernel, $postback_args) = @_[OBJECT, KERNEL, ARG1];
  my $schedule = $postback_args->[0];
 
  for my $alarm ($self->alarms) {
    $kernel->alarm_remove($alarm);
  }

  for my $event (@$schedule) {
    if ($self->debug_mode) {
      $kernel->yield(announce => $event);
    } else {
      my $start_time = $event->start->epoch;
      my $announce_time = $start_time - $self->config->{General}{'Announcement Lead Time'};
      next if $self->last_announcement > $announce_time;
      my $alarm = $kernel->alarm_set( announce => $announce_time, $event );
    }
  }
}

sub announce {
  my ($self, $kernel, $event) = @_[OBJECT, KERNEL, ARG0];

  $self->bot->announce_event($event);
}

no Moose;
__PACKAGE__->meta->make_immutable;
