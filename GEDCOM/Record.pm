# -*- coding: utf-8 -*-
package Gedcom::Report::Record;
use strict;
use locale;
use utf8;
use Gedcom::Report::Locale;
use Gedcom::Report::LaTeX;
use Gedcom::Report::Record::Root;
use Gedcom::Report::Record::Date;
use Gedcom::Report::Record::Event;
use Gedcom::Report::Record::Attribute;
use Gedcom::Report::Record::Place;
use Gedcom::Report::Record::Individual;
use Gedcom::Report::Record::Family;
use Data::Dumper;

our @EVENTS;
our @ATTRIBUTES;
our %EVENTDESC;
our %TAGNAME;

#INIT {
    @EVENTS = qw(BIRT CHR DEAT BURI CREM ADOP BAPM BARM BASM BLES CHRA
                 CONF FCOM ORDN NATU EMIG IMMI CENS PROB WILL GRAD
                 RETI EVEN ANUL CENS DIV DIVF ENGA MARB MARC MARR MARL
                 MARS RESI);
    @ATTRIBUTES = qw(CAST DSCR EDUC IDNO NATI NCHI NMR OCCU PROP RELI
                     SSN TITL FACT);
    %EVENTDESC = ( ADOP => T( "adpopted" ),
		   ANUL => T( "marriage anullment" ),
		   BAPM => T( "baptized" ),
		   BARM => T( "Bar Mitzvah" ),
		   BASM => T( "Bas Mitsva" ),
		   BIRT => T( "born" ),
		   BLES => T( "blessed" ),
		   BURI => T( "buried" ),
		   CENS => T( "census" ),
		   CHR  => T( "christened" ),
		   CHRA => T( "adult christened" ),
		   CONF => T( "confirmed" ),
		   CREM => T( "cremated" ),
		   DEAT => T( "died" ),
		   DIV  => T( "divorced" ),
		   DIVF => T( "filed divorce" ),
		   EMIG => T( "emigrated" ),
		   ENGA => T( "engaged" ),
		   EVEN => T( "event" ),
		   FCOM => T( "first communion" ),
		   GRAD => T( "graduated" ),
		   IMMI => T( "immigrated" ),
		   MARB => T( "banns of marriage" ),
		   MARC => T( "contract of marriage" ),
		   MARL => T( "marriage licence" ),
		   MARR => T( "married" ),
		   MARS => T( "marriage settlement" ),
		   NATU => T( "naturalization" ),
		   ORDN => T( "ordinated" ),
		   PROB => T( "probated" ),
		   RESI => T( "resided" ),
		   RETI => T( "retired" ),
		   WILL => T( "will" ),
		 );
