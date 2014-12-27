=pod

=head The GEDCOM::Record::Root package

Honestly, I don't know what or why.

=cut

package GEDCOM::Record::Root;
use base qw(GEDCOM::Record);
use strict;
use warnings;
use utf8;

sub single_source {
    return '';
}

1;
