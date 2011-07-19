package App::ACT::ScheduleBot;

use Moose;
use Config::Any;

use App::ACT::ScheduleBot::ScheduleFetcher;

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

has 'schedule_fetcher' => (
  is => 'ro',
  isa => 'App::ACT::ScheduleBot::ScheduleFetcher',
  lazy => 1,
  default => sub { 
    my ($self) = @_;
    App::ACT::ScheduleBot::ScheduleFetcher->new(
      bot => $self
    );
  },
);



no Moose;
__PACKAGE__->meta->make_immutable;
