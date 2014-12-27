# -*- coding: utf-8 -*-
package GEDCOM::Record;
use strict;
use locale;
use utf8;
use GEDCOM::Locale;
use GEDCOM::LaTeX;
use GEDCOM::Record::Root;
use GEDCOM::Record::Date;
use GEDCOM::Record::Event;
use GEDCOM::Record::Attribute;
use GEDCOM::Record::Place;
use GEDCOM::Record::Individual;
use GEDCOM::Record::Family;
use GEDCOM::Record::Object;
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
%EVENTDESC = (
    ADOP => "adopterad",
    ANUL => "anullering av äktenskap",
    BAPM => "döpt",
    BARM => "Bar Mitzvah",
    BASM => "Bas Mitsva",
    BIRT => "född",
    BLES => "välsignad",
    BURI => "begravd",
    CENS => "folkräkning",
    CHR  => "kristnad",
    CHRA => "vuxendöpt",
    CONF => "konfirmerad",
    CREM => "kremerad",
    DEAT => "död",
    DIV  => "frånskild",
    DIVF => "skilsmässoansökan",
    EMIG => "emigrerade",
    ENGA => "förlovad",
    EVEN => "händelse",
    FCOM => "första nattvard",
    GRAD => "examen",
    IMMI => "immigration",
    MARB => "banns of marriage",
    MARC => "äktenskapsförord",
    MARL => "hindersprövning",
    MARR => "gift",
    MARS => "hemskillnad",
    NATU => "naturalisering",
    ORDN => "ordinerad",
    PROB => "bouppteckning",
    RESI => "bosatt",
    RETI => "pensionerad",
    WILL => "testamente",
);
%TAGNAME = (
    ABBR => "förkortning",
    ADDR => "adress",
    ADR1 => "adress rad 1",
    ADR2 => "adress rad 2",
    ADOP => "adoption",
    AFN  => "Ancestral File Number",
    AGE  => "ålder",
    AGNC => "institution",
    ALIA => "alias",
    ANCE => "anor",
    ANCI => "intressanta anor",
    ANUL => "anullering",
    ASSO => "associationer",
    AUTH => "författare",
    BAPL => "LDS dop",
    BAPM => "dop",
    BARM => "bar mitzvah",
    BASM => "bas mitzvah",
    BIRT => "födelse",
    BLES => "välsignelse",
    BURI => "begravning",
    CALN => "call number",
    CAST => "kast",
    CAUS => "orsak",
    CENS => "folkräkning",
    CHAN => "ändrad",
    CHAR => "character",
    CHIL => "child",
    CHR  => "christening",
    CHRA => "adult christening",
    CITY => "city",
    CONC => "concatenation",
    CONF => "confirmation",
    CONL => "LDS confirmation",
    CONT => "continued",
    COPR => "copyright",
    CORP => "corporate",
    CREM => "cremation",
    CTRY => "country",
    DATA => "data",
    DATE => "date",
    DEAT => "death",
    DESC => "descendants",
    DESI => "descendant interests",
    DEST => "destination",
    DIV  => "divorce",
    DIVF => "divorce filed",
    DSCR => "physical description",
    EDUC => "education",
    EMAI => "email",
    EMIG => "emigration",
    ENDL => "endowment",
    ENGA => "engagement",
    EVEN => "event",
    FACT => "fact",
    FAM  => "family",
    FAMC => "family child",
    FAMF => "family file",
    FAMS => "family spouse",
    FAX  => "facsimile",
    FCOM => "first communion",
    FILE => "file",
    FORM => "format",
    FONE => "phonetic",
    GEDC => "GEDCOM",
    GIVN => "given name",
    GRAD => "graduation",
    HEAD => "header",
    HUSB => "husband",
    IDNO => "personnummer",
    IMMI => "immigration",
    INDI => "individual",
    LANG => "language",
    LATI => "latitued",
    LONG => "longitude",
    MAP  => "map",
    MARB => "marriage bann",
    MARC => "marriage contract",
    MARL => "marriage license",
    MARR => "marriage",
    MARS => "marriage settlement",
    MEDI => "media",
    NAME => "name",
    NATI => "nationality",
    NATU => "naturalization",
    NCHI => "children count",
    NICK => "nickname",
    NMR  => "marriage count",
    NOTE => "note",
    NPFX => "name prefix",
    NSFX => "name suffix",
    OBJE => "object",
    OCCU => "yrke",
    ORDI => "ordinance",
    ORDN => "ordination",
    PAGE => "page",
    PEDI => "pedigree",
    PHON => "phone",
    PLAC => "place",
    POST => "postal code",
    PROB => "probate",
    PROP => "property",
    PUBL => "publication",
    QUAY => "quality of data",
    REFN => "reference",
    RELA => "relationship",
);

