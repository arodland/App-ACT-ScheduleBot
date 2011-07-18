package App::ACT::ScheduleBot::PublisherRole;
use Moose::Role;
use POE;

requires 'startup';
requires 'publish_event';

has 'session' => (
  is => 'ro',
  isa => 'POE::Session',
  builder => '_build_session',
);

has 'extra_states' => (
  is => 'ro',
  isa => 'ArrayRef',
  default => sub { [] },
);

has 'extra_session_args' => (
  is => 'ro',
  isa => 'HashRef'.
  default => sub { +{} },
);

sub _build_session {
  my ($self) = @_;
  return POE::Session->create(
    object_states => [
      $self => [
        qw/startup publish_event/,
        @{ $self->extra_states },
      ],
    ],
    %{ $self->extra_session_args },
  );
}

no Moose::Role;
1;
