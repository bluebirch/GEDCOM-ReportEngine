package GEDCOM::Record::Place;

=head1 GEDCOM::Record::Place

This package is a subclass of GEDCOM::Record and includes special handling of
places and names of places.

=cut

use base qw(GEDCOM::Record);
use strict;
use warnings;
use utf8;
use GEDCOM::Locale;
use GEDCOM::LaTeX;

# sub parse {
#     my $self = shift;
#     $self->SUPER::parse;
# }

sub name {
    my $self = shift;
    return $self->value;
}

sub shortname {
    my $self        = shift;
    my $short_place = $self->name;
    if ( $self->{global}->{lastplace} ) {
        my @last = split m/\s*,\s*/, $self->{global}->{lastplace};
        my @cur  = split m/\s*,\s*/, $self->name;
        while ( $#cur >= 1 && $#last >= 1 && $last[$#last] eq $cur[$#cur] ) {
            pop @last;
            pop @cur;
        }
        $short_place = join( ", ", @cur );
    }
    $self->{global}->{lastplace} = $self->name;
    return $short_place;
}

1;
