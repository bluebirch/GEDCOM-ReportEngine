#!/usr/bin/perl -w

# Test GEDCOM parsing.

use Test::More tests => 1;

use GEDCOM::ReportEngine;

my $ged = GEDCOM::ReportEngine->new( 't/files/genealogi.ged' );

isa_ok( $ged, "GEDCOM::ReportEngine" );
