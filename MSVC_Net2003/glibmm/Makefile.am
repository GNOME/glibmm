BUILT_SOURCES = glibmmconfig.h glibmm-2.4.rc

MAINTAINERCLEANFILES = $(built_sources)

EXTRA_DIST = glibmmconfig.h glibmm.vcproj glibmm-2.4.rc

glibmmconfig.h: $(top_builddir)/glib/glibmmconfig.h
	cp -f $< $@
