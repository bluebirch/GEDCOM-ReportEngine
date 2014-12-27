
=head1 The GEDCOM::Record::Date package

=over 8

=cut

package GEDCOM::Record::Date;
use base qw(GEDCOM::Record);
use strict;
use warnings;
use utf8;
#use GEDCOM::Locale;
use GEDCOM::Record::Date::Range;
use GEDCOM::Record::Date::Interval;
use Date::Calc qw(:all);
use Data::Dumper;

my %Months;

BEGIN {
    %Months = (
        JAN => 1,
        FEB => 2,
        MAR => 3,
        APR => 4,
        MAY => 5,
        JUN => 6,
        JUL => 7,
        AUG => 8,
        SEP => 9,
        OCT => 10,
        NOV => 11,
        DEC => 12
    );

    Language( Decode_Language("svenska") );
}

sub _parsedate {
    my ( $self, $date ) = @_;

    $date
        =~ m/^((\d+)\s+)?((JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)\s+)?(\d{4})$/i
        or die "Invalid date $date";

    my @date = ( 0, 0, 0 );

    $date[0] = $5               if ($5);
    $date[1] = $Months{ uc $4 } if ($4);
    $date[2] = $2               if ($2);

    return @date;
}

sub _isodate {
    my ( $self, $year, $month, $day ) = @_;
    my $t = '';
    if ($year) {
        $t .= sprintf( "%04d", $year );
        if ($month) {
            $t .= sprintf( "-%02d", $month );
            if ($day) {
                $t .= sprintf( "-%02d", $day );
            }
        }
    }
    return $t;
}

sub _textdate {
    my ( $self, $year, $month, $day ) = @_;
    my $t = '';
    if ($year) {
        $t = sprintf( "%04d", $year );
        if ($month) {
            $t = sprintf( "%s $t", Month_to_Text($month) );
            if ($day) {
                $t = sprintf( "%d $t", $day );
            }
        }
    }
    return $t;
}

sub _numericdate {
    my ( $self, $year, $month, $day ) = @_;
    my $t = '';
    if ($year) {
        $t = sprintf( "%04d", $year );
        if ($month) {
            if ($day) {
                $t .= sprintf( "~%d/%d", $day, $month );
            }
            else {
                $t .= sprintf( "~?/%d", $month );
            }
        }
    }
    return $t;
}

sub parse {
    my $self  = shift;
    my $class = ref($self);
    my $date  = $self->{value};

    my ( @date1, @date2 );

    # Check if date is estimated
    if ( $date =~ s/\s*EST\s+//i ) {
        $self->{estimated} = 1;
    }

    # Check if date is approximate
    if ( $date =~ s/\s*ABT\s+//i ) {
        $self->{approximated} = 1;
    }

    # Check if date is calculated
    if ( $date =~ s/\s*CAL\s+//i ) {
        $self->{calculated} = 1;
    }

    # Check if date is a range
    if ( $date =~ m/FROM (.*?) TO (.*)/i ) {
        $class .= '::Range';
        @{ $self->{date1} } = $self->_parsedate($1);
        @{ $self->{date2} } = $self->_parsedate($2);
    }
    elsif ( $date =~ m/FROM (.*)/i ) {
        $class .= '::Range';
        @{ $self->{date1} } = $self->_parsedate($1);
    }
    elsif ( $date =~ m/TO (.*)/i ) {
        $class .= '::Range';
        @{ $self->{date2} } = $self->_parsedate($1);
    }

    # Check if date is interval
    elsif ( $date =~ m/BET (.*?) AND (.*)/i ) {
        $class .= '::Interval';
        @{ $self->{date1} } = $self->_parsedate($1);
        @{ $self->{date2} } = $self->_parsedate($2);
    }
    elsif ( $date =~ m/AFT (.*)/i ) {
        $class .= '::Interval';
        @{ $self->{date1} } = $self->_parsedate($1);
    }
    elsif ( $date =~ m/BEF (.*)/i ) {
        $class .= '::Interval';
        @{ $self->{date2} } = $self->_parsedate($1);
    }

    # Assume date is point in time
    else {
        @{ $self->{date1} } = $self->_parsedate($date);
    }

    # If class has changed, bless myself.
    if ( ref($self) ne $class ) {
        bless( $self, $class );
    }

    #     # If we got no date from this process, something must be wrong.
    #     if (!$self->{date1}) {
    #   die "Date parse error: $self->{value}";
    #     }

    # Run parse in base class.
    $self->SUPER::parse();
}

sub sortkey {
    my $self = shift;
    unless ( $self->{sortkey} ) {
        my @date;
        if ( $self->{date1} ) {
            @date = @{ $self->{date1} };
        }
        elsif ( $self->{date2} ) {
            @date = @{ $self->{date2} };
        }
        else {
            @date = ( 0, 0, 0 );
        }

       #    print "created sort key ", sprintf( "%04d%02d%02d", @date ), "\n";
        $self->{sortkey} = sprintf( "%04d%02d%02d", @date );
    }
    return $self->{sortkey};
}

