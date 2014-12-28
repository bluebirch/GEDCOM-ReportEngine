package GEDCOM::Record;

=head1 GEDCOM::Record

The base class for all types of GEDCOM records.

=cut

use strict;
use locale;
use utf8;
use GEDCOM::Record::Root;
use GEDCOM::Record::Date;
use GEDCOM::Record::Event;
use GEDCOM::Record::Attribute;
use GEDCOM::Record::Place;
use GEDCOM::Record::Individual;
use GEDCOM::Record::Family;
use GEDCOM::Record::Object;
use GEDCOM::Record::Source;
use Data::Dumper;

our @EVENTS;
our @ATTRIBUTES;
our %EVENTDESC;
our %TAGNAME;

=head2 Global Variables

=over 4

=item C<@EVENTS>

The C<@EVENTS> variable holds a list of all record types that should be
regarded as events. They are parsed as the subclass C<GEDCOM::Record::Event>.

See the GEDCOM 5.5.1 specification page 34.

=cut

@EVENTS = qw(BIRT CHR DEAT BURI CREM ADOP BAPM BARM BASM BLES CHRA
    CONF FCOM ORDN NATU EMIG IMMI CENS PROB WILL GRAD
    RETI EVEN ANUL CENS DIV DIVF ENGA MARB MARC MARR MARL
    MARS RESI);

=item C<@ATTRIBUTES>

The C<@ATTRIBUTES> variable holds a list of all record types that are
attributes. They are parsed as the subclass C<GEDCOM::Record::Attribute>.

See the GEDCOM 5.5.1 specification page 33.

=cut

@ATTRIBUTES = qw(CAST DSCR EDUC IDNO NATI NCHI NMR OCCU PROP RELI
    SSN TITL FACT);

=item C<%EVENTDESC>

This variable holds the descriptions of events, currently only in Swedish (I
had a multilingual function, but I removed it).

=cut

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

=item C<%TAGNAME>

All GEDCOM tags and their names. In Swedish.

=cut

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

=back

=head2 Class Constructor

=over 4

=item C<new( $level, $tag, $id, $value, $global )>

Create a new record of type C<$tag> at level C<$level> with C<@XREF@> C<$id> (if
available) and value C<$value> (if available). The C<$global> structure should
be explained somewhere.