%TAGNAME = ( ABBR => T( "abbreviation" ),
	     ADDR => T( "address" ),
	     ADR1 => T( "address line 1" ),
	     ADR2 => T( "address line 2" ),
	     ADOP => T( "adoption" ),
	     AFN  => T( "Ancestral File Number" ),
	     AGE  => T( "age" ),
	     AGNC => T( "agency" ),
	     ALIA => T( "alias" ),
	     ANCE => T( "ancestors" ),
	     ANCI => T( "ancestors interest" ),
	     ANUL => T( "annulment" ),
	     ASSO => T( "associates" ),
	     AUTH => T( "author" ),
	     BAPL => T( "LDS baptism" ),
	     BAPM => T( "baptism" ),
	     BARM => T( "bar mitzvah" ),
	     BASM => T( "bas mitzvah" ),
	     BIRT => T( "birth" ),
	     BLES => T( "blessing" ),
	     BURI => T( "burial" ),
	     CALN => T( "call number" ),
	     CAST => T( "caste" ),
	     CAUS => T( "cause" ),
	     CENS => T( "census" ),
	     CHAN => T( "change" ),
	     CHAR => T( "character" ),
	     CHIL => T( "child" ),
	     CHR  => T( "christening" ),
	     CHRA => T( "adult christening" ),
	     CITY => T( "city" ),
	     CONC => T( "concatenation" ),
	     CONF => T( "confirmation" ),
	     CONL => T( "LDS confirmation" ),
	     CONT => T( "continued" ),
	     COPR => T( "copyright" ),
	     CORP => T( "corporate" ),
	     CREM => T( "cremation" ),
	     CTRY => T( "country" ),
	     DATA => T( "data" ),
	     DATE => T( "date" ),
	     DEAT => T( "death" ),
	     DESC => T( "descendants" ),
	     DESI => T( "descendant interests" ),
	     DEST => T( "destination" ),
	     DIV  => T( "divorce" ),
	     DIVF => T( "divorce filed" ),
	     DSCR => T( "physical description" ),
	     EDUC => T( "education" ),
	     EMAI => T( "email" ),
	     EMIG => T( "emigration" ),
	     ENDL => T( "endowment" ),
	     ENGA => T( "engagement" ),
	     EVEN => T( "event" ),
	     FACT => T( "fact" ),
	     FAM  => T( "family" ),
	     FAMC => T( "family child" ),
	     FAMF => T( "family file" ),
	     FAMS => T( "family spouse" ),
	     FAX  => T( "facsimile" ),
	     FCOM => T( "first communion" ),
	     FILE => T( "file" ),
	     FORM => T( "format" ),
	     FONE => T( "phonetic" ),
	     GEDC => T( "GEDCOM" ),
	     GIVN => T( "given name" ),
	     GRAD => T( "graduation" ),
	     HEAD => T( "header" ),
	     HUSB => T( "husband" ),
	     IDNO => T( "identification number" ),
	     IMMI => T( "immigration" ),
	     INDI => T( "individual" ),
	     LANG => T( "language" ),
	     LATI => T( "latitued" ),
	     LONG => T( "longitude" ),
	     MAP  => T( "map" ),
	     MARB => T( "marriage bann" ),
	     MARC => T( "marriage contract" ),
	     MARL => T( "marriage license" ),
	     MARR => T( "marriage" ),
	     MARS => T( "marriage settlement" ),
	     MEDI => T( "media" ),
	     NAME => T( "name" ),
	     NATI => T( "nationality" ),
	     NATU => T( "naturalization" ),
	     NCHI => T( "children count" ),
	     NICK => T( "nickname" ),
	     NMR  => T( "marriage count" ),
	     NOTE => T( "note" ),
	     NPFX => T( "name prefix" ),
	     NSFX => T( "name suffix" ),
	     OBJE => T( "object" ),
	     OCCU => T( "occupation" ),
	     ORDI => T( "ordinance" ),
	     ORDN => T( "ordination" ),
	     PAGE => T( "page" ),
	     PEDI => T( "pedigree" ),
	     PHON => T( "phone" ),
	     PLAC => T( "place" ),
	     POST => T( "postal code" ),
	     PROB => T( "probate" ),
	     PROP => T( "property" ),
	     PUBL => T( "publication" ),
	     QUAY => T( "quality of data" ),
	     REFN => T( "reference" ),
	     RELA => T( "relationship" ),
	   );

sub new {
    my $this = shift;
    my $class = ref($this) || $this;

    my ($level, $tag, $id, $value, $global) = @_;

    my $self = { level      => $level,
		 tag        => $tag,
		 subrecords => [],
		 index      => {}
	       };

    $self->{id} = $id if ($id);
    $self->{value} = $value if ($value);
    $self->{global} = $global if ($global);

    if ($tag eq '_ROOT') {
	$class .= '::Root';
    }
    elsif ($tag eq 'DATE') {
	$class .= '::Date';
    }
    elsif ($tag eq 'INDI') {
	$class .= '::Individual';
    }
    elsif ($tag eq 'FAM') {
	$class .= '::Family';
    }
    elsif ($tag eq 'PLAC') {
	$class .= '::Place';
    }
    elsif (grep m/$tag/, @EVENTS) {
	$class .= '::Event';
    }
    elsif (grep m/$tag/, @ATTRIBUTES) {
	$class .= '::Attribute';
    }

    bless $self, $class;

    # Add record to global index
    if ($self->{id} && $self->{level} == 0 && $self->{global}) {
	$self->{global}->{xref}->{$self->{id}} = $self;
    }

    return $self;
}

sub parse {
    my $self = shift;
    # Check if this record is a reference to another record and add
    # record from index.
    foreach my $subrecord (@{$self->{subrecords}}) {
	$subrecord->parse();
    }
}

