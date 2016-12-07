package GEDCOM::ReportEngine::Record::Object;

=head1 GEDCOM::ReportEngine::Record::Object

=encoding utf8

This is a class for media objects, that is, GEDCOM C<OBJE> records. A typical
C<OBJE> records looks like the following:

    OBJE <@XREF@>
        FILE <filename>
            FORM <jpg|png|...>
            TITL <text>
        NOTE <text>

The only interesting things for our purposes is filename and title, that is
C<FILE> and C<FILE.TITL>. We specify those as methods below. Further, with
pandoc markdown, we can use inline images (and implicit figures, if put on a
single line), so we'll create a method for that as well.

=cut

use base qw(GEDCOM::ReportEngine::Record);
use strict;
use warnings;
use utf8;

=head2 Methods

=over 4

=item C<file()>

Returns file name, that is, the contents of the C<FILE> subrecord.

=cut

sub file {
    my $self = shift;
    return scalar $self->get_value('FILE');
}

=item C<title()>

Returns the title of the object, that is, the contents of the C<FILE.TITL>
subrecord path.

=cut

sub title {
    my $self = shift;
    return scalar $self->get_value_path('FILE.TITL');
}

=item C<inline_image()>

Return the media file as a pandoc markdown inline image. Do this once only;
subsequent calls to this method returns nothing. This avoids duplicate images
in reports.

=cut

sub inline_image {
    my $self = shift;
    my $t;
    if ( $self->{printed} ) {
        $t = "";
    }
    else {
        my $caption = $self->title;
        my $note = $self->notes;
        if ($note) {
            $caption =~ s/\.?$/./; # Title should end with full stop.
            $note =~ s/\n+/ /g; # Remove linebreaks
            $caption .= " " . $note;
        }
        $t = "![" . $caption . " -- \\[" . $self->id . "\\]](" . $self->file . "){ width=80% }";
        $self->flag; # flag this object
    }
    return $t;
}

=item C<printed()>

This is a simple call to check if the media file has already been returned as
an inline image (see above).

=cut

sub printed {
    my $self = shift;
    return $self->flagged;
}

=back

=cut

1;
