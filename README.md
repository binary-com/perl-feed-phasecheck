# NAME

Feed::PhaseCheck

Finds the relative time delay between two feed segments.

Accomplished by shifting one feed relative to the other and then computing the error (absolute difference).

The shift that yields the lowest error corresponds to the relative delay between he two input feeds.

The output consists of the delay found, and the error in delayed point.

# SYNOPSIS

    use Feed::PhaseCheck qw(compare_feeds);
    my $sample = {
        "1451276654" => "1.097655",
        "1451276655" => "1.09765",
        #...
        "1451276763" => "1.0976",
        "1451276764" => "1.097595"
    };
    my $compare_to = {
        "1451276629" => "1.09765",
        "1451276630" => "1.09764916666667",
        #...
        "1451276791" => "1.097595",
        "1451276792" => "1.097595"
    };
    my $max_delay_check = 30;    # seconds
    my ($errors,$delay_with_min_err) = compare_feeds($sample,$compare_to,$max_delay_check);

# METHODS

## compare\_feeds

# AUTHOR

Maksym Kotielnikov, `<maksym at binary.com>`

# BUGS

Please report any bugs or feature requests to `bug-feed-phasecheck at rt.cpan.org`, or through
the web interface at [http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Feed-PhaseCheck](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Feed-PhaseCheck).  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Feed::PhaseCheck

You can also look for information at:

- RT: CPAN's request tracker (report bugs here)

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=Feed-PhaseCheck](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Feed-PhaseCheck)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/Feed-PhaseCheck](http://annocpan.org/dist/Feed-PhaseCheck)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Feed-PhaseCheck](http://cpanratings.perl.org/d/Feed-PhaseCheck)

- Search CPAN

    [http://search.cpan.org/dist/Feed-PhaseCheck/](http://search.cpan.org/dist/Feed-PhaseCheck/)

# ACKNOWLEDGEMENTS
