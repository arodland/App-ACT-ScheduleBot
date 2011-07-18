package App::ACT::ScheduleBot::Tweeter;
use Moose;

use POE;
use Net::Twitter;

has bot => (
  isa => 'App::ACT::ScheduleBot',
  is => 'ro',
  required => 1,
  handles => [ qw/config/ ],
);

has 'net_twitter' => (
  is => 'ro',
  isa => 'Net::Twitter',
  lazy => 1,
  builder => '_build_net_twitter',
);

sub _build_net_twitter {
  return Net::Twitter->new(
    traits => [ qw/OAuth API::REST RetryOnError/ ],
    consumer_key => $self->config->{Twitter}{'Consumer Key'},
    consumer_secret => $self->config->{Twitter}{'Consumer Secret'},
    access_token => $self->config->{Twitter}{'Access Token'},
    access_token_secret => $self->config->{Twitter}{'Access Token Secret'},
  );
}

has 'session' => (
  is => 'ro',
  isa => 'POE::Session',
  builder => '_build_session',
);

sub _build_session {
  my ($self) = @_;
  return POE::Session->create(
    object_states => [
      $self => [ qw/startup publish_event/ ],
    ]
  );
}

sub publish_event {
  my ($self, $kernel, $event) = @_[OBJECT, KERNEL, ARG0];
  die "Unimplemented";
}

no Moose;
__PACKAGE__->meta->make_immutable;
