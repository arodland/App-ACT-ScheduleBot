package App::ACT::ScheduleBot;

use Moose;
use DateTime;
use DateTime::Format::ISO8601;
use Data::iCal;
use LWP::Simple 'get';
use Net::Twitter;

has 'config_file' => (
  is => 'ro',
  isa => 'Str',
  required => 1,
);

has 'config' => (
  is => 'ro',
  isa => 'HashRef',
  builder => 'load_config',
);

sub load_config {
  return Config::Any->load_files( { files => [ $self->config_file ] } );
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

no Moose;
__PACKAGE__->meta->make_immutable;
