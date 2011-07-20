package App::ACT::ScheduleBot;

use Moose;
use Config::Any;

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
  return (values $configs->[0])[0];
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
    ]
  )
}

sub _start { }

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

sub get_schedule_and_exit {
  my ($self) = @_;
  my $schedule = $self->schedule->get_schedule;
  POE::Kernel->run;
  return $schedule;
}

no Moose;
__PACKAGE__->meta->make_immutable;
