package GEDCOM::Record::Object;

=head1 GEDCOM::Record::Object

=encoding utf8

Det här är en klass för medieobjekt, dvs. GEDCOM OBJE-poster. En typisk 
OBJE-post ser ut som följer:

    OBJE <id>
        FILE <filnamn>
            FORM <jpg|png|...>
            TITL <text>

Det enda av intresse är filnamn och titel, alltså FILE och FILE.TITL. Dessa
kan vi således ange som metoder till klassen GEDCOM::Record::Object.

=cut

use base qw(GEDCOM::Record);
use strict;
use warnings;
use utf8;

=head2 Metoder

=over 4

=item file()

Returnerar filen som objektet pekar på.

=cut

sub file {
    my $self = shift;
    return scalar $self->get_value( 'FILE' );
}

=item title()

Returns the title of the object.

=cut

sub title {
    my $self = shift;
    return scalar $self->get_value_path( 'FILE.TITL' );
}

=back

Slut.

=cut

1;
