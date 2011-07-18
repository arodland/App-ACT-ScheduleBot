package App::ACT::ScheduleBot::PublisherRole;
use Moose::Role;
with 'App::ACT::ScheduleBot::POERole';

sub poe_states {
  'publish_event'
}

requires 'publish_event';

no Moose::Role;
1;