sub new {
    my $this = shift;
    my $class = ref($this) || $this;

    my ( $level, $tag, $id, $value, $global ) = @_;

    my $self = {
        level      => $level,
        tag        => $tag,
        subrecords => [],
        index      => {}
    };

    $self->{id}     = $id     if ($id);
    $self->{value}  = $value  if ($value);
    $self->{global} = $global if ($global);

    if ( $tag eq '_ROOT' ) {
        $class .= '::Root';
    }
    elsif ( $tag eq 'DATE' ) {
        $class .= '::Date';
    }
    elsif ( $tag eq 'INDI' ) {
        $class .= '::Individual';
    }
    elsif ( $tag eq 'FAM' ) {
        $class .= '::Family';
    }
    elsif ( $tag eq 'PLAC' ) {
        $class .= '::Place';
    }
    elsif ( $tag eq 'OBJE' && $level == 0) {
         $class .= '::Object';
    }
    elsif ( grep m/$tag/, @EVENTS ) {
        $class .= '::Event';
    }
    elsif ( grep m/$tag/, @ATTRIBUTES ) {
        $class .= '::Attribute';
    }

    bless $self, $class;

    # Add record to global index
    if ( $self->{id} && $self->{level} == 0 && $self->{global} ) {
        $self->{global}->{xref}->{ $self->{id} } = $self;
    }

    return $self;
}

sub parse {
    my $self = shift;

    # Check if this record is a reference to another record and add
    # record from index.
    foreach my $subrecord ( @{ $self->{subrecords} } ) {
        $subrecord->parse();
    }
}

=item get_value( $tag )

Return values of subrecords of type $tag. In scalar mode, return the first
value only.

=cut

sub get_value {
    my $self = shift;
    my @value = map( $_->value, $self->get_records(@_) );

    # In scalar mode, return only the first element (if it exists).
    return wantarray ? @value : ( $value[0] || '' );
}

=item get_record( $tag )

Return the first subrecord of type $tag.

=cut

sub get_record {
    my $self   = shift;
    my $record = $self->get_records(@_);
    return $record;
}

=item get_records( $tag )

Return subrecords of type $tag. In scalar mode, return the first subrecord
only.

=cut

sub get_records {
    my $self = shift;

    # Get subrecords with specified tags.
    my @records = map( $self->{subrecords}->[$_],
        sort { $a <=> $b }
        map( @{ $self->{index}->{$_} }, grep( $self->{index}->{$_}, @_ ) )
    );
    return wantarray ? @records : ( $records[0] || undef );
}

##############################################################################

