#!perl
#
use strict;
use warnings;

use Net::Twitter;

my $twitter = Net::Twitter->new(
  traits => [qw/OAuth API::REST RetryOnError/],
  consumer_key => 'XXX',
  consumer_secret => 'XXX',
);

print $twitter->get_authorization_url, "\n";
print "PIN:\n";
chomp(my $pin = <>);
my @ret = $twitter->request_access_token(verifier => $pin);
print "$_\n" for @ret;
