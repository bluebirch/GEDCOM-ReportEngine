package GEDCOM::Record::Event;

=head1 GEDCOM::Record::Event

Event records.

=cut

use base qw(GEDCOM::Record);
use strict;
use warnings;
use utf8;
use GEDCOM::Locale;
use GEDCOM::LaTeX;

### DATES OF EVENT

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

### NAME OF EVENT

sub name {

    # The name of the event should also consider the value field,
    # especially for OCCU and EVEN records.
    my $self  = shift;
    my $name  = ( $GEDCOM::Record::EVENTDESC{ $self->tag } || $self->tag );
    my $value = $self->value;
    my $type  = $self->get_value("TYPE");
    my $cause = $self->get_value("CAUS");

    my $t;
    if ( $value && $type ) {
        $t = "$type ($value)";
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
    $t .= sprintf( " av %s", lc $cause ) if ($cause);

    return $t;
}

=item as_string()

Returnera händelser som språkligt korrekt textsträng.

=cut

sub as_string {
    my $self  = shift;
    my %opt   = @_;

    # Datum för händelsen.
    my $date  = $self->date;

    if ($opt{age}) {
        $date .= " ($opt{age})";
    }

    # Plats för händelsen.
    my $place = $self->place;

    # Adress för händelsen.
    my $address = $self->get_strings("ADDR");
    my $city    = $self->get_value_path("ADDR.CITY");
    $address .= ", $city"     if ($city);
    $place   .= " ($address)" if ($address);

    # Make/maka om det rör sig om en familjehändelse.
    my $spouse;
    if ( $self->parent->tag eq "FAM" && $opt{indi} && $self->tag ne "DIV" ) {
        ($spouse)
            = grep { $_->id ne $opt{indi} }
            grep {$_} ( $self->parent->husband, $self->parent->wife );
        $spouse = $spouse->plainname_refn if ($spouse);
    }

    # Mecka ihop lite olika textsträngar beroende på vilken information vi har
    # tillgänglig.
    my $t;
    if ( $date && $place && $spouse && !$opt{nodate} ) {
        $t = sprintf( "%s %s med %s, i %s", $self->name, $date, $spouse, $place );
    }
    elsif ( $date && $place && !$opt{nodate} ) {
        $t = sprintf( "%s %s i %s", $self->name, $date, $place );
    }
    elsif ( $date && $spouse && !$opt{nodate} ) {
        $t = sprintf( "%s %s med %s", $self->name, $date, $spouse );
    }
    elsif ( $date && !$opt{nodate} ) {
        $t = sprintf( "%s %s", $self->name, $date );
    }
    elsif ( $place && $spouse ) {
        $t = sprintf( "%s med %s, i %s", $self->name, $spouse, $place );
    }
    elsif ($place) {
        $t = sprintf( "%s i %s", $self->name, $place );
    }
    elsif ($spouse) {
        $t = sprintf( "%s med %s", $self->name, $spouse );
    }
    else {
        $t = $self->name;
    }
    return $t;
}

=item as_sentence()

Returnera händelse som mening med korrekt satsbyggnad.

=cut

sub as_sentence {
    my $self = shift;
    return ucfirst( $self->as_string(@_) ) . '. ';
}

1;
