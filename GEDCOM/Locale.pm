# -*- coding: utf-8 -*-
package GEDCOM::Locale;
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
    our ( $VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS );
    $VERSION     = ( split m/ /, q$Revision$ )[1];
    @ISA         = qw(Exporter);
    @EXPORT      = qw(&T &Ts &decode_relation &ordinal);
    %EXPORT_TAGS = ();
    @EXPORT_OK   = qw();
}

BEGIN {
    # Get current locale for messages
    $Locale = setlocale(LC_MESSAGES);
    $Locale =~ s/\..*//;

    print "Setting locale $Locale\n";
    if ( eval "require GEDCOM::Locale::$Locale" ) {
        eval "\%Translation = \%GEDCOM::Locale::${Locale}::T";
    }
    else {
        print STDERR "Translation for locale $Locale not available.\n";
    }
}

sub T {
    my $t = shift;
    print STDERR "call to T( \"$t\" ) is obsolete\n";
    return $Translation{$t} ? $Translation{$t} : $t;
}

sub Ts {
    my $pattern = T(shift);
    my %data    = @_;

    #    print STDERR "call to Ts( \"") is obsolete\n";
    foreach my $key ( keys %data ) {
        $pattern =~ s/%\($key\)/$data{$key}/g;
    }
    return $pattern;
}

sub decode_relation {
    my $relation = shift;

    my $t = '';

    while (length($relation) > 2) {
        my $pair = substr $relation, 0, 2, '';
        if ($pair eq 'FF') {
            $t .= "farfars ";
        }
        elsif ($pair eq 'FM') {
            $t .= "farmors ";
        }
        elsif ($pair eq 'MM') {
            $t .= "mormors ";
        }
        elsif ($pair eq 'MF') {
            $t .= "morfars ";
        }
        else {
            die "lack of logic"
        }
    }

    if ($relation eq 'FF') {
        $t .= "farfar";
    }
    elsif ($relation eq 'FM') {
        $t .= "farmor";
    }
    elsif ($relation eq 'MM') {
        $t .= "mormor";
    }
    elsif ($relation eq 'MF') {
        $t .= "morfar";
    }
    elsif ($relation eq 'F') {
        $t .= "far";
    }
    elsif ($relation eq 'M') {
        $t .= "mor";
    }
    else {
        die "logic failure";
    }

    return $t;
}

=item ordinal( $n )

Returnera ett ordinaltal för angivet tal $n. Detta används bland annat i
rubriker av typen "första generationen", "andra generationen", och så vidare.
För tillfället är den extremt enkel och knappt funktionell, men fungerar för
ordningstal mellan 1 och 10. :-)

=cut

my %ORDINAL = (
    1  => "första",
    2  => "andra",
    3  => "tredje",
    4  => "fjärde",
    5  => "femte",
    6  => "sjätte",
    7  => "sjunde",
    8  => "åttonde",
    9  => "nionde",
    10 => "tionde",
    11 => "elfte",
    12 => "tolfte",
    13 => "trettonde",
    14 => "fjortonde",
    15 => "femtonde",
);

sub ordinal {
    my $n = shift;
    return $ORDINAL{$n} ? $ORDINAL{$n} : $n;
}

1;
