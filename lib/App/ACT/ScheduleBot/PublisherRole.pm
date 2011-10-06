package App::ACT::ScheduleBot::PublisherRole;
use Moose::Role;
with 'App::ACT::ScheduleBot::POERole';

sub poe_states {
  qw/announce_event/
}

requires 'announce_event';

no Moose::Role;
1;