sub get_value {
    my $self = shift;
    my @value = map( $_->value, $self->get_records( @_ ) );

    # In scalar mode, return only the first element (if it exists).
    return wantarray ? @value : ( $value[0] || '' );
}

sub get_record {
    my $self = shift;
    my $record = $self->get_records( @_ );
    return $record;
}

sub get_records {
    my $self = shift;

    # Get subrecords with specified tags.
    my @records =  map( $self->{subrecords}->[$_],
			sort {$a <=> $b} map( @{$self->{index}->{$_}}, 
					      grep( $self->{index}->{$_}, @_ )
					    )
		      );
    return wantarray ? @records : ($records[0] || undef);
}

##############################################################################

sub value {
    my $self = shift;
    my $value = $self->{value} ? $self->{value} : '';
    if ($self->{index}->{CONC} || $self->{index}->{CONT}) {
	foreach my $subrecord ($self->get_records( 'CONC', 'CONT' )) {
	    if ($subrecord->tag eq 'CONC') {
		$value .= $subrecord->value;
	    }
	    else {
		$value .= "\n" . $subrecord->value;
	    }
	}
    }
    return $value;
}

sub as_string {
    my $self = shift;
    return $self->value;
}

sub as_String {
    my $self = shift;
    return uc( $self->value ) . '. ';
}

sub tag {
    my $self = shift;
    return $self->{tag} ? $self->{tag} : '';
}

sub tagname {
    my $self = shift;
    return $TAGNAME{$self->tag} ? $TAGNAME{$self->tag} : $self->tag;
}

sub id {
    my $self = shift;
    my $id = $self->{id};
    if ($id) {
	$id =~ s/@//g;
	return $id;
    }
    return '';
}

sub refn {
    my $self = shift;
    return $self->{global} && $self->{global}->{refn} 
      && $self->{global}->{refn}->{$self->id} ? 
	$self->{global}->{refn}->{$self->id} : '';
}

sub refnp {
    my $self = shift;
    return $self->refn ? " [" . $self->refn . "]" : '';
}

sub xref {
    my $self = shift;
    return $self->id;
}

# Check if record is a reference to another record. In that case,
# return the referenced record.
sub reference {
    my $self = shift;
    return $self->{global}->{xref}->{$self->value};
}

# Create and return sort key
sub sortkey {
    my $self = shift;
    unless ($self->{sortkey}) {
	my $key = '';
	my $date = $self->get_record( "DATE" );
	if ($date) {
	    $key .= $date->sortkey;
	}
	$key .= $self->tag;
	$self->{sortkey} = $key;
#	print "Created sort key $key\n";
    }
    return $self->{sortkey}
}

##############################################################################

# sub get_path {
#     my ($self, @path) = @_;
#     return '' unless (@path);
#     @path = map( split( m/\./, $_ ), @path );
#     my $tag = shift @path;
#     if (@path) {
# 	return map( $_->get_path( @path ), $self->get_record( $tag ) );
#     }
#     else {
# 	return $self->get_value( $tag );
#     }
# }

sub get_record_path {
    my ($self, $path) = @_;
    return '' unless ($path);
    my ($tag, $rest) = split( m/\./, $path, 2 );
    my @res;

    # If there is a rest, we should dig deeper
    if ($rest) {

	# If the current tag is a reference to another record, we
	# resolve this via the xref index.
	my @subrecords = $self->get_records( $tag );
	for my $i (0..$#subrecords) {
	    $subrecords[$i] = $subrecords[$i]->reference if ($subrecords[$i]->reference);
	}
	@res = map( $_->get_record_path( $rest ), @subrecords );
    }
    else {
	@res = $self->get_records( $tag );
    }
    return wantarray ? @res : ($res[0] || '');
}

sub get_value_path {
    my ($self, $path) = @_;
    my @res = map( $_->value, $self->get_record_path( $path ) );
    return wantarray ? @res : ($res[0] || '');
}

sub get_string {
    my $self = shift;
    my @res = map( $_->as_string, $self->get_record_path( @_ ) );
    return ($res[0] || '');
}

sub get_strings {
    my $self = shift;
    my @res = map( $_->as_string, $self->get_record_path( @_ ) );
    return wantarray ? @res : ($res[0] || '');
}

### RESET PLACE MEMORY (see Place.pm)

