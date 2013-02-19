package App::ACT::ScheduleBot::Publisher::Twitter;
use Moose;
use Moose::Util::TypeConstraints;
use POE;
use Path::Class::File;
use Net::Twitter 3.18001;
use App::ACT::ScheduleBot::EventFormatter;

with 'App::ACT::ScheduleBot::PublisherRole';

sub BUILD {
  my ($self) = @_;
  $self->_build_twitter_credentials;
}

has 'net_twitter' => (
  is => 'ro',
  isa => 'Net::Twitter',
  lazy => 1,
  builder => '_build_net_twitter',
  handles => [
    'get_authorization_url',
    'request_access_token',
  ],
);

sub _build_net_twitter {
  my ($self) = @_;

  return $self->_twitter_from_credentials(
    $self->twitter_credentials
  );
}

sub _twitter_from_credentials {
  my ($self, $creds) = @_;

  return Net::Twitter->new(
    traits => [ qw/OAuth API::REST RetryOnError/ ],
    %$creds,
  );
}

has 'formatter' => (
  is => 'ro',
  isa => 'App::ACT::ScheduleBot::EventFormatter',
  lazy => 1,
  builder => '_build_formatter',
  handles => [qw/format_event/],
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

class_type 'Path::Class::File';
coerce 'Path::Class::File',
  from 'Str',
  via { Path::Class::File->new($_) };

has 'twitter_credential_file' => ( 
  is => 'ro',
  isa => 'Path::Class::File',
  default => sub {
    my $self = shift;
    my $filename = $self->config->{Twitter}{'Credential File'} || 'twitter.credential';
    Path::Class::File->new($self->bot->config_file)->dir->file($filename);
  },
  coerce => 1,
);

has 'twitter_credentials' => (
  is => 'rw',
  isa => 'HashRef',
  builder => '_build_twitter_credentials',
);

sub _build_twitter_credentials {
  my ($self) = @_;

  my $credential_file = $self->twitter_credential_file;
  if (-e $credential_file) {
    return $self->read_twitter_credentials($credential_file);
  } else {
    my $creds = $self->oauth_authorize;
    $self->write_twitter_credentials($credential_file, $creds);
    return $creds;
  }
}

sub read_twitter_credentials {
  my ($self, $filename) = @_;
  return Storable::retrieve($filename);
}

sub write_twitter_credentials {
  my ($self, $filename, $data) = @_;
  return Storable::nstore($data, $filename);
}

sub oauth_authorize {
  my ($self) = @_;

  print "TWITTER CONFIGURATION IS REQUIRED\n";
  my $creds = {};

  print "Enter consumer key: ";
  chomp ($creds->{consumer_key} = <STDIN>);

  print "Enter consumer key secret: ";
  chomp ($creds->{consumer_secret} = <STDIN>);

  my $twitter = $self->_twitter_from_credentials($creds);

  my $url = $twitter->get_authorization_url;
  print "Authorization URL: $url\n";
  print "Go here and authorize the request, then enter the pin below.\n";
  my $pin;

  do {
    print "PIN: ";
    chomp($pin = <STDIN>);
  } until ($pin =~ /^\d+$/);

  my ($access_token, $secret, $user_id, $username) = $twitter->request_access_token(verifier => $pin);

  print "Authorized for user $username\n";

  $creds->{access_token} = $access_token;
  $creds->{access_token_secret} = $secret;

  return $creds;
}

no Moose;
__PACKAGE__->meta->make_immutable;
