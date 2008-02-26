doxygen_configfile = Doxyfile
doxygen_configfile_source = $(srcdir)/Doxyfile.in
beautify_docs_source = $(srcdir)/beautify_docs.pl.in
beautify_docs = $(srcdir)/beautify_docs.pl

devhelp_file = glibmm-2.4.devhelp
devhelp_stylesheet = doxygen_to_devhelp.xsl

referencedir = $(gtkmm_docdir)/reference/html
devhelpdir = $(datadir)/devhelp/books/glibmm-2.4

#install the devhelp stylesheet to be used by other libraries as well
stylesheetdir = $(GMMPROC_DIR)
stylesheet_DATA = $(devhelp_stylesheet)

include $(top_srcdir)/docs/Makefile_web.am_fragment
web_path_reference = $(web_path_docs)reference

EXTRA_DIST = README Doxyfile.in \
             glibmm_header.html_fragment glibmm_footer.html_fragment beautify_docs.pl \
             html glibmm_doxygen_tags libstdc++.tag.xml $(devhelp_stylesheet) $(devhelp_file) \
             xml/index.xml #Just to satisfy the dependency when building from the tarball.
#Ideally, libstdc++.tag.xml would be installed by gcc, instead of being copied into every project.


HTML_INDEX=html/index.html
XML_INDEX=xml/index.xml

# Build a DevHelp reference from the doxygen xml
$(devhelp_file): $(XML_INDEX) $(devhelp_stylesheet)
	xsltproc --stringparam book_title "glibmm 2.4 Reference Manual" \
		--stringparam book_name "glibmm 2.4" \
		--stringparam reference_prefix "../../../doc/glibmm-2.4/docs/reference/html" \
		-o $@ $(devhelp_stylesheet) $(XML_INDEX)

$(HTML_INDEX) $(XML_INDEX): $(doxygen_configfile_source) $(beautify_docs_source) $(top_srcdir)/glib/glibmm/*.h
	-rm -rf html
	-rm -rf xml
	doxygen $(doxygen_configfile)
	$(PERL_PATH) $(beautify_docs) html && touch $@


glibmm-reference-html.tar.gz: $(HTML_INDEX)
	tar cf - html | gzip -c --best >$@

glibmm-reference-html.tar.bz2: $(HTML_INDEX)
	tar cf - html | bzip2 -c >$@

post-html: $(HTML_INDEX)
	rsync $(rsync_args) -r html/ $$USER@$(web_host):$(web_path_reference)/html/

doc-clean:
	-rm -rf html
	-rm -rf xml
	-rm -f $(devhelp_file)  
	-rm -f glibmm_doxygen_tags
	-rm -f glibmm-reference-html.tar.gz glibmm-reference-html.tar.bz2

install-reference: $(HTML_INDEX) $(devhelp_file)
	@$(NORMAL_INSTALL)
	$(mkinstalldirs) $(DESTDIR)$(referencedir)
	@dir='$(<D)'; for p in $$dir/*.html $$dir/*.css $$dir/*.png $$dir/*.dot ; do \
	  f="`echo $$p | sed -e 's|^.*/||'`"; \
	  echo " $(INSTALL_DATA) $$p $(DESTDIR)$(referencedir)/$$f"; \
	  $(INSTALL_DATA) $$p $(DESTDIR)$(referencedir)/$$f; \
	done
	$(mkinstalldirs) $(DESTDIR)$(devhelpdir)
	$(INSTALL_DATA) $(srcdir)/$(devhelp_file) $(DESTDIR)$(devhelpdir)/$$f;

uninstall-reference: $(HTML_INDEX)
	@$(NORMAL_UNINSTALL)
	@dir='$(<D)'; for p in $$dir/*.html $$dir/*.css $$dir/*.png $$dir/*.dot ; do \
	  f="`echo $$p | sed -e 's|^.*/||'`"; \
	  echo " rm -f $(DESTDIR)$(referencedir)/$$f"; \
	  rm -f $(DESTDIR)$(referencedir)/$$f; \
	done
	rm -f $(DESTDIR)$(devhelpdir)/$(devhelp_file)

# Install beautify_docs.pl, next to gmmproc.
gmmproc_bin_SCRIPTS = $(beautify_docs)
gmmproc_bindir = $(GMMPROC_DIR)

all-local: $(HTML_INDEX) $(devhelp_file)

install-data-local: install-reference

uninstall-local: uninstall-reference

maintainer-clean-local: doc-clean

.PHONY: post-html doc-clean install-reference uninstall-reference