sub reset_places {
    my $self = shift;
    $self->{global}->{lastplace} = undef;
}

### HANDLE SUBRECORDS AND PARENTS

sub add_subrecord {
    my ($self, $subrecord) = @_;

    # Add parent to subrecord
    $subrecord->{parent} = $self;

    # Add record to list of subrecords
    push @{$self->{subrecords}}, $subrecord;

    # Add entry in index of subrecords
    push @{$self->{index}->{$subrecord->tag}}, $#{$self->{subrecords}};

}

sub parent {
    my $self = shift;
    return $self->{parent};
}

# sub sort_subrecords {
#     my $self = shift;
#     @{$self->{subrecords}} = sort { $a->{tag} cmp $b->{tag} } @{$self->{subrecords}};
#     return 1;
# }

### Event handling.

=pod

=item collect_events( @events )

Collect events specified in the @events array, including family
events. If no events are specified, all events are collected.

=cut

sub collect_events {
    my $self = shift;
    my @match_events = @_ ? @_ : @EVENTS;
    my @events;
    foreach my $subrecord (@{$self->{subrecords}}) {
	push @events, $subrecord if (grep m/$subrecord->{tag}/, @match_events);
    }
    # Get family events
    my @fams = map { $_->reference } $self->get_records( "FAMS" );
    foreach my $fam (@fams) {
	my $fam_events = $fam->collect_events( @match_events );
	push @events, @$fam_events;
    }
    @events = sort { $a->sortkey cmp $b->sortkey } @events;
    return \@events;
}

=pod

=item collect_attributes( @attributes )

Collect attributes specified in the @attributes array.  If no
attributes are specified, all attributes are collected.

=cut

sub collect_attributes {
    my $self = shift;
    my @match_attributes = @_ ? @_ : @ATTRIBUTES;
    my @attributes;
    foreach my $subrecord (@{$self->{subrecords}}) {
	push @attributes, 
	  $subrecord if (grep m/$subrecord->{tag}/, @match_attributes);
    }
    @attributes = sort { $a->sortkey cmp $b->sortkey } @attributes;
    return \@attributes;
}

=pod

=item events_table()

Return events as a table.

=cut

sub events_table {
    my $self = shift;
    my %opt = @_;
    my $events = $self->collect_events;

    return "" unless (@$events); # No events, no table.

    # Only known events, no table.
    return ""
      unless (grep { $_ !~ m/^(BIRT|MARR|DIV|DEAT)$/ } map { $_->tag } @$events);

    $self->reset_places;

    my $t = $opt{heading} ? $opt{heading} . "~" : '';

    $t .= begin_table( '@{}llX@{}' );

    # Get birth date
    my $birth = $self->get_record_path( "BIRT.DATE" );

    foreach my $event (@$events) {

	# Calculate age
	my $age = '';
	if ($birth && $event->tag ne "BIRT" && $event->tag ne "BURI") {
	    $age = $birth->delta( $event->get_record( "DATE" ) );
	}

	# Add table row
	$t .= tablerow( $event->isodate,
			$age,
			$event->as_String( nodate => 1, indi => $self->id )
		      );
    }
    $t .= end_table;
    return $t;
}

=pod

=item attributes_table()

Return attributes as a table.

=cut

sub attributes_table {
    my $self = shift;
    my %opt = @_;
    my $attributes = $self->collect_attributes;

    return "" unless (@$attributes); # No attributes, no table.

    $self->reset_places;

    my $t = $opt{heading} ? $opt{heading} . "~" : '';

    $t .= begin_table( '@{}lX@{}' );

    foreach my $attribute (@$attributes) {

	$t .= tablerow( ucfirst $attribute->tagname . ':', $attribute->as_String );
    }
    $t .= end_table;
    return $t;
}

### Source strings.

sub as_source {
    my $self = shift;
    my $t = $self->sourceline;
    foreach my $subrecord (@{$self->{subrecords}}) {
	$t .= $subrecord->as_source;
    }
    return $t;
}

sub sourceline {
    my $self = shift;
    my $t = "  " x $self->{level} . $self->{level};
    $t .= " " . $self->{id} if ($self->{id});
    $t .= " " . $self->{tag};
    $t .= " " . $self->{value} if ($self->{value});
    $t .= "\n";
    return $t;
}


1;
