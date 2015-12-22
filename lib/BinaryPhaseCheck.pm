use strict;
use warnings;

package BinaryPhaseCheck;
use lib '/home/maksym/perl-feed-phasecheck/lib';
use base 'Feed::PhaseCheck';
use DataDog::DogStatsd::Helper qw(stats_gauge);

sub set {
    my ($self, $params) = @_;
    if (ref $params eq 'HASH') {
        $params->{ref} = 'FXCM';
        $self->SUPER::set($params);
        foreach (keys %$params) {
            if ($_ eq 'path') {
                $self->setPath($params->{$_});
            } elsif ($_ eq 'result_path') {
                $self->setResultPath($params->{$_});
            } elsif ($_ eq 'symbol') {
                $self->setSymbol($params->{$_});
            } elsif ($_ eq 'period') {
                $self->setPeriod($params->{$_});
            } elsif ($_ eq 'long') {
                $self->setLong($params->{$_});
            } elsif ($_ eq 'test') {
                $self->{test} = 1;
            }
            delete $params->{$_};
        }
    }
}

sub setPath {
    my ($self, $path) = @_;
    if (-e $path) {
        $self->{path} = $path;
        return 1;
    }
}

sub setResultPath {
    my ($self, $path) = @_;
    if (-e $path) {
        $self->{result_path} = $path;
        return 1;
    }
}

sub setSymbol {
    my ($self, $symbol) = @_;
    if ($symbol) {
        $self->{symbol} = $symbol;
        return 1;
    }
}

sub setPeriod {
    my ($self, $period) = @_;
    if ($period) {
        $self->{period} = $period;
        return 1;
    }
}

sub setLong {
    my ($self, $long) = @_;
    if ($long) {
        $self->{long} = $long;
        return 1;
    }
}

sub run {
    my $self = shift;

    unless ($self->{period}) {
        die("Timeout should be provided!\n");
    }

    while (1) {
        $self->calculate;
        $self->save_to_file;
        $self->send_to_datadog;
        sleep $self->{period};
    }
}

sub calculate {
    my $self  = shift;
    my $spots = $self->tail_idata;
    $self->SUPER::set_spots($spots);
    $self->SUPER::calculate_errors;
}

sub send_to_datadog {
    my $self = shift;

    my $last_epoch = $self->{last_ref_epoch} || '';

    foreach (keys %{$self->{min_errors}}) {
        if ($self->{ticks_number}->{$_}) {
            my $error = $self->{errors}->{$_}->{0} - $self->{min_errors}->{$_}->{error};
            stats_gauge('phase_delay', $self->{min_errors}->{$_}->{delay}, {tags => ['tag:' . $_]});
            stats_gauge('phase_error', $error, {tags => ['tag:' . $_]});
        }
    }
}

sub save_to_file {
    my $self = shift;

    my @errors;
    unless ($self->{result_path}) {
        push @errors, 'Path for saving result should be provided!';
    }
    unless ($self->{symbol}) {
        push @errors, 'Underlying should be provided!';
    }

    if (scalar @errors) {
        print join("\n", @errors) . "\n";
        die();
    }

    my $path = "$self->{result_path}/$self->{symbol}.csv";

    open(my $fh, ">>", $path) or die("Can not create file!\n");

    my $last_epoch = $self->{last_ref_epoch} || '';
    foreach (sort { $a cmp $b } keys %{$self->{min_errors}}) {
        if ($self->{ticks_number}->{$_}) {
            my $error = $self->{errors}->{$_}->{0} - $self->{min_errors}->{$_}->{error};
            print $fh "$_,$self->{min_errors}->{$_}->{delay},$error,$self->{ticks_number}->{$_},$last_epoch\n";
        }
    }

    close $fh;
}

sub tail_idata {
    my $self = shift;

    my @errors;
    unless ($self->{symbol}) {
        push @errors, "Underlying is needed!";
    }
    unless ($self->{path}) {
        push @errors, "Path is needed!";
    }
    unless ($self->{long}) {
        push @errors, "Long interval is needed!";
    }

    if (scalar @errors) {
        print join("\n", @errors) . "\n";
        die();
    }

    my $interval = $self->{long};

    my %spots;
    my $last_epoch;
    my $spots = {};

    if ($self->{test}) {
        use Time::Local;
        my $path = "/home/EUR-A0-FX3.log";

        if (!(-f $path)) {
            return {};
        }

        my $bw;
        if (-e '/usr/bin/tac') {
            open $bw, "-|", "tac", $path;
        } else {
            open $bw, "-|", "tail", "-r", $path;
        }

        while (my $line = <$bw>) {
            chomp $line;
            my @fields = split /\,/, $line;

            my ($year, $month, $day, $hours, $min, $sec) = split(/[\/: ]/, $fields[1]);
            my $epoch = Time::Local::timegm($sec, $min, $hours, $day, $month - 1, $year);
            $last_epoch = $epoch if !$last_epoch;
            last if $epoch + $interval < $last_epoch;
            $spots->{$fields[4]} = {} if !$spots->{$fields[4]};
            $spots->{$fields[4]}->{$epoch} = ($fields[5] + $fields[6]) / 2;
        }
        close $bw;
    } else {
        my $date = $self->_get_current_date;
        my $path = "$self->{path}/idata/$self->{symbol}/$date-fullfeed.csv";

        if (!(-f $path)) {
            return {};
        }

        my $bw;
        if (-e '/usr/bin/tac') {
            open $bw, "-|", "tac", $path;
        } else {
            open $bw, "-|", "tail", "-r", $path;
        }

        while (my $line = <$bw>) {
            chomp $line;
            my @fields = split /\,/, $line;
            $last_epoch = $fields[0] if !$last_epoch;
            last if $fields[0] + $interval < $last_epoch;
            next if $fields[6] && $fields[6] =~ /BADSRC/;
            $spots->{$fields[5]} = {} if !$spots->{$fields[5]};
            $spots->{$fields[5]}->{$fields[0]} = $fields[4];
        }
        close $bw;
    }
    return $spots;
}

sub _get_current_date {
    my $self = shift;
    my ($sec, $min, $hour, $day, $month, $year) = gmtime(1447286399);
    my $date = "$day-" . $self->_month_to_name($month) . "-" . ($year - 100);
    return $date;
}

sub _month_to_name {
    my $self   = shift;
    my $number = shift;
    my %m      = (
        0  => 'Jan',
        1  => 'Feb',
        2  => 'Mar',
        3  => 'Apr',
        4  => 'May',
        5  => 'Jun',
        6  => 'Jul',
        7  => 'Aug',
        8  => 'Sep',
        9  => 'Oct',
        10 => 'Nov',
        11 => 'Dec'
    );
    return $m{$number};
}

1;
