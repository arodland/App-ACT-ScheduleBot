package App::ACT::ScheduleBot::PublisherRole;
use Moose::Role;
with 'App::ACT::ScheduleBot::POERole';

sub poe_states { }

around poe_states => sub {
  my ($orig, $self) = @_;
  return ($self->$orig(), 'announce_event');
};

requires 'announce_event';

no Moose::Role;
1;
