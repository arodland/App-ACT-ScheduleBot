package App::ACT::ScheduleBot::Publisher::IRC;
use Moose;
use POE qw/Component::IRC/;
use App::ACT::ScheduleBot::EventFormatter;

with 'App::ACT::ScheduleBot::PublisherRole';

sub poe_states { 
  qw/START irc_001/
}

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

has 'formatter' => (
  is => 'ro',
  isa => 'App::ACT::ScheduleBot::EventFormatter',
  lazy => 1,
  builder => '_build_formatter',
  handles => [qw/format_event/],
);

sub _build_formatter {
  my ($self) = @_;
  return App::ACT::ScheduleBot::EventFormatter->new(
    max_length => 200,
  );
}

has 'debug_mode' => ( 
  is => 'rw',
  isa => 'Int',
  default => 0
);

sub START {
  my ($self, $kernel) = @_[OBJECT, KERNEL];
  unless ($self->debug_mode) {
    $self->poco_irc;
    $kernel->post(irc => register => '001');
    $kernel->post(irc => connect => { });
  }
}

sub irc_001 {
  my ($self, $kernel) = @_[OBJECT, KERNEL];
  $kernel->post(irc => join => $self->config->{IRC}{Channel});
  print STDERR "Connected to IRC\n";
}

sub announce_event {
  my ($self, $kernel, $event) = @_[OBJECT, KERNEL, ARG0];
  my $formatted = $self->format_event($event, 'irc');
  print STDERR "  IRC: $formatted\n";
  if (!$self->debug_mode) {
    $kernel->post( irc => notice => $self->config->{IRC}{Channel} => $formatted );
  }
}

no Moose;
__PACKAGE__->meta->make_immutable;
