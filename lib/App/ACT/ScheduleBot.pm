package App::ACT::ScheduleBot;

use Moose;
use Config::Any;

#sub POE::Kernel::TRACE_EVENTS () { 1 }
#sub POE::Kernel::TRACE_SESSIONS () { 1 }
#sub POE::Kernel::TRACE_REFCNT () { 1 }

use POE;
use App::ACT::ScheduleBot::Schedule;
use App::ACT::ScheduleBot::Scheduler;

has 'config_file' => (
  is => 'ro',
  isa => 'Str',
  required => 1,
);

has 'config' => (
  is => 'ro',
  isa => 'HashRef',
  lazy => 1,
  builder => 'load_config',
);

sub load_config {
  my ($self) = @_;
  my $configs = Config::Any->load_files(
    {
      files => [ $self->config_file ],
      use_ext => 1,
    }
  );
  return (values %{$configs->[0]})[0];
}

has 'session' => (
  is => 'ro',
  isa => 'POE::Session',
  builder => '_build_session',
);

sub _build_session {
  my ($self) = @_;
  return POE::Session->create(
    object_states => [
      $self => [ qw/_start/ ],
    ],
  )
}

sub _start {
  my ($self, $kernel) = @_[OBJECT, KERNEL];
  $kernel->alias_set("$self");
}

has '_publishers' => (
  is => 'ro',
  isa => 'ArrayRef',
  traits => ['Array'],
  default => sub { [] },
  handles => {
    publishers => 'elements',
    add_publisher => 'push',
  },
);

has 'schedule' => (
  is => 'ro',
  isa => 'App::ACT::ScheduleBot::Schedule',
  lazy => 1,
  default => sub { 
    my ($self) = @_;
    App::ACT::ScheduleBot::Schedule->new(
      bot => $self
    );
  },
);

has 'scheduler' => (
  is => 'ro',
  isa => 'App::ACT::ScheduleBot::Scheduler',
  lazy => 1,
  default => sub { 
    my ($self) = @_;
    App::ACT::ScheduleBot::Scheduler->new(
      bot => $self
    );
  },
);

sub BUILD {
  my ($self) = @_;

  if ($self->config->{Twitter}{Enabled}) {
    Class::MOP::load_class('App::ACT::ScheduleBot::Publisher::Twitter');
    $self->add_publisher(App::ACT::ScheduleBot::Publisher::Twitter->new(bot => $self));
  }

  if ($self->config->{IRC}{Enabled}) {
    Class::MOP::load_class('App::ACT::ScheduleBot::Publisher::IRC');
    $self->add_publisher(App::ACT::ScheduleBot::Publisher::IRC->new(bot => $self));
  }
}

sub get_schedule_and_exit {
  my ($self) = @_;
  $_->debug_mode(1) for $self->publishers;
  my $schedule = $self->schedule->get_schedule;
  POE::Kernel->run;
  return $schedule;
}

sub test_run {
  my ($self) = @_;
  $self->scheduler->debug_mode(1);
  $_->debug_mode(1) for $self->publishers;
  POE::Kernel->run;
}

sub run_to_stdout {
  my ($self) = @_;
  $_->debug_mode(1) for $self->publishers;
  $self->scheduler;
  POE::Kernel->run;
}

sub run {
  my ($self) = @_;
  $self->scheduler;
  POE::Kernel->run;
}

sub announce_event {
  my ($self, $event) = @_;

  for my $publisher ($self->publishers) {
    $publisher->post('announce_event' => $event);
  }
}

no Moose;
__PACKAGE__->meta->make_immutable;
