package App::ACT::ScheduleBot::IRCer;
use Moose;

use POE qw/Component::IRC/;

has bot => (
  isa => 'App::ACT::ScheduleBot',
  is => 'ro',
  required => 1,
  handles => [ qw/config/ ],
);

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

has 'session' => (
  is => 'ro',
  isa => 'POE::Session',
  builder => '_build_session',
);

sub _build_session {
  my ($self) = @_;
  return POE::Session->create(
    object_states => [
      $self => [ qw/startup publish_event/ ],
    ]
  );
}

sub startup { }

sub publish_event {
  my ($self, $kernel, $event) = @_[OBJECT, KERNEL, ARG0];
  die "Unimplemented";
}

no Moose;
__PACKAGE__->meta->make_immutable;
