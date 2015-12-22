use strict;
use warnings;

package PhaseCheck;

sub new {
    my ($class, $args) = @_;
    my $self = bless {}, $class;
    $self->set($args);
    return $self;
}

sub set {
    my ($self, $params) = @_;
    if (ref $params eq 'HASH') {
        foreach (keys %$params) {
            if ($_ eq 'spots') {
                $self->setSpots($params->{$_});
                delete $params->{$_};
            } elsif ($_ eq 'ref') {
                $self->setRef($params->{$_});
                delete $params->{$_};
            } elsif ($_ eq 'short') {
                $self->setShort($params->{$_});
                delete $params->{$_};
            }
        }
    }
}

sub setSpots {
    my ($self, $spots) = @_;
    if (ref $spots ne 'HASH') {
        return;
    }
    $self->{spots} = $spots;
    delete $self->{errors};
    delete $self->{min_errors};
    delete $self->{ticks_number};
    return 1;
}

sub setRef {
    my ($self, $ref) = @_;
    if ($ref) {
        $self->{ref} = $ref;
        delete $self->{errors};
        delete $self->{min_errors};
        delete $self->{ticks_number};
        return 1;
    }
}

sub setShort {
    my ($self, $short) = @_;
    if ($short) {
        $self->{short} = $short;
        delete $self->{errors};
        delete $self->{min_errors};
        delete $self->{ticks_number};
        return 1;
    }
}

sub list_errors {
    my ($self, $provider) = @_;

    if ($self->{errors}) {
        $self->calculate_errors;
    }

    if ($provider) {
        return $self->{errors}->{$provider};
    } else {
        return $self->{errors};
    }
}

sub list_min_errors {
    my ($self, $provider) = @_;

    if ($self->{errors}) {
        $self->calculate_errors;
    }

    if ($provider) {
        return $self->{min_errors}->{$provider};
    } else {
        return $self->{min_errors};
    }
}

sub calculate_errors {
    my $self = shift;

    my @errors;
    unless (ref $self->{spots} eq 'HASH') {
        push @errors, "Spots are needed!";
    }
    unless ($self->{short}) {
        push @errors, "Short period is needed!";
    }
    unless ($self->{ref}) {
        push @errors, "Ref provider's name is needed!";
    }

    if (scalar @errors) {
        print join("\n", @errors) . "\n";
        die();
    }

    $self->{errors}       = {};
    $self->{min_errors}   = {};
    $self->{ticks_number} = {};

    my $ref = {
        epoches => [sort(keys %{$self->{spots}->{$self->{ref}}})],
        spots   => $self->{spots}->{$self->{ref}}};

    my $first_ref_epoch = $ref->{epoches}->[0];
    my $last_ref_epoch  = $ref->{epoches}->[-1];
    $self->{last_ref_epoch} = $last_ref_epoch;

    my $delay = int(($ref->{epoches}->[-1] - $ref->{epoches}->[0] - $self->{short}) / 2);
    foreach my $provider (keys %{$self->{spots}}) {
        next if $provider eq $self->{ref};
        my %spots;
        foreach my $e (keys %{$self->{spots}->{$provider}}) {
            if ($e >= $first_ref_epoch + $delay && $e <= $last_ref_epoch - $delay) {
                $spots{$e} = $self->{spots}->{$provider}->{$e};
            }
        }
        $self->{ticks_number}->{$provider} = scalar keys \%spots;
        my $sample = {
            epoches => [sort keys %spots],
            spots   => \%spots
        };
        if (scalar keys %spots) {
            ($self->{errors}->{$provider}, $self->{min_errors}->{$provider}) = $self->calculate_error($ref, $sample);
        }
    }
}

sub calculate_error {
    my ($self, $ref, $sample) = @_;

    my $errors = {};
    my ($min_error_delay, $min_error);
    my $long = $ref->{epoches}->[-1] - $ref->{epoches}->[0];
    for (my $delay = -int(($long - $self->{short}) / 2); $delay <= int(($long - $self->{short}) / 2); $delay++) {
        my $error = 0;
        foreach my $epoch (@{$sample->{epoches}}) {
            my $sample_epoch = $epoch - $delay;
            my $ref_value;
            if (!$ref->{spots}->{$sample_epoch}) {
                for (my $i = 1; $i < scalar @{$ref->{epoches}}; $i++) {
                    if ($ref->{epoches}->[$i] > $sample_epoch) {
                        $ref->{spots}->{$sample_epoch} =
                            $ref->{spots}->{$ref->{epoches}->[$i - 1]} +
                            ($sample_epoch - $ref->{epoches}->[$i - 1]) *
                            ($ref->{spots}->{$ref->{epoches}->[$i]} - $ref->{spots}->{$ref->{epoches}->[$i - 1]}) /
                            ($ref->{epoches}->[$i] - $ref->{epoches}->[$i - 1]);
                        last;
                    }
                }
            }
            $error += ($ref->{spots}->{$sample_epoch} - $sample->{spots}->{$epoch})**2;
        }
        $errors->{$delay} = $error;
        if (!defined($min_error) || $min_error > $error) {
            $min_error       = $error;
            $min_error_delay = $delay;
        }
    }

    return (
        $errors,
        {
            delay => $min_error_delay,
            error => $min_error
        });
}

1;
