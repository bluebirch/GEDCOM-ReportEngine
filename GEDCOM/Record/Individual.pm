package GEDCOM::Record::Individual;

=head1 GEDCOM::Record::Individual

=over 8

=cut

use base qw(GEDCOM::Record);
use strict;
use warnings;
use utf8;
use GEDCOM::Locale;
use GEDCOM::LaTeX;
use Data::Dumper;

sub parse {
    my $self = shift;

    # Add individual to name index
    if ( $self->{global} ) {
        $self->{global}->{nameindex}->{ $self->plainname } = $self;
    }

    $self->SUPER::parse;
}

### NAME
sub name {
    my $self = shift;
    return $self->get_value("NAME");
}

=item fullname()

Return full name in markdown format, family name bold and call name italic.

=cut

sub fullname {
    my $self = shift;
    my $name = $self->name;
    $name =~ s:(\w+?)\*:*$1*:g;
    $name =~ s:/(.*?)/:uc $1:eg;
    return $name;
}

=item plainname()

Namn, rensat från all formattering.

=cut

sub plainname {
    my $self = shift;
    my $name = $self->name;
    $name =~ s:[/"*]::g;
    return $name;
}

sub plainname_refn {
    my $self = shift;
    my $refn = $self->refnp;
    if ($refn) {
        return "[" . $self->plainname . $refn . "](#" . $self->xref . ")";
    }
    else {
        return $self->plainname;
    }
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
    my $self  = shift;
    my $birth = $self->get_record("BIRT");
    my $death = $self->get_record("DEAT");
    if ( $birth && $death ) {
        return $birth->year . '--' . $death->year;
    }
    elsif ($birth) {
        return Ts( "⁎~%(year)", year => $birth->year );
    }
    elsif ($death) {
        return Ts( "†~%(year)", year => $death->year );
    }
    return "";
}

### ATTRIBUTES

sub sex {
    my $self = shift;
    return $self->get_value('SEX');
}

### EVENTS

=item event( $tag )

Returnera händelser för $tag som textsträng.

=cut

sub event {
    my $self = shift;
    my $tag = shift;
    my $t = join( '', map { $_->as_sentence( @_ ) } $self->get_records($tag) );
    return $t;
}

sub birth {
    my $self = shift;
    return $self->event('BIRT', @_ );
}

sub baptism {
    my $self = shift;
    return $self->event('BAPM', @_ );
}

sub death {
    my $self = shift;
    return $self->event('DEAT', @_ );
}

sub burial {
    my $self = shift;
    return $self->event('BURI', @_ );
}

=back

=head2 Families

=over 4

=item fams()

Families that this individual is a spouse in. The records are automatically
dereferenced.

=cut

sub fams {
    my $self = shift;
    my @fams = map { $_->reference } $self->get_records("FAMS");
    return @fams;
}

=item famc()

Families this individual is a child of. This should usually only be one, but I
guess there can be cases of adoptive children and so on; I currently only
return ONE record, which might be a problem in the future. I<This is a
potential bug!>

=cut

sub famc {
    my $self = shift;
    my $famc = $self->get_record("FAMC");
    return $famc ? $famc->reference : undef;
}

=item father()
=item mother()
=item children()

Fairly straightforward what they do, I guess.

=cut

sub father {
    my $self = shift;
    my $famc = $self->famc;
    return $famc ? $famc->husband : undef;
}

sub mother {
    my $self = shift;
    my $famc = $self->famc;
    return $famc ? $famc->wife : undef;
}

sub children {
    my $self = shift;
    return map { $_->children } $self->fams;
}

=back
=head2 Strings
=over 4

=item nameheading()

Write the name as a level 3 markdown heading.

=cut

sub nameheading {
    my $self = shift;
    my $h = $self->refn ? "[" . $self->refn . "] " . $self->fullname : $self->fullname;
    $h .= " {#" . $self->xref . "}";
    #$t .= $self->addnametoindex . label( $self->id );
    return $h . "\n" . "-" x length( $h ) . "\n\n";
}

### REPORTS

=pod

=item oneliner()

Returns the full name, reference number (if any), birth date and death
date.

=cut

sub oneliner {
    my $self = shift;

    my $name  = $self->plainname_refn;
    my $birth = $self->get_record_path("BIRT.DATE");
    my $death = $self->get_record_path("DEAT.DATE");
    my $t     = '';
    if ( $birth && $death ) {
        $t = sprintf( "%s, ✴ %s, † %s.", $name, $birth->as_string, $death->as_string );
    }
    elsif ($birth) {
        $t = sprintf( "%s, ✴ %s.", $name, $birth->as_string );
    }
    elsif ($death) {
        $t = sprintf( "%s, † %s.", $name, $death->as_string );
    }
    else {
        $t = sprintf( "%s.", $name );
    }
    #$t .= $self->addnametoindex;
    return $t;
}

=pod

=item summary()

Returns a summary of the individual, including parents, relations,
children and an eventes table.

=cut

sub summary {
    my $self = shift;
    my %opt  = @_;

    # Vi håller lite koll på vad vi anger för platser. Vi vill nämligen inte
    # upprepa oss alltför mycket, så senare delen av platsnamnet visas inte om
    # det upprepas. Den här funktionen nollställer denna "minnesfunktion"
    # eller vad man skall kalla det.
    $self->reset_places();

    # Börja med att ange namnet som rubrik.
    my $t = $self->nameheading();

    # Ange först relationen till huvudpersonen, så att säga.
    $t .= ucfirst( decode_relation( $opt{relation} ) ) . '. '
        if ( $opt{relation} );

    # Just reference if person has already been printed. (Jag vet inte riktigt
    # hur jag skall göra detta i markdown, men det får bli ett senare
    # problem.)
    if ( $self->{global}->{printed}->{ $self->id } ) {
        $t .= T("See") . " [" . $self->id . "]\n\n";
        return $t;
    }

    # Födelse
    $t .= $self->birth( nosource => 1 );

    # Föräldrar
    $t .= $self->childof();

    # Familjehändelser
    foreach my $event ( @{ $self->collect_events( "MARR", "DIV" ) } ) {
        $t .= $event->as_sentence( indi => $self->id, nosource => 1 );
    }

    # Död
    $t .= $self->death( nosource => 1);

    # Remove trailing spaces
    $t =~ s/\s+$//s;

    # Sources
    $t .= $self->sources_footnote;

    # Nytt stycke
    $t .= "\n\n";

    # Images
    $t .= $self->inline_images;

    # Barn
    $t .= $self->listofchildren( spouseinfo => $opt{spouseinfo}, images => 1 );

    # Anteckningar
    $t .= $self->notes( heading => "### Anteckningar" );
#        if ( $opt{notes} );

    # Egenskaper
    $t .= $self->listofattributes( heading => "### Fakta" );

    # Händelser
    $t .= $self->listofevents( heading => "### Kronologi" );

    # Remember this individual
    $self->{global}->{printed}->{ $self->id } = 1;

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
    if ( $self->sex eq 'M' ) {
        $child = "Son";
    }
    elsif ( $self->sex eq 'F' ) {
        $child = "Dotter";
    }
    else {
        $child = "Barn";
    }

    my $t = "";
    if ( $father && $mother ) {
        $t = sprintf( "%s till %s och %s.", $child, $father->plainname_refn, $mother->plainname_refn );
    }
    elsif ($father) {
        $t = sprintf( "%s till %s.", $child, $father->plainname_refn );
    }
    elsif ($mother) {
        $t = sprintf( "%s till %s.", $child, $mother->plainname_refn );
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
    my %opt  = @_;

    my $t = '';

    # Barn
    my $nchi = 0;    # Children counter.
    foreach my $fam ( map { $_->reference } $self->get_records("FAMS") ) {
        my @children = $fam->children;
        if (@children) {

            # Get spouse
            my ($spouse) = grep { $_->id ne $self->id }
                grep {$_} ( $fam->husband, $fam->wife );

            # Display spouse info
            if ($spouse) {
                if ( $opt{spouseinfo} ) {
                    # Rubrik i form av make/makas namn
                    $t .= "### " . $spouse->fullname . "\n\n";
                    $t .= $spouse->birth . $spouse->childof . $spouse->death;
                    $t .= "\n\n";
                    $t .= sprintf( "Barn till %s och %s:\n\n", $self->plainname, $spouse->plainname );
                }
                else {
                    $t .= sprintf( "### Barn med %s\n\n", $spouse->plainname );
                }
            }
            else {
                $t .= "### Barn\n\n";
            }

            # Print list of children
            #$t .= begin_numlist;
            #$t .= "\\setcounter{enumi}{$nchi}\n";
            #$t .= "\n\n";
            foreach my $child (@children) {
                $t .= sprintf( "%2d. ", ++$nchi ) . $child->oneliner . "\n";
            }
            $t .= "\n";

            # Print media (if exists)
            $t .= $fam->inline_images if ($opt{images});
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

Return a report containing ancestors or descendants.

=cut

sub _report {
    my $self = shift;
    my $type = shift;
    my %opt  = @_;

    # Här kommer några variabler som jag knappt vet vad de gör. Den första
    # tror jag har att göra med vilken typ av träd som skall byggas; ett anrop
    # till aktuell sub kommer nog senare. Den andra har något med numreringen
    # av personer i trädet att göra. Den tredje anger det maximala antalet
    # generationer i trädet.
    my $sub         = 'make_' . $type . '_tree';
    my $type_refn   = $type . '_refn';
    my $generations = $opt{generations} ? $opt{generations} : 20;

    # Detta är en flagga som anger huruvida vi skall skriva ut information om
    # make/maka i trädet. Det gör vi i stamtavlor, men inte i antavlor.
    my $spouseinfo = 0;

    # Ja, men titta, här är ju anropet till trädkonstruktionssubrutinen i
    # fråga. Här bygger vi alltså upp det träd som sedemera skall rapporteras,
    # generation för generation.
    $self->$sub( generations => $generations )
        unless ( $self->{$type} );

    # "Connect global reference number table with this tree." -- Det här vet
    # jag faktiskt inte vad det betyder. Det var länge sedan jag skrev den här
    # koden.
    $self->{global}->{refn} = $self->{$type_refn};

    # I variabeln $t lagras hela den textsträng som skall bli ett markdown-
    # dokument. Vi börjar med att ange dokumentets titel. Det gör vi i ett
    # YAML-block i början av dokumentet.
    my $t = "---\ntitle: ";

    # Titeln blir lite olika beroende på vad det är för typ av rapport som skapas.
    if ( $type eq 'ancestors' ) {
        $t .= "Antavla för " . $self->plainname;
    }
    elsif ( $type eq 'descendants' ) {
        $t .= "Stamtavla för " . $self->plainname;
        $spouseinfo = 1;
    }
    else {
        $t .= "Rapport för " . $self->plainname;
    }

    # Avsluta YAML-blocket (egentligen skall det väl in datum och grejor här).
    $t .= "\n...\n\n";

    # Stega igenom rapporten, generation för generation.
    for my $generation ( 0 .. $#{ $self->{$type} } ) {

        # Sätt en rubrik. Vi gör en läsvänlig markdown-rubrik.
        my $heading = ucfirst( sprintf( "%s generationen", ordinal( $generation + 1 ) ) );
        $t .= $heading . "\n";
        $t .= "=" x length( $heading ) . "\n\n";

        # Och så rapporterar vi varje individ. Det gör vi i funktionen
        # 'summary', som uppenbarligen anropas härifrån.
        foreach my $i ( @{ $self->{$type}->[$generation] } ) {
            $t .= $i->summary(
                spouseinfo => $spouseinfo,
                notes      => $opt{notes},
                relation   => $self->{relation}->{ $i->xref }
            );
        }
    }

    # Last, but not least, print all footnotes
    $t .= $self->footnotes;

    return $t;
}

=pod

=item make_ancestors_tree( $max_generations )

Build an internal structure of ancestors for each generation.

=cut

sub make_ancestors_tree {
    my $self = shift;
    my %opt  = @_;

    # Maximum generations defaults to 10.
    my $max_generations = $opt{generations} ? $opt{generations} : 10;

    # Array-of-Array with generations and individuals. Every
    # generation holds the parents of previous generation.
    @{ $self->{ancestors} } = ( [$self] );

    # The beginning person gets reference number 1.
    $self->{ancestors_refn}->{ $self->id } = 1;

    # Step through all individuals in generation $generation and add
    # their parents to $generation+1.
    my $generation = 0;
    my $refn       = 2;
    my $parents;    # Holds list of parents.
    do {
        $parents = [];
        foreach my $indi ( @{ $self->{ancestors}->[$generation] } ) {
            if ( $indi->father ) {
                push @$parents, $indi->father;

                # Father gets number 2n
                $self->{ancestors_refn}->{ $indi->father->id }
                    = $self->{ancestors_refn}->{ $indi->id } * 2;

                # Store relation
                $self->set_parental_relation( $indi, $indi->father );
            }
            if ( $indi->mother ) {
                push @$parents, $indi->mother;

                # Mother gets number 2n+1
                $self->{ancestors_refn}->{ $indi->mother->id }
                    = $self->{ancestors_refn}->{ $indi->id } * 2 + 1;

                # Store relation
                $self->set_parental_relation( $indi, $indi->mother );
            }
        }

        # Add list of parents to the list of ancestors.
        $generation++;
        $self->{ancestors}->[$generation] = $parents if (@$parents);
    } while ( @$parents && $generation < $max_generations - 1 );
}

sub set_parental_relation {
    my ( $self, $person, $parent ) = @_;
    my $relation = $self->{relation}->{ $person->xref };
    $relation = "" unless ($relation);
    if ( $parent->sex eq 'M' ) {
        $relation .= 'F';
    }
    elsif ( $parent->sex eq 'F' ) {
        $relation .= 'M';
    }
    $self->{relation}->{ $parent->xref } = $relation;
}

=pod

=item make_descendants_tree( $max_generations )

Build an internal structure of descendants for each generation.

=cut

sub make_descendants_tree {
    my $self = shift;
    my %opt  = @_;

    # Maximum generations defaults to 10
    my $max_generations = $opt{generations} ? $opt{generations} : 10;

    # Array-of-Array with generations and individuals. Each individual
    # holds the children to the individuals in previous generation.
    @{ $self->{descendants} } = ( [$self] );

    # The beginning person gets reference number 1.
    $self->{descendants_refn}->{ $self->id } = 1;

    # Step through all individuals in generation $generation and add
    # their children to $generation+1.
    my $generation = 0;
    my $refn       = 2;
    my $children;    # Hold list of children
    do {
        $children = [];
        foreach my $indi ( @{ $self->{descendants}->[$generation] } ) {
            my @children = $indi->children;
            if (@children) {

                # Lägg barnen till aktuell lista för generation x. Ta
                # bara med de barn som själva har barn.
                #       push @$chil, grep { $_->children } @children;
                push @$children, @children;
            }
        }

        # Add numbers
        if (@$children) {
            foreach my $indi (@$children) {
                $self->{descendants_refn}->{ $indi->id } = $refn++;
            }
            $self->{descendants}->[ ++$generation ] = $children;
        }
    } while ( @$children && $generation < $max_generations );
}

1;
