package GEDCOM::ReportEngine::Record::Attribute;

=head1 GEDCOM::ReportEngine::Record::Attribute

Attributes.

=cut

use base qw(GEDCOM::ReportEngine::Record);
use strict;
use warnings;
use utf8;

# move the following to Record.pm

sub date {
    my $self = shift;
    return $self->get_strings("DATE");
}

sub isodate {
    my $self = shift;
    my $date = $self->get_record("DATE");
    return $date ? $date->isodate : '';
}

sub year {
    my $self = shift;
    my $date = $self->get_record("DATE");
    return $date ? $date->year : '';
}

sub place {
    my $self  = shift;
    my $place = $self->get_record("PLAC");
    return $place ? $place->shortname : '';
}

=pod

=item tagname()

The tagname method includes an exception for the FACT tag; otherwise,
it is the same as the base class tagname().

=cut

sub tagname {
    my $self = shift;
    if ( $self->tag eq "FACT" ) {
        return ( $self->get_value("TYPE") || $self->tag );
    }
    return $self->SUPER::tagname();
}

sub _string {
    my $self  = shift;
    my $name  = $self->tagname;
    my $value = $self->value;
    my $type  = $self->get_value("TYPE");

    my $t;
    if ( $value && $type && $self->tag ne "FACT" ) {
        $t = "$value ($type)";
    }
    elsif ($value) {
        $t = $value;
    }
    elsif ($type) {
        $t = $type;
    }
    else {
        $t = $name;
    }
    return $t;
}

sub as_string {
    my $self = shift;
    my %opt  = @_;

    my $attribute = $self->_string;
    my $date      = $self->date;
    my $place     = $self->place;

    my $t;
    if ( $date && $place ) {
        $t = sprintf( "%s i %s (%s)", $attribute, $date, $place );
    }
    elsif ($place) {
        $t = sprintf( "%s i %s", $attribute, $place );
    }
    elsif ($date) {
        $t = sprintf( "%s (%s)", $attribute, $date );
    }
    else {
        $t = sprintf( "%s", $attribute );
    }
    return $t;
}

sub as_sentence {
    my $self = shift;
    my %opt = @_;

    my $t = ucfirst( $self->as_string(@_) ) . '.';

    # Add sources
    $t .= $self->sources_footnote unless ($opt{nosource});

    $t .= " ";

    return $t;
}

1;
