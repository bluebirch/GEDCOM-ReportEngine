# -*- coding: utf-8 -*-
package GEDCOM::LaTeX;
use warnings;
use strict;
use utf8;
use locale;
use POSIX qw(locale_h);

# All LaTeX stuff is moved to a non-OO module. Seems like a good idea.

BEGIN {
    use Exporter qw();
    our ( $VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS );
    $VERSION = ( split m/ /, q$Revision$ )[1];
    @ISA     = qw(Exporter);
    @EXPORT  = qw(&begin_document &end_document &maketitle &tableofcontents
        &smallcaps &italic &bold
        &cdots &ldots
        &chapter &section &subsection &subsubsection &paragraph &subparagraph
        &p
        &begin_table &end_table &tablerow &hline
        &begin_numlist &end_numlist &begin_itemlist &end_itemlist
        &item
        &normal &small &smaller &smallest
        &textbreak
        &addtoindex &label
        &shortplace &reset_shortplace);
    %EXPORT_TAGS = ();
    @EXPORT_OK   = qw();
}

### Well, this actually has nothing to do in this module, but I really
### don't have the will to create another module. Place handling. Sort
### of. You know.
###
### When printing places, hide parts of the names that has recently
### been used.
###
my $LASTPLACE;

# sub shortplace {
#     my $place = shift;
#     return '' unless ($place);
#     my $short_place = $place;
#     if ($LASTPLACE) {
#   my @last = split m/\s*,\s*/, $LASTPLACE;
#   my @cur = split m/\s*,\s*/, $place;
#   while ($#cur >= 1 && $#last >= 1 && $last[$#last] eq $cur[$#cur]) {
#       pop @last;
#       pop @cur;
#   }
#   $short_place = join( ", ", @cur );
#     }
#     $LASTPLACE = $place;
#     return $short_place;
# }

# sub reset_shortplace {
#     $LASTPLACE = undef;
# }

### BEgin and end document

sub begin_document {    # FIXME: Language should be chosen from
                        # Locale.pm, not hard-coded here.
    return <<END;
% -*- coding: utf-8 -*-
\\documentclass[a4paper,12pt,swedish]{report}
\\usepackage[utf8]{inputenc}
\\usepackage[T1]{fontenc}
\\usepackage{textcomp}
%\\usepackage[osf,scaled]{xagaramon}
\\usepackage{mathpazo}
\\usepackage{babel}
\\usepackage{filecontents}
\\usepackage{ltxtable}
\\usepackage{booktabs}
\\usepackage[flushleft,alwaysadjust]{paralist}
\\usepackage{parskip}
\\usepackage{index}
\\usepackage{a4wide}
\\setcounter{secnumdepth}{-1}
\\makeatletter
\\newcommand{\\textbreak}{\\par
  \\penalty -100
  \\noindent\\parbox{\\linewidth}{\\centering * * *}\\null
  \\penalty -20
  \\\@afterindentfalse
  \\\@afterheading}
\\makeatother
\\makeindex
\\begin{document}
END
}

sub end_document {
    return <<END;
\\printindex
\\end{document}
END
}

# Title

sub maketitle {
    my ( $title, $author, $date ) = @_;
    return '' unless ($title);
    my $t = "\\title{$title}\n";
    $t .= "\\author{$author}\n" if ($author);
    $t .= "\\date{$date}\n"     if ($date);
    $t .= "\\maketitle\n\n";
    return $t;
}

sub tableofcontents { return "\\tableofcontents\n"; }

# Special characters

sub cdots { return '$\cdots$' }
sub ldots { return '\ldots{}' }

# Font stuff

sub smallcaps {
    return "\\textsc{" . join( '', @_ ) . "}";
}

sub italic {
    return "\\emph{" . join( '', @_ ) . "}";
}

sub bold {
    return "\\textbf{" . join( '', @_ ) . "}";
}
sub normal   { return "\\normalsize{}" }
sub small    { return "\\small{}" }
sub smaller  { return "\\footnotesize{}" }
sub smallest { return "\\tiny{}" }

# Sectioning

sub _section {
    my ( $type, $text, $optional_text ) = @_;
    return $optional_text
        ? "\n\\${type}[$optional_text]{$text}\n\n"
        : "\n\\${type}{$text}\n\n";
}

sub chapter       { return _section( "chapter",       @_ ); }
sub section       { return _section( "section",       @_ ); }
sub subsection    { return _section( "subsection",    @_ ); }
sub subsubsection { return _section( "subsubsection", @_ ); }
sub paragraph     { return _section( "paragraph",     @_ ); }
sub subparagraph  { return _section( "subparagraph",  @_ ); }

# Paragraphing

sub p {
    return "\n\n";
}

# Tables

sub begin_table {
    my $format = shift;
    $format = 'lX' unless ($format);
    return <<END;
\\begin{filecontents}{tmp.tex}
\\begin{longtable}{$format}
END
}

sub end_table {
    return <<END;
\\end{longtable}
\\end{filecontents}
\\LTXtable{\\columnwidth}{tmp.tex}
END
}

sub tablerow {
    return join( ' & ', @_ ) . "\\\\\n";
}

sub hline {
    return "\\hline\n";
}

### Lists

sub item           { return "\\item @_\n"; }
sub begin_itemlist { return "\n\\begin{itemize}\n"; }
sub end_itemlist   { return "\\end{itemize}\n"; }
sub begin_numlist  { return "\n\\begin{enumerate}\n"; }
sub end_numlist    { return "\\end{enumerate}\n"; }

### Labels and index

sub addtoindex { return "\\index{@_}"; }
sub label      { return "\\label{@_}"; }

### Text break stuff

sub textbreak { return "\\textbreak\n\n"; }

1;
