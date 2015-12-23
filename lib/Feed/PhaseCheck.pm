package Feed::PhaseCheck;

use 5.006;
use strict;
use warnings;

=head1 NAME

Feed::PhaseCheck

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Finds the relative time delay between two feed segments.  

Accomplished by shifting one feed relative to the other and then computing the error (absolute difference).  

The shift that yields the lowest error corresponds to the relative delay between he two input feeds.  

The output consists of the delay found, and the error in delayed point.

=cut

sub new {
    my ($class, $args) = @_;
    my $self = bless {}, $class;
    $self->set($args);
    $self->clean;
    return $self;
}

sub set {
    my ($self, $params) = @_;
    if (ref $params eq 'HASH') {
        foreach (keys %$params) {
            if ($_ eq 'spots') {
                $self->set_spots($params->{$_});
                delete $params->{$_};
            } elsif ($_ eq 'ref') {
                $self->set_ref($params->{$_});
                delete $params->{$_};
            } elsif ($_ eq 'short') {
                $self->set_short($params->{$_});
                delete $params->{$_};
            }
        }
    }
}

sub set_spots {
    my ($self, $spots) = @_;
    if (ref $spots ne 'HASH') {
        return;
    }
    $self->{spots} = $spots;
    $self->clean;
    return $self->{spots};
}

sub set_ref {
    my ($self, $ref) = @_;
    if ($ref && !ref($ref) && $ref =~ /^[a-z0-9_-]+$/i) {
        $self->{ref} = $ref;
        $self->{_ref} = {};
        $self->clean;
    }
    return $self->{ref};
}

sub set_short {
    my ($self, $short) = @_;
    if ($short && !ref($short) && $short =~ /^[0-9]+$/) {
        $self->{short} = $short;
        $self->clean;
    }
    return $self->{short};
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

sub calculate_for_all {
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

    $self->clean;

    foreach my $provider (keys %{$self->{spots}}) {
        next if $provider eq $self->{ref};
        my $result = $self->calculate_for_provider($provider);
        if(ref $result eq 'HASH'){
            $self->{errors}->{$provider} = $result->{errors};
            $self->{min_errors}->{$provider} = {
                error => $result->{min_error},
                delay => $result->{min_delay},
            };
            $self->{spots_number}->{$provider} = $result->{spots_number};
        }
    }
    return ($self->{errors}, $self->{min_errors});
}

sub calculate_for_provider {
    my ($self, $sample_name) = @_;

    if (!$sample_name) {
        return;
    }

    if (ref $self->{spots} ne 'HASH') {
        return;
    }

    if (!$self->{ref} || !$self->{spots}->{$self->{ref}}) {
        return;
    }

    my $sample_full = $self->{spots}->{$sample_name};
    if (!$sample_full) {
        return;
    }

    if (!$self->{short}) {
        return;
    }

    if (!$self->{_ref} || !scalar keys %{$self->{_ref}}) {
        $self->{_ref} = {
            epoches => [sort(keys %{$self->{spots}->{$self->{ref}}})],
            spots   => $self->{spots}->{$self->{ref}}};
    }
    my $ref = $self->{_ref};

    my $first_ref_epoch = $ref->{epoches}->[0];
    my $last_ref_epoch  = $ref->{epoches}->[-1];
    my $delay           = int(($ref->{epoches}->[-1] - $ref->{epoches}->[0] - $self->{short}) / 2);

    my %spots;
    foreach my $e (keys %$sample_full) {
        if ($e >= $first_ref_epoch + $delay && $e <= $last_ref_epoch - $delay) {
            $spots{$e} = $sample_full->{$e};
        }
    }

    if (!scalar(keys %spots)) {
        return;
    }

    my $sample = {
        epoches => [sort keys %spots],
        spots   => \%spots
    };

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

    return {
        errors => $errors,
        min_delay => $min_error_delay,
        min_error => $min_error,
        spots_number => scalar(keys %spots)
    };
}

sub clean {
    my $self = shift;
    $self->{errors}       = {};
    $self->{min_errors}   = {};
    $self->{spots_number} = {};
}

=head1 AUTHOR

Maksym Kotielnikov, C<< <maksym at binary.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-feed-phasecheck at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Feed-PhaseCheck>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Feed::PhaseCheck


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Feed-PhaseCheck>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Feed-PhaseCheck>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Feed-PhaseCheck>

=item * Search CPAN

L<http://search.cpan.org/dist/Feed-PhaseCheck/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Maksym Kotielnikov.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1;    # End of Feed::PhaseCheck
