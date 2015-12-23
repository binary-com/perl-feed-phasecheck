# Feed::PhaseCheck

An object oriented module that finds the relative time delay between two feed segments.  

Accomplished by shifting one feed relative to the other and then computing the error (absolute difference).  

The shift that yields the lowest error corresponds to the relative delay between he two input feeds.  

The output consists of the delay found, and the error in delayed point.

### Input format:
* Feed spots list:
```perl
$spots = {
    'DCFX' => {
        '1447286220' => '1.07617',
        '1447286221' => '1.07608',
        '1447286222' => '1.07608'
        
    },
    'FXCM' => {
        '1447286220' => '1.07618',
        '1447286222' => '1.076135',
        '1447286223' => '1.0761125'
    }};
```
* Referance provider's name (should be the key from spots' hash) - relative to this provider's feed will be the compression done:
```perl
$ref = 'FXCM';
```
* Short - the length of the feed in seconds, that should be compared to referance feed
```perl
$short = 30;
```

There are 3 ways to pass input parameters:
```perl
my $ph = Feed::PhaseCheck->new({
        short => 120,
        spots => $spots,
        ref   => 'FXCM'
    });
```
```perl
my $ph = Feed::PhaseCheck->new;
$ph->set({
        short => 120,
        spots => $spots,
        ref   => 'FXCM'
    });
```
```perl
my $ph = Feed::PhaseCheck->new;
$ph->set_spots($spots);
$ph->set_ref('FXCM');
$ph->set_short(120);
```

### Methods:

* new
```perl
my $ph = Feed::PhaseCheck->new;
```
or
```perl
my $ph = Feed::PhaseCheck->new({
        short => 120,
        spots => $spots,
        ref   => 'FXCM'
    });
```
* set
```perl
$ph->set({
        short => 120,
        spots => $spots,
        ref   => 'FXCM'
    });
```
* set_spot
```perl
# Ref to HASH
$ph->set_spots($spots);
```
* set_ref
```perl
$ph->set_ref('FXCM');
```
* set_short
```perl
$ph->set_short(120);
```
* calculate_for_provider
```perl
# Calculates errors for provider with name "provider". 
# There should be key "provider" in spots HASH
$ph->calculate('provider');
```
* calculate_for_all
```perl
# Calculates errors for all providers in spots' hash except REF provider 
$ph->calculate_for_all;
```
* list_errors
```perl
# Lists hash with errors for each calculated provider for each calculated dalay
my $result = $ph->list_errors;

# Lists hash with errors for "provider" for each calculated dalay
my $result =  $ph->list_errors('provider');
```
* list_min_errors
```perl
# Lists hash with min error and delay for this min error for each calculated provider
my $result = $ph->list_min_errors;

# Lists hash with min error and delay for this min error for "provider"
my $result =  $ph->list_min_errors('provider');
```