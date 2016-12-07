# ABSTRACT: A GEDCOM Report Engine written in Perl
package GEDCOM::ReportEngine;
=head1 GEDCOM.pm

To be documented.

=cut

use strict;
use warnings;
use locale;
use utf8;

use IO::File;
#use GEDCOM::ReportEngine::Locale;
use GEDCOM::ReportEngine::Record;
use Data::Dumper;

BEGIN {
    our ($VERSION);
    $VERSION = "0.0.1";
}

=head2 Methods

=over 4

=item C<new( $filename )>

Create a new GEDCOM file object. Expects a file name as argument.

=cut

sub new {
    my $this  = shift;
    my $class = ref($this) || $this;
    my $self  = {
        root   => GEDCOM::ReportEngine::Record->new( -1, '_ROOT' ),
        global => {}
    };
    $self->{filename} = shift;
    bless $self, $class;
    $self->parse();
    return $self;
}

=item C<parse()>

Parse a GEDCOM file.

=cut

sub parse {
    my $self = shift;
    my $fh   = new IO::File $self->{filename};
    if ($fh) {
        my $current_level = -1;
        my $last_record   = $self->{root};
        my @stack;
        while ( my $line = <$fh> ) {

            # Strip lf or crlf
            $line =~ s/\r?\n$//;

            if ( $line
                =~ m/^\s*(\d+)\s+(?:(@[A-Z0-9]+@)\s+)?([A-Z_]{3,})(?:\s+(.*))?$/
                )
            {
                my ( $level, $id, $tag, $data ) = ( $1, $2, $3, $4 );

                #           print STDERR "lvl $level tag $tag";
                #           print STDERR " id $id" if ($id);
                #           print STDERR " data $data" if ($data);
                #           print STDERR "\n";

                # Check for special tags
                if ( $tag eq 'CHAR' ) {
                    print STDERR "Character set: $data\n";
                    if ( $data eq 'UTF-8' ) {
                        binmode( $fh, ':utf8' ) || die "binmode failed";
                    }
                }

                # Create a GEDCOM record object.
                my $record
                    = GEDCOM::ReportEngine::Record->new( $level, $tag, $id, $data,
                    $self->{global} );

                # If level is same as last level, add to subrecord on
                # stack.
                if ( $level == $current_level ) {
                    $stack[$#stack]->add_subrecord($record);
                }

                # If level is increased by one, push last record on
                # stack and add current record to it.
                elsif ( $level - $current_level == 1 ) {
                    $last_record->add_subrecord($record);
                    push @stack, $last_record;
                }

                # If level is decreased by one, pop record from stack
                # and add to the last record on stack.
                elsif ( $level < $current_level ) {
                    my $diff = $current_level - $level;
                    for ( my $i = 1; $i <= $diff; $i++ ) {
                        pop @stack;
                    }
                    $stack[$#stack]->add_subrecord($record);
                }

                # Otherwise, there must be something wrong.
                else {
                    die
                        "Something went wrong (level $level, current $current_level) $line";
                }

                $current_level = $level;
                $last_record   = $record;

            }
            else {
                die "Can't parse line \"$line\"";
            }
        }
    }
    else {
        die "No GEDCOM file found";
    }

    # Recursive parse of all records
    $self->{root}->parse();

    return $self->{root};
}

=item C<as_source()>

Return entire GEDCOM file as source. This should be identical to original
file.

=cut

sub as_source {
    my $self = shift;
    return $self->{root}->as_source();
}

=item C<get_individual( $pattern )>

Find an individual in the GEDCOM database based on the supplied regexp
pattern. Returns the first match only.

=cut

sub get_individual {
    my ( $self, $pattern ) = @_;
    my $firstmatch
        = ( grep m/$pattern/, keys %{ $self->{global}->{nameindex} } )[0];
    return $firstmatch ? $self->{global}->{nameindex}->{$firstmatch} : undef;
}

=item C<get_xref( $xref )>

Find an object based on its C<@XREF@>.

=cut

sub get_xref {
    my ($self, $xref) = @_;
    return $self->{global}->{xref}->{$xref};
}

=back

=cut

1;

