package App::ACT::ScheduleBot::Publisher::Twitter;
use Moose;
use POE;
use Net::Twitter 3.18001;
use App::ACT::ScheduleBot::EventFormatter;

with 'App::ACT::ScheduleBot::PublisherRole';

has 'net_twitter' => (
  is => 'ro',
  isa => 'Net::Twitter',
  lazy => 1,
  builder => '_build_net_twitter',
);

sub _build_net_twitter {
  my ($self) = @_;
  return Net::Twitter->new(
    traits => [ qw/OAuth API::REST RetryOnError/ ],
    consumer_key => $self->config->{Twitter}{'Consumer Key'},
    consumer_secret => $self->config->{Twitter}{'Consumer Secret'},
    access_token => $self->config->{Twitter}{'Access Token'},
    access_token_secret => $self->config->{Twitter}{'Access Token Secret'},
  );
}

has 'formatter' => (
  is => 'ro',
  isa => 'App::ACT::ScheduleBot::EventFormatter',
  lazy => 1,
  builder => '_build_formatter',
  handles => [qw/format_event/],
);

has 'twitter_conf' => (
  is => 'ro',
  isa => 'HashRef',
  lazy => 1,
  default => sub { shift->net_twitter->get_configuration },
);

sub _build_formatter {
  my ($self) = @_;

  return App::ACT::ScheduleBot::EventFormatter->new(
    max_length => 140,
    suffix => $self->config->{Twitter}{Hashtags} || '',
    short_url_length => $self->twitter_conf->{short_url_length},
    short_url_length_https => $self->twitter_conf->{short_url_length_https},
  );
}

has 'debug_mode' => ( 
  is => 'rw',
  isa => 'Int',
  default => 0
);

sub announce_event {
  my ($self, $kernel, $event) = @_[OBJECT, KERNEL, ARG0];
  my $formatted = $self->format_event($event);
  print STDERR "Tweet: $formatted\n";
  if (!$self->debug_mode) {
    eval {
      $self->net_twitter->update($formatted);
    };
    if ($@) {
      print STDERR "Error tweeting: $@\n";
    }
  }
}

no Moose;
__PACKAGE__->meta->make_immutable;
