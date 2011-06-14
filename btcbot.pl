#!/usr/bin/env perl

use common::sense;
use WebService::MtGox;
use Data::Dump 'pp';

my $user;
my $password;

if (not -e "$ENV{HOME}/.mgrc") {
print qq{Config file not found.

To get started, you need to add your mtgox.com login credentials
to a file that only you can read like this:

  echo username >  ~/.mgrc
  echo password >> ~/.mgrc
  chmod 0400 ~/.mgrc

Of course, you should replace username and password with your
own credentials.

To get started, run:

  mg help

};
exit 1;
} else {
  open my $fh, '<', "$ENV{HOME}/.mgrc" or die $!;
  ($user, $password) = map { chomp; $_ } <$fh>;
}

sub sei { print @_, "\n" }

# Super simple strategy:
# * If I have existing pending trades, do nothing
# * Otherwise, put in a pair of trades
# ** One a buy, $0.5 lower than the current going price
# ** One a sell, $0.5 higher than the current going price
#
# In theory, the price will fluctuate more than that. If the price goes down
# and stays down, then we'll never execute the 'sell'. If the price goes up and
# stays up, we'd never execute the 'buy'. Either way, this bot won't spiral
# down to zero. It won't grow much either though :)
#
# I stuck this into a cronjob running every 5 minutes

my $spread = 0.5; # Place orders +/- this amount around the current price
my $amount = 0.1; # Place orders for this amount

my $m = WebService::MtGox->new(
  user     => $user,
  password => $password,
);

print `date`;
my $trades = $m->list;
my $orders = $trades->{orders};
if(@$orders) {
  print "existing orders!\n";
  exit;
}

my $ticker = $m->get_ticker;
sei pp($ticker);
my $buy = $ticker->{ticker}{buy} - $spread;
my $sell = $ticker->{ticker}{sell} + $spread;
print "buy: $buy\tsell: $sell\n";

# Place the actual orders
my $b = $m->buy(amount => $amount, price => $buy);
my $s = $m->sell(amount => $amount, price => $sell);

sei pp($b);
sei pp($s);

