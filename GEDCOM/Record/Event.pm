# -*- coding: utf-8 -*-
package Gedcom::Report::Record::Event;
use base qw(Gedcom::Report::Record);
use strict;
use warnings;
use utf8;
use Gedcom::Report::Locale;
use Gedcom::Report::LaTeX;

### DATES OF EVENT

sub date {
    my $self = shift;
    return $self->get_strings( "DATE" );
}
sub isodate {
    my $self = shift;
    my $date = $self->get_record( "DATE" );
    return $date ? $date->isodate : '';
}
sub year {
    my $self = shift;
    my $date = $self->get_record( "DATE" );
    return $date ? $date->year : '';
}
sub place {
    my $self = shift;
    my $place = $self->get_record( "PLAC" );
    return $place ? $place->shortname : '';
}

### NAME OF EVENT

sub name {
    # The name of the event should also consider the value field,
    # especially for OCCU and EVEN records.
    my $self = shift;
    my $name = ($Gedcom::Report::Record::EVENTDESC{$self->tag} || $self->tag);
    my $value = $self->value;
    my $type = $self->get_value( "TYPE" );
    my $cause = $self->get_value( "CAUS" );

    my $t;
    if ($value && $type) {
	$t = "$type ($value)"
    }
    elsif ($value) {
	$t = $value
    }
    elsif ($type) {
	$t = $type
    }
    else {
	$t = $name;
    }
    $t .= Ts( " from %(cause)", cause => lc $cause ) if ($cause);

    return $t;
}

sub as_string {
    my $self = shift;
    my %opt = @_;
    my $date = $self->date;
    my $place = $self->place;

    my $address = $self->get_strings( "ADDR" );
    my $city = $self->get_value_path( "ADDR.CITY" );
    $address .= ", $city" if ($city);
    $place .= " ($address)" if ($address);

    my $spouse;
    if ($self->parent->tag eq "FAM" && $opt{indi} && $self->tag ne "DIV") {
	($spouse) = grep {$_->id ne $opt{indi}} grep {$_} ($self->parent->husband, $self->parent->wife );
	$spouse = $spouse->plainname_refn if ($spouse);
    }

    my $t;
    if ($date && $place && $spouse && !$opt{nodate}) {
	$t = Ts( "%(event) %(date) with %(spouse), in %(place)",
		 event => $self->name,
		 date => $date,
		 spouse => $spouse,
		 place => $place );
    }
    elsif ($date && $place && !$opt{nodate}) {
	$t = Ts( "%(event) %(date) in %(place)",
		 event => $self->name,
		 date => $date,
		 place => $place );
    }
    elsif ($date && $spouse && !$opt{nodate}) {
	$t = Ts( "%(event) %(date) with %(spouse)",
		 event => $self->name,
		 date => $date,
		 spouse => $spouse );
    }
    elsif ($date && !$opt{nodate}) {
	$t = Ts( "%(event) %(date)",
		 event => $self->name,
		 date => $date );
    }
    elsif ($place && $spouse) {
	$t = Ts( "%(event) with %(spouse), in %(place)",
		 event => $self->name,
		 spouse => $spouse,
		 place => $place );
    }
    elsif ($place) {
	$t = Ts( "%(event) in %(place)",
		 event => $self->name,
		 place => $place );
    }
    elsif ($spouse) {
	$t = Ts( "%(event) with %(spouse)",
		 event => $self->name,
		 spouse => $spouse );
    }
    else {
	$t = Ts( "%(event)",
		 event => $self->name );
    }
    return $t;
}

sub as_String {
    my $self = shift;
    return ucfirst( $self->as_string( @_ ) ) . '. ';
}

1;
