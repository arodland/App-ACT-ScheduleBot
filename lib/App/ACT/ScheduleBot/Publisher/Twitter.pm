package App::ACT::ScheduleBot::Publisher::Twitter;
use Moose;
use POE;
use Net::Twitter;
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

has 'debug_mode' => ( 
  is => 'rw',
  isa => 'Int',
  default => 0
);

sub _start { }

sub announce_event {
  my ($self, $kernel, $event) = @_[OBJECT, KERNEL, ARG0];
  die "Unimplemented";
}

no Moose;
__PACKAGE__->meta->make_immutable;
