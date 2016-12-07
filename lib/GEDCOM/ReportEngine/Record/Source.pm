package GEDCOM::ReportEngine::Record::Source;

=head1 GEDCOM::ReportEngine::Record::Source

=encoding utf8

This is a class for GEDCOM C<SOUR> records.

    0 @XREF@ SOUR
    1 TITL <title>
    1 ABBR <abbreviated title>
    1 AUTH <author>
    1 PUBL <publication information>

=cut

use base qw(GEDCOM::ReportEngine::Record);
use strict;
use warnings;
use utf8;

=head2 Methods

=over 4

=item C<fulltitle()>

Return full title (C<TITL>) of source reference.

=cut

sub fulltitle {
    my $self = shift;
    return $self->get_value('TITL');
}

=item C<shorttitle()>

Return abbreviated title (C<ABBR>) of source reference. Fallback to full title.

=cut

sub shorttitle {
    my $self  = shift;
    my $title = $self->get_value('ABBR');
    $title = $self->fulltitle unless ($title);
    return $title;
}

=item C<title()>

On first call, return full title. On subsequent calls, return abbreviated title (if it exists).

=cut

sub title {
    my $self = shift;
    if ( $self->{subsequent_title} ) {
        return $self->shorttitle;
    }
    $self->{subsequent_title} = 1;
    return $self->fulltitle;
}

=item C<as_string()>

Return source reference as markdown footnote. Footnote texts are stored globally.

=cut

sub as_string {
    my $self = shift;

    my $author      = $self->get_value("AUTH");
    my $publication = $self->get_value("PUBL");

    my $t = $author ? $author . ". " : "";

    if ( $self->{subsequent_string} ) {
        $t .= "*" . $self->shorttitle . "*";
    }
    else {
        $t .= "*" . $self->fulltitle . "*";
        $t .= ". " . $publication if ($publication);
        $self->{subsequent_string} = 1;
    }
    return $t;

}

=back

=cut

1;
