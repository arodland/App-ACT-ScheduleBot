use inc::Module::Install;

name 'App-ACT-ScheduleBot';
all_from 'lib/App/ACT/ScheduleBot.pm';

requires(
  'Moose'                     => 0,
  'Data::ICal'                => 0,
  'DateTime'                  => 0,
  'DateTime::Format::ISO8601' => 0,
  'LWP::Simple'               => 0,
  'Net::Twitter'              => 0,
  'POE'                       => 0,
  'POE::Component::IRC'       => 0,
  'Config::Any'               => 0,
  'Config::Tiny'              => 0,
  'Data::ICal::DateTime'      => 0,
);

#install_script 'bin/act_schedulebot.pl';
auto_install;
WriteAll;
