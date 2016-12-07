package GEDCOM::ReportEngine::Record::Family;

=head1 GEDCOM::ReportEngine::Record::Family

Family records.

=cut

use base qw(GEDCOM::ReportEngine::Record);
use strict;
use warnings;
use utf8;

sub parse {
    my $self = shift;
    $self->SUPER::parse;
}

sub husband {
    my $self = shift;
    my $husb = $self->get_record("HUSB");
    return $husb ? $husb->reference : undef;
}

sub wife {
    my $self = shift;
    my $wife = $self->get_record("WIFE");
    return $wife ? $wife->reference : undef;
}

sub children {
    my $self = shift;
    my @children = map { $_->reference } $self->get_records("CHIL");
    return @children;
}

1;
