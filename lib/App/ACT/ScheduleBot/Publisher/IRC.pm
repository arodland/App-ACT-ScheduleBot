package App::ACT::ScheduleBot::Publisher::IRC;
use Moose;
use POE qw/Component::IRC/;
with 'App::ACT::ScheduleBot::PublisherRole';

has 'poco_irc' => (
  is => 'ro',
  lazy => 1,
  builder => '_build_poco_irc',
);

sub _build_poco_irc {
  my ($self) = @_;
  return POE::Component::IRC->spawn(
    nick => $self->config->{IRC}{Nickname},
    ircname => $self->config->{IRC}{IRCName},
    server => $self->config->{IRC}{Server},
    alias => 'irc',
  );
}

has 'debug_mode' => ( 
  is => 'rw',
  isa => 'Int',
  default => 0
);

sub _start { }

sub announce_event {
  my ($self, $kernel, $event) = @_[OBJECT, KERNEL, ARG0];
  die "Unimplemented";
}

no Moose;
__PACKAGE__->meta->make_immutable;
