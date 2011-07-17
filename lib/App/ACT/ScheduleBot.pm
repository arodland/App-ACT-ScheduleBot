package App::ACT::ScheduleBot;

use Any::Moose;
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

has 'net_twitter' => (
  is => 'ro',
  isa => 'Net::Twitter',
  lazy => 1,
  builder => '_build_net_twitter',
);

sub _build_net_twitter {
  return Net::Twitter->new(
    traits => [ qw/OAuth API::REST RetryOnError/ ],
    consumer_key => $self->config->{Twitter}{'Consumer Key'},
    consumer_secret => $self->config->{Twitter}{'Consumer Secret'},
    access_token => $self->config->{Twitter}{'Access Token'},
    access_token_secret => $self->config->{Twitter}{'Access Token Secret'},
  );
}

has 'poco_irc' => (
  is => 'ro',
  lazy => 1,
  builder => '_build_poco_irc',
);

sub _build_poco_irc {
  return POE::Component::IRC->spawn(
    nick => $self->config->{IRC}{Nickname},
    ircname => $self->config->{IRC}{IRCName},
    server => $self->config->{IRC}{Server},
    alias => 'irc',
  );
}