=cut

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
    elsif ( $tag eq 'SOUR' && $level == 0) {
         $class .= '::Source';
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

=item parse()

I'm not sure what this one does...

=cut

sub parse {
    my $self = shift;

    # Check if this record is a reference to another record and add
    # record from index.
    foreach my $subrecord ( @{ $self->{subrecords} } ) {
        $subrecord->parse();
    }
}

=back

=head2 Subrecord Access Methods

=over 4

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

=item C<get_records( $tag )>

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

=back

=head2 Data Access Methods

=over 4

=item C<value()>

Return record value (if any). Concatenate subrecords automatically.

=cut

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

=item C<as_string()>

In this base class, this is simply a call to C<$self->value()>. Subclasses
might do other things.

=cut

sub as_string {
    my $self = shift;
    return $self->value;
}

=item C<as_sentence()>

Return C<as_string()> with leading capital letter and ending full stop, thus
making it 'sentence-like'.

=cut

sub as_sentence {
    my $self = shift;
    return uc( $self->value ) . '. ';
}

=item C<tag()>

Return the GEDCOM tag (record type) for this record.

=cut

sub tag {
    my $self = shift;
    return $self->{tag} ? $self->{tag} : '';
}

=item C<tagname()>

Return the GEDCOM tag (record type) in readable format; this is where the
global variable C<%TAGNAME> is used.

=cut

sub tagname {
    my $self = shift;
    return $TAGNAME{ $self->tag } ? $TAGNAME{ $self->tag } : $self->tag;
}

=item C<id()>

Return the GEDCOM xref id, with C<@>-characters stripped. A synonym for this
function is C<xref()> (see below).

=cut

sub id {
    my $self = shift;
    my $id   = $self->{id};
    if ($id) {
        $id =~ s/@//g;
        return $id;
    }
    return '';
}

=item C<xref()>

Simply a call to C<id()> (see above), but aligns with proper GEDCOM
terminology.

=cut

sub xref {
    my $self = shift;
    return $self->id;
}

=back

=head2 Internal Reference Numbers

=over 4

=item C<refn()>

Internal reference number, if it exists. These are set by
C<GEDCOM::Record::Individual->make_ancestors_tree> and
C<GEDCOM::Record::Individual->make_descendatns_tree>. Before building either
tree, this methods returns nothing.

=cut

sub refn {
    my $self = shift;
    return
           $self->{global}
        && $self->{global}->{refn}
        && $self->{global}->{refn}->{ $self->id }
        ? $self->{global}->{refn}->{ $self->id }
        : '';
}

=item C<refnp()>

As C<refn()> above, but add brackets, like: "[4]".

This is perhaps where I should add internal references.

=cut

sub refnp {
    my $self = shift;
    return $self->refn ? " [" . $self->refn . "]" : '';
}

=back

=head2 References to Other Records

=over 4

=item C<dereference()>, C<reference()>

Check if record is a reference to another record. In that case,
return the referenced record.

C<reference()> is an deprecated name that should be replaced with calls to
C<dereference()>.

=cut

sub dereference {
    my $self = shift;
    return $self->{global}->{xref}->{ $self->value };
}

sub reference {
    my $self = shift;
    #print STDERR "call to reference() is deprecated, use dereference() instead\n";
    return $self->dereference();
}

=back

=head2 Sorting

=over 4

=item C<sortkey()>

Return sort key, for sorting events.

=cut

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

=back

=head2 Subrecord Paths

=over 4

=item C<get_record_path( $tag_path )>

Return records for specified subrecord path, for example C<FAM.MARR> or
C<FILE.TITL>.

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

=item C<get_value_path ()>

Return values from specified subrecord path (see get_value_record above).

=cut

sub get_value_path {
    my ( $self, $path ) = @_;
    my @res = map( $_->value, $self->get_record_path($path) );
    return wantarray ? @res : ( $res[0] || '' );
}

=item C<get_string()>

Like C<get_value_path()>, but returns C<as_string()> from subrecords instead
of C<value()>.

=cut

sub get_string {
    my $self = shift;
    my @res = map( $_->as_string, $self->get_record_path(@_) );
    return ( $res[0] || '' );
}

=item C<get_strings()>

Like C<get_string()>, but returns multiple subrecords.

=cut

sub get_strings {
    my $self = shift;
    my @res = map( $_->as_string, $self->get_record_path(@_) );
    return wantarray ? @res : ( $res[0] || '' );
}

=back

=head2 Place Handling

=over 4

=item C<reset_places()>

Reset place memory (see C<GEDCOM::Record::Place>).

=cut

sub reset_places {
    my $self = shift;
    $self->{global}->{lastplace} = undef;
}

=back

=head2 Subrecords and Parent Records

=over 4

=item C<add_subrecord( $record )>

Add C<$record> as subrecord of this record.

=cut

sub add_subrecord {
    my ( $self, $subrecord ) = @_;

    # Add parent to subrecord
    $subrecord->{parent} = $self;

    # Add record to list of subrecords
    push @{ $self->{subrecords} }, $subrecord;

    # Add entry in index of subrecords
    push @{ $self->{index}->{ $subrecord->tag } }, $#{ $self->{subrecords} };

}

=item C<parent()>

Return parent record, that is, the record of which this record is a subrecord.

=cut

sub parent {
    my $self = shift;
    return $self->{parent};
}

# sub sort_subrecords {
#     my $self = shift;
#     @{$self->{subrecords}} = sort { $a->{tag} cmp $b->{tag} } @{$self->{subrecords}};
#     return 1;
# }

=back

=head2 Events, Attributes, Media, Sources

=over 4

=item C<collect_events( @events )>

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

=item C<collect_attributes( @attributes )>

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

=item C<listofevents()>

Return a numbered markdown list of events, sorted by date.

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

        my $notes = $event->notes;
        if ($notes) {
            $notes =~ s/^/    /mg;
            $t .= "\n" . $notes;
        }
    }
    $t .= "\n";
    return $t;
}

