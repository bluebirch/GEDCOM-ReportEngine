# -*- coding: utf-8 -*-
package GEDCOM::Record::Date::Range;
use base qw(GEDCOM::Record::Date);
use strict;
use warnings;
use utf8;
use Date::Calc qw(:all);

sub isodate {
    my $self = shift;
    my @d1   = @{ ( $self->{date1} || $self->{date2} ) };    # First date
    my @d2   = @{ ( $self->{date2} || $self->{date1} ) };    # Second date
    my $t    = "";
    if ( $d2[0] && $d2[0] != $d1[0] ) {
        $t = sprintf( "%04d", $d2[0] );
    }
    if ( $d2[1] && $d2[1] != $d1[1] ) {
        $t .= '-' if ($t);
        $t .= sprintf( "%02d", $d2[1] );
    }
    if ( $d2[2] && $d2[2] != $d1[2] ) {
        $t .= '-' if ($t);
        $t .= sprintf( "%02d", $d2[2] );
    }
    return $self->_isodate(@d1) . '--' . $t;
}

sub as_string {
    my $self   = shift;
    my %opt    = @_;
    my $format = $opt{format} ? $opt{format} : 'text';
    my $sub    = '_' . $format . 'date';
    my $t;
    if ( $self->{date1} && $self->{date2} ) {
        $t = sprintf(
            "från %s till %s",
            $self->$sub( @{ $self->{date1} } ),
            $self->$sub( @{ $self->{date2} } )
        );
    }
    elsif ( $self->{date1} ) {
        $t = sprintf( "från %s", $self->$sub( @{ $self->{date1} } ) );
    }
    elsif ( $self->{date2} ) {
        $t = sprintf( "till %(date2)", $self->$sub( @{ $self->{date2} } ) );
    }
    else {
        $t = "completely screwed up date";
    }
    return $t;
}

sub earliest {
    my $self = shift;
    my @date = @{ ( $self->{date1} || $self->{date2} ) };
    $date[1] = 1 unless ( $date[1] );
    $date[2] = 1 unless ( $date[2] );
    return @date;
}

sub latest {
    my $self = shift;
    my @date = @{ ( $self->{date2} || $self->{date1} ) };
    $date[1] = 12 unless ( $date[1] );
    $date[2] = Days_in_Month( @date[ 0 .. 1 ] ) unless ( $date[2] );
    return @date;
}

1;
