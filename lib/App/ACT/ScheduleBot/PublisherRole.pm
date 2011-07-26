package App::ACT::ScheduleBot::PublisherRole;
use Moose::Role;
with 'App::ACT::ScheduleBot::POERole';

sub poe_states {
  qw/_start announce_event/
}

requires '_start';
requires 'announce_event';

no Moose::Role;
1;
