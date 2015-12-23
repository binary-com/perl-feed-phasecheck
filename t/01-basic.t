use Test::More;
use Data::Dumper;
use Feed::PhaseCheck;
use strict;
use warnings;

require 'spots.pl';
our $spots;

sub default_params {
    my $param  = shift;
    my $params = {
        short => 120,
        spots => $spots,
        ref   => 'FXCM'
    };
    if ($param) {
        return $params->{$param};
    } else {
        return $params;
    }
}

my $skip;
my $ph1 = Feed::PhaseCheck->new;
ok(
    eq_hash(
        {%$ph1},
        {
            spots_number => {},
            min_errors   => {},
            errors       => {}}
    ),
    'Initiation without params'
) || (($skip = 1));
undef $ph1;

my $params1 = default_params;
my $ph2 = Feed::PhaseCheck->new({%$params1, wrong_parameter => 1});
ok(
    eq_hash(
        {%$ph2},
        {
            %{default_params()},
            _ref         => {},
            spots_number => {},
            min_errors   => {},
            errors       => {}}
    ),
    'Initiation with parameters (wrong parameter shouldn’t pass).'
) || ($skip = 1);
undef $ph2;

my $ph3 = Feed::PhaseCheck->new;
$ph3->{spots_number} = {a => 1};
$ph3->{min_errors}   = {a => 1};
$ph3->{errors}       = {a => 1};
$ph3->set_spots('wrong_value');
ok(
    eq_hash(
        {%$ph3},
        {
            spots_number => {a => 1},
            min_errors   => {a => 1},
            errors       => {a => 1}}
    ),
    'Wrong value for set_spots method should not pass.'
) || ($skip = 1);
$ph3->set_spots(default_params('spots'));
ok(
    eq_hash(
        {%$ph3},
        {
            spots        => default_params('spots'),
            spots_number => {},
            min_errors   => {},
            errors       => {}}
    ),
    'Correct value for set_spots method should pass, result fields should be set to defaults.'
) || ($skip = 1);
undef $ph3;

my $ph4 = Feed::PhaseCheck->new;
$ph4->{spots_number} = {a => 1};
$ph4->{min_errors}   = {a => 1};
$ph4->{errors}       = {a => 1};
$ph4->set_short('wrong_value');
ok(
    eq_hash(
        {%$ph4},
        {
            spots_number => {a => 1},
            min_errors   => {a => 1},
            errors       => {a => 1}}
    ),
    'Wrong value for set_short method should not pass.'
) || ($skip = 1);
$ph4->set_short(default_params('short'));
ok(
    eq_hash(
        {%$ph4},
        {
            short        => default_params('short'),
            spots_number => {},
            min_errors   => {},
            errors       => {}}
    ),
    'Correct value for set_short method should pass, result fields should be set to defaults.'
) || ($skip = 1);
undef $ph4;

my $ph5 = Feed::PhaseCheck->new;
$ph5->{spots_number} = {a => 1};
$ph5->{min_errors}   = {a => 1};
$ph5->{errors}       = {a => 1};
$ph5->set_ref(default_params('ref'));
ok(
    eq_hash(
        {%$ph5},
        {
            _ref         => {},
            ref          => default_params('ref'),
            spots_number => {},
            min_errors   => {},
            errors       => {}}
    ),
    'Correct value for set_ref method should pass, result fields should be set to defaults.'
) || ($skip = 1);
undef $ph5;

if ($skip) {
    plan skip_all => 'Wrong processing of input parameters';
}

my $ph6 = Feed::PhaseCheck->new;
ok(!($ph6->calculate_for_provider), 'Can\'t calculate without parameters passed.');
$ph6->set(default_params);
ok(!($ph6->calculate_for_provider),               'Provider\'s name should provided.');
ok(!($ph6->calculate_for_provider('wrong_name')), 'Provider\'s name should be key from spots HASH.');
delete $ph6->{spots};
ok(!($ph6->calculate_for_provider('DCFX')), 'Spots should be HASH.');
$ph6->set_spots(default_params('spots'));
delete $ph6->{ref};
ok(!($ph6->calculate_for_provider('DCFX')), 'Ref name should be provided.');
$ph6->set_ref('wrong_value');
ok(!($ph6->calculate_for_provider('DCFX')), 'Ref name should be the key from spots HASH.');
$ph6->set_ref(default_params('ref'));
my $e = $ph6->calculate_for_provider('DCFX');
require 'errors_DCFX.pl';
our $errors_DCFX;
ok(
    eq_hash(
        $e,
        {
            errors       => $errors_DCFX,
            min_delay    => 0,
            min_error    => '1.19795454544091e-08',
            spots_number => 41
        }
    ),
    'calculate_for_provider method should make calculations with correct params.'
);
undef $ph6;

my $ph7 = Feed::PhaseCheck->new(default_params);
$ph7->calculate_for_all;
ok(
    eq_hash(
        $ph7->{min_errors},
        {
            'DCFX' => {
                'error' => '1.19795454544091e-08',
                'delay' => 0
            }})
        && eq_hash($ph7->{errors},       {'DCFX' => $errors_DCFX})
        && eq_hash($ph7->{spots_number}, {'DCFX' => 41}),
    'calculate_for_all method shoud provide valid result when valid parameters.'
);
undef $ph7;

done_testing();

