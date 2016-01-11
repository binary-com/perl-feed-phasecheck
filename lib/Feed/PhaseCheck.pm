package Feed::PhaseCheck;

use 5.006;
use strict;
use warnings;

use Exporter qw(import);

our @EXPORT_OK = qw(compare_feeds);

=head1 NAME

Feed::PhaseCheck

Finds the relative time delay between two feed segments.  

Accomplished by shifting one feed relative to the other and then computing the error (absolute difference).  

The shift that yields the lowest error corresponds to the relative delay between he two input feeds.  

The output consists of the delay found, and the error in delayed point.

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

    use Feed::PhaseCheck qw(compare_feeds);
    my $sample = {
        "1451276654" => "1.097655",
        "1451276655" => "1.09765",
        ...
        "1451276763" => "1.0976",
        "1451276764" => "1.097595"
    };
    my $compare_to = {
        "1451276629" => "1.09765",
        "1451276630" => "1.09764916666667",
        ...
        "1451276791" => "1.097595",
        "1451276792" => "1.097595"
    }
    my $max_delay_check = 30;    # seconds
    my ($errors,$delay_with_min_err) = compare_feeds($sample,$compare_to,$max_delay_check);

=cut

sub compare_feeds {
    my $sample          = shift;
    my $main            = shift;
    my $max_delay_check = shift || 0;

    if ($max_delay_check !~ /^\d+$/) {
        return;
    }

    if (ref $sample ne 'HASH' || scalar keys %$sample < 2) {
        return;
    }

    if (ref $main ne 'HASH' || scalar keys %$main < 2) {
        return;
    }

    my @main_epoches = sort keys %$main;
    foreach (@main_epoches) {
        if (int($_) != $_ || abs($main->{$_}) != $main->{$_}) {
            return;
        }
    }

    my @sample_epoches = sort keys %$sample;
    foreach (@sample_epoches) {
        if (int($_) != $_ || abs($sample->{$_}) != $sample->{$_}) {
            return;
        }
    }

    if ($sample_epoches[0] < $main_epoches[0] || $sample_epoches[-1] > $main_epoches[-1]) {
        return;
    }

    my %main  = %$main;
    my %error = ();
    my ($min_error, $delay_for_min_error);
    my $delay1 = $sample_epoches[0] - $main_epoches[0] < $max_delay_check   ? $sample_epoches[0] - $main_epoches[0]   : $max_delay_check;
    my $delay2 = $main_epoches[-1] - $sample_epoches[-1] < $max_delay_check ? $main_epoches[-1] - $sample_epoches[-1] : $max_delay_check;
    for (my $delay = -$delay1; $delay <= $delay2; $delay++) {
        $error{$delay} = 0;
        foreach my $epoch (@sample_epoches) {
            my $sample_epoch = $epoch - $delay;
            if (!defined $main{$sample_epoch}) {
                for (my $i = 1; $i < scalar keys @main_epoches; $i++) {
                    if ($main_epoches[$i] > $sample_epoch) {
                        $main{$sample_epoch} = _interpolate(
                            $main_epoches[$i - 1],
                            $main{$main_epoches[$i - 1]},
                            $main_epoches[$i], $main{$main_epoches[$i]},
                            $sample_epoch
                        );
                        last;
                    }
                }
            }
            $error{$delay} += ($main{$sample_epoch} - $sample->{$epoch})**2;
        }
        if (!defined $min_error || $error{$delay} < $min_error) {
            $min_error           = $error{$delay};
            $delay_for_min_error = $delay;
        }
        # $error{$delay} =~ s/(\d{8}).+?e/$1e/;
    }

    return (\%error, $delay_for_min_error);
}

sub _interpolate {
    my ($x1, $y1, $x2, $y2, $x) = @_;
    my $y = $y1 + ($x - $x1) * ($y2 - $y1) / ($x2 - $x1);
    return $y;
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