sub value {
    my $self = shift;
    my $value = $self->{value} ? $self->{value} : '';
    if ( $self->{index}->{CONC} || $self->{index}->{CONT} ) {
        foreach my $subrecord ( $self->get_records( 'CONC', 'CONT' ) ) {
            if ( $subrecord->tag eq 'CONC' ) {
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

sub as_sentence {
    my $self = shift;
    return uc( $self->value ) . '. ';
}

sub tag {
    my $self = shift;
    return $self->{tag} ? $self->{tag} : '';
}

sub tagname {
    my $self = shift;
    return $TAGNAME{ $self->tag } ? $TAGNAME{ $self->tag } : $self->tag;
}

sub id {
    my $self = shift;
    my $id   = $self->{id};
    if ($id) {
        $id =~ s/@//g;
        return $id;
    }
    return '';
}

sub refn {
    my $self = shift;
    return
           $self->{global}
        && $self->{global}->{refn}
        && $self->{global}->{refn}->{ $self->id }
        ? $self->{global}->{refn}->{ $self->id }
        : '';
}

sub refnp {
    my $self = shift;
    return $self->refn ? " [" . $self->refn . "]" : '';
}

sub xref {
    my $self = shift;
    return $self->id;
}

=item reference()

Check if record is a reference to another record. In that case,
return the referenced record.

This should perhaps be called "dereference" for clarity...

=cut

sub reference {
    my $self = shift;
    return $self->{global}->{xref}->{ $self->value };
}

# Create and return sort key
sub sortkey {
    my $self = shift;
    unless ( $self->{sortkey} ) {
        my $key  = '';
        my $date = $self->get_record("DATE");
        if ($date) {
            $key .= $date->sortkey;
        }
        $key .= $self->tag;
        $self->{sortkey} = $key;

        #   print "Created sort key $key\n";
    }
    return $self->{sortkey};
}

##############################################################################

# sub get_path {
#     my ($self, @path) = @_;
#     return '' unless (@path);
#     @path = map( split( m/\./, $_ ), @path );
#     my $tag = shift @path;
#     if (@path) {
#   return map( $_->get_path( @path ), $self->get_record( $tag ) );
#     }
#     else {
#   return $self->get_value( $tag );
#     }
# }

=item get_record_path( $tag_path )

Return records for specified subrecord path, for example FAM.MARR or
FILE.TITL.

=cut

sub get_record_path {
    my ( $self, $path ) = @_;
    return '' unless ($path);
    my ( $tag, $rest ) = split( m/\./, $path, 2 );
    my @res;

    # If there is a rest, we should dig deeper
    if ($rest) {

        # If the current tag is a reference to another record, we
        # resolve this via the xref index.
        my @subrecords = $self->get_records($tag);
        for my $i ( 0 .. $#subrecords ) {
            $subrecords[$i] = $subrecords[$i]->reference
                if ( $subrecords[$i]->reference );
        }
        @res = map( $_->get_record_path($rest), @subrecords );
    }
    else {
        @res = $self->get_records($tag);
    }
    return wantarray ? @res : ( $res[0] || '' );
}

=item get_value_path ()

Return values from specified subrecord path (see get_value_record above).

=cut

sub get_value_path {
    my ( $self, $path ) = @_;
    my @res = map( $_->value, $self->get_record_path($path) );
    return wantarray ? @res : ( $res[0] || '' );
}

sub get_string {
    my $self = shift;
    my @res = map( $_->as_string, $self->get_record_path(@_) );
    return ( $res[0] || '' );
}

sub get_strings {
    my $self = shift;
    my @res = map( $_->as_string, $self->get_record_path(@_) );
    return wantarray ? @res : ( $res[0] || '' );
}

### RESET PLACE MEMORY (see Place.pm)

sub reset_places {
    my $self = shift;
    $self->{global}->{lastplace} = undef;
}

### HANDLE SUBRECORDS AND PARENTS

sub add_subrecord {
    my ( $self, $subrecord ) = @_;

    # Add parent to subrecord
    $subrecord->{parent} = $self;

    # Add record to list of subrecords
    push @{ $self->{subrecords} }, $subrecord;

    # Add entry in index of subrecords
    push @{ $self->{index}->{ $subrecord->tag } }, $#{ $self->{subrecords} };

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
    foreach my $subrecord ( @{ $self->{subrecords} } ) {
        push @events, $subrecord
            if ( grep m/$subrecord->{tag}/, @match_events );
    }

    # Get family events
    my @fams = map { $_->reference } $self->get_records("FAMS");
    foreach my $fam (@fams) {
        my $fam_events = $fam->collect_events(@match_events);
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
    foreach my $subrecord ( @{ $self->{subrecords} } ) {
        push @attributes, $subrecord
            if ( grep m/$subrecord->{tag}/, @match_attributes );
    }
    @attributes = sort { $a->sortkey cmp $b->sortkey } @attributes;
    return \@attributes;
}

=pod

=item listofevents()

Gör en numrerad lista med händelser, i kronologisk ordning.

=cut

sub listofevents {
    my $self   = shift;
    my %opt    = @_;
    my $events = $self->collect_events;

    return "" unless (@$events);    # No events, no table.

    # Only known events, no table.
    return ""
        unless ( grep { $_ !~ m/^(BIRT|MARR|DIV|DEAT)$/ }
        map { $_->tag } @$events );

    $self->reset_places;

    my $t = $opt{heading} ? "$opt{heading}\n\n" : '';

    # Get birth date
    my $birth = $self->get_record_path("BIRT.DATE");

    my $n = 1;
    foreach my $event (@$events) {

        # Calculate age
        my $age = '';
        if ( $birth && $event->tag ne "BIRT" && $event->tag ne "BURI" ) {
            $age = $birth->delta( $event->get_record("DATE") );
        }

        # Add table row
        $t .= sprintf( "%2d. %s\n", $n++, $event->as_sentence( nodate => 0, indi => $self->id, age => $age ) );
    }
    $t .= "\n";
    return $t;
}

=pod

=item listofattributes()

Return attributes as a table.

=cut

sub listofattributes {
    my $self       = shift;
    my %opt        = @_;
    my $attributes = $self->collect_attributes;

    return "" unless (@$attributes);    # No attributes, no table.

    $self->reset_places;

    my $t = $opt{heading} ? "$opt{heading}\n\n" : '';

    #$t .= begin_table('@{}lX@{}');

    foreach my $attribute (@$attributes) {
        $t .= sprintf( "  - *%s:* %s\n", ucfirst( $attribute->tagname ), $attribute->as_sentence );
    }
    $t .= "\n";
    return $t;
}

### Source strings.

sub as_source {
    my $self = shift;
    my $t    = $self->sourceline;
    foreach my $subrecord ( @{ $self->{subrecords} } ) {
        $t .= $subrecord->as_source;
    }
    return $t;
}

sub sourceline {
    my $self = shift;
    my $t    = "  " x $self->{level} . $self->{level};
    $t .= " " . $self->{id}    if ( $self->{id} );
    $t .= " " . $self->{tag};
    $t .= " " . $self->{value} if ( $self->{value} );
    $t .= "\n";
    return $t;
}

1;
