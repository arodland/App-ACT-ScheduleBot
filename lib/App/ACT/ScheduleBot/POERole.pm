package App::ACT::ScheduleBot::POERole;
use Moose::Role;
use POE;

requires '_start';

has bot => (
  isa => 'App::ACT::ScheduleBot',
  is => 'ro',
  weak_ref => 1,
  required => 1,
  handles => [ qw/config/ ],
);

has 'session' => (
  is => 'ro',
  isa => 'POE::Session',
  builder => '_build_session',
);

sub all_poe_states {
  my ($self) = @_;
  my @ret;
  
  for my $method (reverse Class::MOP::class_of($self)->find_all_methods_by_name('poe_states')) {
    push @ret, $method->{code}->execute($self);
  }

  return @ret;
}

sub all_poe_session_args {
  my ($self) = @_;
  my @ret;

  for my $method (reverse Class::MOP::class_of($self)->find_all_methods_by_name('poe_session_args')) {
    push @ret, $method->{code}->execute($self);
  }

  return @ret;
}

sub _build_session {
  my ($self) = @_;
  return POE::Session->create(
    object_states => [
      $self => [
        $self->all_poe_states
      ],
    ],
    $self->all_poe_session_args,
  );
}

no Moose::Role;
1;
