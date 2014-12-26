# -*- coding: utf-8 -*-
package Gedcom::Report::Locale;
use warnings;
use strict;
use utf8;
use locale;
use POSIX qw(locale_h);
use Data::Dumper;

my %Translation;
my $Locale = 'C';

BEGIN {
    use Exporter qw();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
    $VERSION = (split m/ /, q$Revision$)[1];
    @ISA = qw(Exporter);
    @EXPORT = qw(&T &Ts &decode_relation);
    %EXPORT_TAGS = ();
    @EXPORT_OK = qw();
}

BEGIN {
    # Get current locale for messages
    $Locale = setlocale( LC_MESSAGES );
    $Locale =~ s/\..*//;

    print "Setting locale $Locale\n";
    if (eval "require Gedcom::Report::Locale::$Locale") {
	eval "\%Translation = \%Gedcom::Report::Locale::${Locale}::T";
    }
    else {
	print STDERR "Translation for locale $Locale not available.\n";
    }
}

sub T {
    my $t = shift;
    return $Translation{$t} ? $Translation{$t} : $t;
}

sub Ts {
    my $pattern = T( shift );
    my %data = @_;
    foreach my $key (keys %data) {
	$pattern =~ s/%\($key\)/$data{$key}/g;
    }
    return $pattern;
}

sub decode_relation {
    my $relation = shift;
#    if ($Locale eq 'sv_SE') {
	$relation =~ s/FF(?=\w)/farfars /g;
	$relation =~ s/FM(?=\w)/farmors /g;
	$relation =~ s/MF(?=\w)/morfars /g;
	$relation =~ s/MM(?=\w)/mormors /g;
	$relation =~ s/FF/farfar/g;
	$relation =~ s/FM/farmor/g;
	$relation =~ s/MF/morfar/g;
	$relation =~ s/MM/mormor/g;
	$relation =~ s/F/far/g;
	$relation =~ s/M/mor/g;
#    }
    return $relation;
}

1;