sub isodate {
    my $self = shift;
    return $self->_isodate( @{ $self->{date1} } );
}

=pod

=item as_string( [format] )

Return date as a string with the specified format. Format can be one
of 'text' or 'iso'.

=cut

sub as_string {
    my $self   = shift;
    my %opt    = @_;
    my $format = $opt{format} ? $opt{format} : 'text';
    $format = '_' . $format . 'date';
    return $self->$format( @{ $self->{date1} } );
}

=pod

=item prefix()

Return a string prefixing the date, such as 'estimated' or 'calculated'.

=cut

sub prefix {
    my $self = shift;
    my $t    = '';
    $t .= "uppskattat "  if ( $self->{estimated} );
    $t .= "beräkntat " if ( $self->{calculated} );
    $t .= "omkring "      if ( $self->{approximated} );
    return $t;
}

=pod

=item year()

Return year of date. (What about ranges?)

=cut

sub year {
    my $self = shift;
    my ($year) = $self->earliest;
    return $year;
}

=pod

=item earliest(), latest()

Return array with earliest and latest possible date, respectively.

=cut

sub earliest {
    my $self = shift;
    my @date = @{ $self->{date1} };
    $date[1] = 1 unless ( $date[1] );
    $date[2] = 1 unless ( $date[2] );
    return @date;
}

sub latest {
    my $self = shift;
    my @date = @{ $self->{date1} };
    $date[1] = 12 unless ( $date[1] );
    $date[2] = Days_in_Month( @date[ 0 .. 1 ] ) unless ( $date[2] );
    return @date;
}

=pod

=item delta()

Compare this date object with another date object and return the time
passed in a string. Used for calculating age.

=cut

sub delta {
    my ( $self, $other ) = @_;

    return '' unless ($other);

#     print STDERR "Dates1: ", $self->_isodate( $self->latest ), " ", $self->_isodate( $self->earliest ), "\n";
#     print STDERR "Dates2: ", $self->_isodate( $other->latest ), " ", $self->_isodate( $other->earliest ), "\n";

    # Calculate shortest possible range (latest of first date and
    # first of second date).
    my @shortest = $self->_delta( $self->latest, $other->earliest );

    # Calculate longest possible range (earliest of first date and
    # latest of second date).
    my @longest = $self->_delta( $self->earliest, $other->latest );

    #      print STDERR "Ranges:\n";
    #      print STDERR Dumper \@shortest, \@longest;

    # Express difference as a string
    my $t = '';
    if ( $shortest[0] || $longest[0] ) {
        if ( $shortest[0] == $longest[0] ) {
            $t = sprintf( "%s år", $shortest[0] );
        }
        else {
            $t = sprintf( "%s--%s år", $shortest[0], $longest[0] );
        }
    }
    elsif ( $shortest[1] || $longest[1] ) {
        if ( $shortest[1] == $longest[1] ) {
            $t = sprintf( "%s månader", $shortest[1] );
        }
        else {
            $t = sprintf( "%s--%s månader", $shortest[1], $longest[1] );
        }
    }
    elsif ( $shortest[2] || $longest[2] ) {
        if ( $shortest[2] == $longest[2] ) {
            $t = sprintf( "%s dagar", $shortest[2] );
        }
        else {
            $t = sprintf( "%s--%s dagar", $shortest[2], $longest[2] );
        }
    }
    return $t;
}

=pod

=item _delta()

Calculate difference between two dates. Helper function to delta().

=cut

sub _delta {
    my $self = shift;
    my @d1   = @_[ 0 .. 2 ];    # Beginning
    my @d2   = @_[ 3 .. 5 ];    # End

    #     print STDERR "calculate delta: @d1 @d2\n";

    # Calculate difference.
    my @diff = Delta_YMD( @d1, @d2 );

    # Make sure difference is positive.
    if ( $diff[2] < 0 ) {
        $diff[2] += Days_in_Month( @d2[ 0 .. 1 ] );
        $diff[1]--;
    }
    if ( $diff[1] < 0 ) {
        $diff[1] += 12;
        $diff[0]--;
    }
    return @diff;
}

=pod

=item subtract_dates( year1, month1, day1, year2, day2, month2 )

Subtract the latter date from the former and return the difference.

=cut

sub subtract_date {
    my $self  = shift;
    my @date1 = @_[ 0 .. 2 ];
    my @date2 = @_[ 3 .. 5 ];

    # Swap dates if date2 is before date 1.
    if ( $self->compare_dates( @date1, @date2 ) > 0 ) {
        my @tmp = @date1;
        @date1 = @date2;
        @date2 = @tmp;
    }

}

=pod

=item compare_dates()

Compare two dates.

=cut

sub compare_dates {
    my $self  = shift;
    my $date1 = sprintf( "%04d%02d%02d", @_[ 0 .. 2 ] );
    my $date2 = sptintf( "%04d%02d%02d", @_[ 3 .. 5 ] );
    return $date1 cmp $date2;
}

1;
