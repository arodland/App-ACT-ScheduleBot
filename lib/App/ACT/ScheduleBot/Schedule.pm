package App::ACT::ScheduleBot::Schedule;
use Moose;
use LWP::Simple;
use Encode ();

use Data::ICal;
use Data::ICal::DateTime;
use Text::xSV;
use App::ACT::ScheduleBot::Event;

with 'App::ACT::ScheduleBot::POERole';

sub poe_states {
  qw/get_schedule/
}

sub get_schedule {
  my ($self, %args) = @_;

  my $schedule;

  if (my $ics_url = $self->config->{General}{'ICS URL'}) {
	  my $ics_data = get($ics_url);

	  my $parser = Data::ICal->new(data => $ics_data);
	  my @entries = @{ $parser->entries };

	  $schedule = [
	    map App::ACT::ScheduleBot::Event->new(ics_entry => $_),
	    grep $_->isa('Data::ICal::Entry::Event'),
	    @entries
	  ];
  } elsif (my $csv_url = $self->config->{General}{'CSV URL'}) {
    my $csv_data = get($csv_url);
    $csv_data = Encode::encode('UTF-8', $csv_data);
    open my $fh, '<', \$csv_data;
    my $xsv = Text::xSV->new(fh => $fh);
    $xsv->read_header;
    while ($xsv->get_row) {
      my $row = $xsv->extract_hash;
      push @$schedule, App::ACT::ScheduleBot::Event->new(csv_entry => $row);
    }
  } else {
    die "No CSV or ICS";
  }

  if (defined $self->config->{General}{'Schedule Offset'}) {
    for my $event (@$schedule) {
      $event->start->add(minutes => $self->config->{General}{'Schedule Offset'});
    }
  }

  if (defined $args{postback}) {
    $args{postback}->($schedule);
  } else {
    return $schedule;
  }
}

