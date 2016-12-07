# GEDCOM::ReportEngine

This is GEDCOM::ReportEngine, a Perl class to create markdown reports from GEDCOM data.

A long time ago, I was dissatisfied with the reporting possibilities in all existing geneaology software. I ended up implementing my own reporting engine in Perl. At the time, I wasn't aware of Paul Johnson's [Gedcom](https://metacpan.org/pod/Gedcom) package or didn't find it a viable alternative (I can't remember) so I implemented my own GEDCOM parser as well. The reporting engine is closely tied to the parser: the GEDCOM data structure is converted to record objects in an hierarchic structure of arrays, and the reporting functions is implemented as methods of those objects. For example, a `GEDCOM::ReportEngine::Record::Individual` object has different methods for different ways of representing indvididuals in a report.

I originally designed the module to output plain text or LaTeX, but with the discovery of [Pandoc](https://pandoc.org) I have redesigned it to only output Markdown text. The markdown report can then be converted into the desired format (PDF, Word, OpenDocument Text, ePUB, etc) with Pandoc.

My goal is to finish this module and publish it on CPAN. Some more work is needed before that can be done, namely (1) code cleanup, (2) documentation, and (3) localization.

