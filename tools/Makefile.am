## Copyright (c) 2009  Openismus GmbH  <http://www.openismus.com/>
##
## This file is part of glibmm.
##
## glibmm is free software: you can redistribute it and/or modify it
## under the terms of the GNU Lesser General Public License as published
## by the Free Software Foundation, either version 2.1 of the License,
## or (at your option) any later version.
##
## glibmm is distributed in the hope that it will be useful, but
## WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
## See the GNU Lesser General Public License for more details.
##
## You should have received a copy of the GNU Lesser General Public License
## along with this library.  If not, see <http://www.gnu.org/licenses/>.

AUTOMAKE_OPTIONS = subdir-objects

include $(srcdir)/m4/filelist.am
include $(srcdir)/pm/filelist.am

# TODO: All these Perl scripts and M4 files are architecture-independent
# and should probably go somewhere below $(pkgdatadir) instead.
gmmproc_bindir = $(libdir)/$(GLIBMM_MODULE_NAME)/proc
gmmproc_m4dir  = $(gmmproc_bindir)/m4
gmmproc_pmdir  = $(gmmproc_bindir)/pm

gmmproc_bin_SCRIPTS  = gmmproc generate_wrap_init.pl
dist_gmmproc_m4_DATA = $(files_codegen_m4:%=m4/%)
dist_gmmproc_pm_DATA = $(files_codegen_pm:%=pm/%)

dist_noinst_SCRIPTS = enum.pl

noinst_PROGRAMS = extra_defs_gen/generate_defs_glib extra_defs_gen/generate_defs_gio
lib_LTLIBRARIES = extra_defs_gen/libglibmm_generate_extra_defs-2.68.la

extradefs_includedir      = $(includedir)/$(GLIBMM_MODULE_NAME)/glibmm_generate_extra_defs
extradefs_include_HEADERS = extra_defs_gen/generate_extra_defs.h

extradefs_ldflags = -no-undefined -version-info $(LIBGLIBMM_SO_VERSION)

extra_defs_gen_libglibmm_generate_extra_defs_2_68_la_SOURCES = extra_defs_gen/generate_extra_defs.cc
extra_defs_gen_libglibmm_generate_extra_defs_2_68_la_LDFLAGS = $(extradefs_ldflags)
extra_defs_gen_libglibmm_generate_extra_defs_2_68_la_LIBADD  = $(GLIBMM_LIBS)

extra_defs_gen_generate_defs_glib_SOURCES = extra_defs_gen/generate_defs_glib.cc
extra_defs_gen_generate_defs_glib_LDADD   = $(GLIBMM_LIBS) $(lib_LTLIBRARIES)

extra_defs_gen_generate_defs_gio_SOURCES = extra_defs_gen/generate_defs_gio.cc
extra_defs_gen_generate_defs_gio_LDADD   = $(GIOMM_LIBS) $(lib_LTLIBRARIES)

AM_CPPFLAGS = -I$(top_builddir) $(GIOMM_CFLAGS)
AM_CXXFLAGS = $(GLIBMM_WXXFLAGS)

EXTRA_DIST = defs_gen/definitions.py \
  defs_gen/defsparser.py \
  defs_gen/enumextract.py \
  defs_gen/h2def.py \
  defs_gen/scmexpr.py \
  defs_gen/docenumdefs.py \
  defs_gen/docextract.py \
  defs_gen/docextract_to_xml.py

# Instruct GNU make to delete the targets of a rule after it failed, in
# order to avoid the complication of handling that situation manually.
.DELETE_ON_ERROR:
