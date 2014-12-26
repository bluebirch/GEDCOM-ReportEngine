# -*- coding: utf-8 -*-

=head1 The Gedcom::Report::Record::Individual package

=over 8

=cut

package Gedcom::Report::Record::Individual;
use base qw(Gedcom::Report::Record);
use strict;
use warnings;
use utf8;
use Gedcom::Report::Locale;
use Gedcom::Report::LaTeX;
use Data::Dumper;

sub parse {
    my $self = shift;

    # Add individual to name index
    if ($self->{global}) {
	$self->{global}->{nameindex}->{$self->plainname} = $self;
    }

    $self->SUPER::parse;
}

### NAME
sub name {
    my $self = shift;
    return $self->get_value( "NAME" );
}

sub fullname {
    my $self = shift;
    my $name = $self->name;
    $name =~ s:/(.*?)/:smallcaps( $1 ):ge;
    $name =~ s:"(.*?)":italic( $1 ):ge;
    return $name;
}

sub plainname {
    my $self = shift;
    my $name = $self->name;
    $name =~ s:[/"]::g;
    return $name;
}

sub plainname_refn {
    my $self = shift;
    return $self->plainname . $self->refnp;
}

sub plainname_year {
    my $self = shift;
    my $name = $self->plainname;
    my $span = $self->lifespan_years;
    return $span ? "$name ($span)" : $name;
}

sub lastname {
    my $self = shift;
    my $name = $self->name;
    $name =~ m:/(.*?)/:;
    return $1 ? $1 : '';
}

sub givenname {
    my $self = shift;
    my $name = $self->name;
    $name =~ s:\s*/.*::;
    $name =~ s:"::g;
    return $name;
}

sub sortname {
    my $self = shift;
    return $self->lastname . ", " . $self->givenname;
}

sub addnametoindex {
    my $self = shift;
    return addtoindex( $self->lastname . '!' . $self->givenname );
}

sub lifespan_years {
    my $self = shift;
    my $birth = $self->get_record( "BIRT" );
    my $death = $self->get_record( "DEAT" );
    if ($birth && $death) {
	return $birth->year . '--' . $death->year;
    }
    elsif ($birth) {
	return Ts( "⁎~%(year)", year => $birth->year );
    }
    elsif ($death) {
	return Ts( "†~%(year)", year => $death->year );
    }
    return ""
}

### ATTRIBUTES

sub sex {
    my $self = shift;
    return $self->get_value( 'SEX' );
}

### EVENTS

sub event {
    my ($self, $tag) = @_;
    my $t = join( '', map { $_->as_String } $self->get_records( $tag ) );
    return $t;
}
sub birth {
    my $self = shift;
    return $self->event( 'BIRT' );
}
sub baptism {
    my $self = shift;
    return $self->event( 'BAPM' );
}
sub death {
    my $self = shift;
    return $self->event( 'DEAT' );
}
sub burial {
    my $self = shift;
    return $self->event( 'BURI' );
}

### FAMILIES
sub fams {
    my $self = shift;
    my @fams =  map { $_->reference } $self->get_records( "FAMS" );
    return @fams;
}
sub famc {
    my $self = shift;
    my $famc =  $self->get_record( "FAMC" );
    return $famc ? $famc->reference : undef;
}
sub father {
    my $self = shift;
    my $famc = $self->famc;
    return $famc ? $self->famc->husband : undef;
}
sub mother {
    my $self = shift;
    my $famc = $self->famc;
    return $famc ? $self->famc->wife : undef;
}
sub children {
    my $self = shift;
    return map { $_->children } $self->fams;
}

### STRINGS

sub notes {
    my $self = shift;
    my %opt = @_;
    my $t = '';
    my @notes = $self->get_records( "NOTE" );
    if (@notes) {
	$t .= $opt{heading} if ($opt{heading});
	for my $i (0..$#notes) {
	    if ($i > 0) {
		$t .= textbreak;
	    }
	    $t .= $notes[$i]->value . p;
	}
    }
    return $t;
}

=pod nameheading()

Write the name as heading, using subsection.

=cut

sub nameheading {
    my $self = shift;
    my $t;
    if ($self->refn) {
	$t = subsection( "[" . $self->refn . "] " . $self->fullname,
			 $self->plainname_year );
    }
    else {
	$t = subsection( $self->fullname, 
			 $self->plainname_year );
    }
    $t .= $self->addnametoindex . label( $self->id );
    return $t;
}


### REPORTS

=pod

=item oneliner()

Returns the full name, reference number (if any), birth date and death
date.

=cut

sub oneliner {
    my $self = shift;

    my $name = $self->plainname_refn;
    my $birth = $self->get_record_path( "BIRT.DATE" );
    my $death = $self->get_record_path( "DEAT.DATE" );
    my $t = '';
    if ($birth && $death) {
	$t = Ts( "%(name), ⁎ %(born), † %(dead).",
		name => $name,
		born => $birth->as_string,
		dead => $death->as_string );
    }
    elsif ($birth) {
	$t = Ts( "%(name), ⁎ %(born).",
		 name => $name,
		 born => $birth->as_string );
    }
    elsif ($death) {
	$t = Ts( "%(name), † %(dead).",
		 name => $name,
		 dead => $death->as_string );
    }
    else {
	$t = Ts( "%(name).",
		 name => $name );
    }
    $t .= $self->addnametoindex;
    return $t;
}

=pod

=item summary()

Returns a summary of the individual, including parents, relations,
children and an eventes table.

=cut

sub summary {
    my $self = shift;
    my %opt = @_;

    $self->reset_places();

    # Name as heading
    my $t = $self->nameheading();

    # Relation
    $t .= ucfirst( decode_relation( $opt{relation} ) ) . '. '
      if ($opt{relation});

    # Just reference if person has already been printed
    if ($self->{global}->{printed}->{$self->id}) {
	$t .= T( "See page~" ) . "\\pageref{" . $self->id . "}" . p;
	return $t;
    }

    # Birth
    $t .= $self->birth();

    # Parents
    $t .= $self->childof();

    # Family events
    foreach my $event (@{$self->collect_events( "MARR", "DIV" )}) {
	$t .= $event->as_String( indi => $self->id );
    }

    # Death
    $t .= $self->death();

    # New paragraph
    $t .= p;

    # Children
    $t .= $self->listofchildren( spouseinfo => $opt{spouseinfo} );

    # Attributes
    $t .= $self->attributes_table( heading => paragraph( T( "Attributes" ) ) );
    $t .= p;

    # Events
    $t .= $self->events_table( heading => paragraph( T( "Chronology" ) ) );

    # Notes
    $t .= $self->notes( heading => paragraph( T( "Notes" ) ) )
      if ($opt{notes});

    # Remember this individual
    $self->{global}->{printed}->{$self->id} = 1;

    return $t;
}

=pod

=item childof()

Return a string like "son/daugher of father and mother".

=cut

sub childof {
    my $self = shift;

    # Parents
    my $father = $self->father;
    my $mother = $self->mother;

    # Son/daughter/child
    my $child;
    if ($self->sex eq 'M') {
	$child = T( "Son" );
    }
    elsif ($self->sex eq 'F') {
	$child = T( "Daughter" );
    }
    else {
	$child = T( "Child" );
    }

    my $t = "";
    if ($father && $mother) {
	$t = Ts( "%(child) of %(father) and %(mother).",
		  child => $child,
		  father => $father->plainname_refn,
		  mother => $mother->plainname_refn );
    }
    elsif ($father) {
	$t = Ts( "%(child) of %(father).",
		  child => $child,
		  father => $father->plainname_refn );
    }
    elsif ($mother) {
	$t = Ts( "%(child) of %(mother).",
		  child => $child,
		  mother => $mother->plainname_refn );
    }
    $t .= ' ' if ($t);
    return $t;
}

=pod

=item listofchildren()

Return list of children.

=cut

sub listofchildren {
    my $self = shift;
    my %opt = @_;

    my $t = '';
    # Children
    my $nchi = 0; # Children counter.
    foreach my $fam (map { $_->reference } $self->get_records( "FAMS" )) {
	my @children = $fam->children;
	if (@children) {

	    # Get spouse
	    my ($spouse) = grep {$_->id ne $self->id}
	      grep {$_} ($fam->husband, $fam->wife );

	    # Display spouse info
	    if ($spouse) {
		if ($opt{spouseinfo}) {
		    $t .= paragraph( $spouse->fullname );
		    $t .= $spouse->birth . $spouse->childof . $spouse->death;
		    $t .= p;
		    $t .= Ts( "Children of %(person) and %(spouse):",
			      person => $self->plainname,
			      spouse => $spouse->plainname );
		}
		else {
		    $t .= Ts( "Children with %(spouse):",
			      spouse => $spouse->plainname );
		}
	    }
	    else {
		$t .= Ts( "Children:" );
	    }

	    # Print list of children
	    $t .= begin_numlist;
	    $t .= "\\setcounter{enumi}{$nchi}\n";
	    foreach my $child (@children) {
		$t .= item( $child->oneliner );
		$nchi++;
	    }
	    $t .= end_numlist . p;
	}
    }
    return $t;
}

=pod

=item ancestors_report( $max_generations )

Return a report containing ancestors.

=cut

sub ancestors_report {
    my $self = shift;
    return $self->_report( "ancestors", @_ );
}

=pod

=item descendants_report( $max_generations )

Return a report containing ancestors.

=cut

sub descendants_report {
    my $self = shift;
    return $self->_report( "descendants", @_ );
}

=pod

=item _report( $type, $max_generations )

Return a report containing ancestors.

=cut

sub _report {
    my $self = shift;
    my $type = shift;
    my %opt = @_;

    my $sub = 'make_' . $type . '_tree';
    my $type_refn = $type . '_refn';
    my $generations = $opt{generations} ? $opt{generations} : 10;

    my $spouseinfo = 0;

    $self->$sub( generations => $generations )
      unless ($self->{$type});

    # Connect global reference number table with this tree.
    $self->{global}->{refn} = $self->{$type_refn};

    my $t;
    if ($type eq 'ancestors') {
	$t = chapter( Ts( "Ancestors of %(name)", name => $self->plainname ) );
    }
    elsif ($type eq 'descendants') {
	$t = chapter( Ts( "Descendants of %(name)", name => $self->plainname ) );
	$spouseinfo = 1;
    }
    else {
	$t = chapter( Ts( "Genealogy report for %(name)", name => $self->plainname ) );
    }

    for my $generation (0..$#{$self->{$type}}) {
	$t .= section( "Generation " . sprintf( '%d', $generation+1 ) ); # Heading

	foreach my $i (@{$self->{$type}->[$generation]}) {
	    $t .= $i->summary( spouseinfo => $spouseinfo,
			       notes => $opt{notes},
			       relation => $self->{relation}->{$i->xref}
			     );
	}
    }
    return $t;
}

=pod

=item make_ancestors_tree( $max_generations )

Build an internal structure of ancestors for each generation.

=cut

sub make_ancestors_tree {
    my $self = shift;
    my %opt = @_;

    # Maximum generations defaults to 10.
    my $max_generations = $opt{generations} ? $opt{generations} : 10;

    # Array-of-Array with generations and individuals. Every
    # generation holds the parents of previous generation.
    @{$self->{ancestors}} = ( [ $self ] );

    # The beginning person gets reference number 1.
    $self->{ancestors_refn}->{$self->id} = 1;

    # Step through all individuals in generation $generation and add
    # their parents to $generation+1.
    my $generation = 0;
    my $refn = 2;
    my $parents; # Holds list of parents.
    do {
	$parents = [];
	foreach my $indi (@{$self->{ancestors}->[$generation]}) {
	    if ($indi->father) {
		push @$parents, $indi->father;

		# Father gets number 2n
		$self->{ancestors_refn}->{$indi->father->id} =
		  $self->{ancestors_refn}->{$indi->id} * 2;

		# Store relation
		$self->set_parental_relation( $indi, $indi->father );
	    }
	    if ($indi->mother) {
		push @$parents, $indi->mother;

		# Mother gets number 2n+1
		$self->{ancestors_refn}->{$indi->mother->id} =
		  $self->{ancestors_refn}->{$indi->id} * 2 + 1;

		# Store relation
		$self->set_parental_relation( $indi, $indi->mother );
	    }
	}

	# Add list of parents to the list of ancestors.
	$generation++;
	$self->{ancestors}->[$generation] = $parents if (@$parents);
    } while (@$parents && $generation < $max_generations-1);
}

sub set_parental_relation {
    my ($self, $person, $parent) = @_;
    my $relation = $self->{relation}->{$person->xref};
    $relation = "" unless ($relation);
    if ($parent->sex eq 'M') {
	$relation .= 'F';
    }
    elsif ($parent->sex eq 'F') {
	$relation .= 'M';
    }
    $self->{relation}->{$parent->xref} = $relation;
}

=pod

=item make_descendants_tree( $max_generations )

Build an internal structure of descendants for each generation.

=cut

sub make_descendants_tree {
    my $self = shift;
    my %opt = @_;

    # Maximum generations defaults to 10
    my $max_generations = $opt{generations} ? $opt{generations} : 10;

    # Array-of-Array with generations and individuals. Each individual
    # holds the children to the individuals in previous generation.
    @{$self->{descendants}} = ( [ $self ] );

    # The beginning person gets reference number 1.
    $self->{descendants_refn}->{$self->id} = 1;

    # Step through all individuals in generation $generation and add
    # their children to $generation+1.
    my $generation = 0;
    my $refn = 2;
    my $children; # Hold list of children
    do {
	$children = [];
	foreach my $indi (@{$self->{descendants}->[$generation]}) {
	    my @children = $indi->children;
	    if (@children) {
		# Lägg barnen till aktuell lista för generation x. Ta
		# bara med de barn som själva har barn.
#		push @$chil, grep { $_->children } @children;
		push @$children, @children;
	    }
	}

	# Add numbers
	if (@$children) {
	    foreach my $indi (@$children) {
		$self->{descendants_refn}->{$indi->id} = $refn++;
	    }
	    $self->{descendants}->[++$generation] = $children;
	}
    } while (@$children && $generation < $max_generations);
}


1;