=item C<listofattributes()>

Return attributes as an unnumbered markdown list.

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

=item C<inline_images()>

Return markdown inline images (pandoc implicit figures) for all media
associated with this record.

=cut

sub inline_images {
    my $self = shift;
    my $t = "";

    # Find and dereference media objects (if any)
    my @media = map { $_->reference } $self->get_records( 'OBJE');

    # Add media objects as implicit figures (pandoc markdown only).
    foreach my $media (@media) {
        unless ($media->printed) {
            $t .= $media->inline_image . "\n\n";
        }
    }
    return $t;
}

=item C<sources()>

Return sources of this record, in markdown format. A typical source reference
might look like this:

    1 SOUR @XREF@
    2 PAGE <text>
    2 DATA
    3 TEXT <text>

For now, I'll only dereference the C<SOUR> pointer and deal with C<PAGE>.

=cut

sub sources {
    my $self = shift;

    my $t = "";

    my @sour = $self->get_records( 'SOUR' );

    foreach my $sour (@sour) {
        $t .= "; " if ($t);
        $t .= $sour->dereference->as_string;
        my $page = $sour->get_value( 'PAGE' );
        if ($page) {
            # reformat page references
            $page =~ s/Sida:/s./gi;
            $page =~ s/Vol(?:ym)?:/vol./gi;
            $page =~ s/(\w+):/lc $1/ge;
            $page =~ s/(?<=\d)-(?=\d)/--/g;
            $t .= ", ". $page;
        }
    }
    $t .= "." if ($t);
    return $t;
}

=item C<sources_footnote()>

Return source references as markdown footnote. Footnote texts are stored globally.

=cut

sub sources_footnote {
    my $self = shift;

    my $t = $self->sources;

    return $self->footnote( $t );
}

=item C<footnote( $text )>

Add a markdown footnote reference. The footnote text is stored internally in
C<$self->{global}->{footnotes}> and it is imperative that this is printed at
the end of any markdown document.

=cut

sub footnote {
    my ($self, $text) = @_;
    if ($text) {
        push @{$self->{global}->{footnotes}}, $text;
        return "[^" . $#{$self->{global}->{footnotes}} . "]";
    }
    return "";
}

=item C<footnotes()>

Return all footnotes.

=cut

sub footnotes {
    my $self = shift;

    my $t = "";
    for my $i (0..$#{$self->{global}->{footnotes}}) {
        $t .= "[^" . $i . "]: " . $self->{global}->{footnotes}->[$i] . "\n\n";
    }
    return $t;
}

=item notes()

Notes, as stored in NOTE records.

When thinking of it, I guess this method should go into GEDCOM::Records; there
are notes in other places as well.

=cut

sub notes {
    my $self  = shift;
    my %opt   = @_;
    my $t     = '';
    my @notes = $self->get_records("NOTE");
    if (@notes) {
        $t .= "$opt{heading}\n\n" if ( $opt{heading} );
        for my $i ( 0 .. $#notes ) {
            if ( $i > 0 ) {
                $t .= "\n\n";
            }
            $t .= $notes[$i]->value . "\n";
        }
    }
    $t .= "\n" if ($t);
    return $t;
}

=back

=head2 GEDCOM Source

=over 4

=item C<as_source()>

Return record as a valid GEDCOM source line. Recursive call to subrecords.

=cut

sub as_source {
    my $self = shift;
    my $t    = $self->sourceline;
    foreach my $subrecord ( @{ $self->{subrecords} } ) {
        $t .= $subrecord->as_source;
    }
    return $t;
}

=item C<sourceline()>

Called from C<as_source()>.

=cut

sub sourceline {
    my $self = shift;
    my $t    = "  " x $self->{level} . $self->{level};
    $t .= " " . $self->{id}    if ( $self->{id} );
    $t .= " " . $self->{tag};
    $t .= " " . $self->{value} if ( $self->{value} );
    $t .= "\n";
    return $t;
}

=back

=cut

1;
