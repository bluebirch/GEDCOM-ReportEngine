perlfiles = $(wildcard *.pm) $(wildcard GEDCOM/*.pm) $(wildcard GEDCOM/Record/*.pm) $(wildcard GEDCOM/Record/Date/*.pm)

test:
	perl -I lib bin/gedcom-report --file=t/files/allged.ged

GEDCOM.pdf: GEDCOM.md
	pandoc --latex-engine=xelatex --number-sections --table-of-contents -V fontsize=12pt -V lang=english -o $@ $<

GEDCOM.md: $(perlfiles)
	echo "% The Perl GEDCOM Report System" > $@
	echo "% Stefan Björk" >> $@
	echo "% `date -R`" >> $@
	echo >> $@
	for f in $^ ; do\
		pod2markdown $$f >> $@ ;\
		echo >> $@ ;\
	done
