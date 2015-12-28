use Test::More;
use Feed::PhaseCheck qw(compare_feeds);
use strict;
use warnings;

require 'sample-hash.pl';
require 'main-hash.pl';
require 'result-hash.pl';
our ($sample,$main,$result);
my $max_delay_check = 30;    # seconds
my ($errors,$delay) = compare_feeds($sample,$main,$max_delay_check);

ok(eq_hash($errors, $result) && $delay==0, 'Calculation is correct!');
done_testing();
