use inc::Module::Install;
cpanfile;

name 'App-ACT-ScheduleBot';
all_from 'lib/App/ACT/ScheduleBot.pm';

#install_script 'bin/schedulebot';
auto_install;
WriteAll;
