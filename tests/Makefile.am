## Copyright (c) 2009, 2010  Openismus GmbH  <http://www.openismus.com/>
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

check_PROGRAMS =			\
	giomm_ioerror/test		\
	giomm_simple/test		\
	glibmm_date/test		\
	glibmm_nodetree/test		\
	glibmm_ustring_compose/test	\
	glibmm_value/test		\
	glibmm_valuearray/test

glibmm_includes = -I$(top_builddir)/glib $(if $(srcdir:.=),-I$(top_srcdir)/glib)
giomm_includes  = -I$(top_builddir)/gio $(if $(srcdir:.=),-I$(top_srcdir)/gio)
local_cppflags  = -I$(top_builddir) $(glibmm_includes) $(giomm_includes)

AM_CPPFLAGS = $(local_cppflags) $(GTHREAD_CFLAGS) $(GIOMM_CFLAGS)
AM_CXXFLAGS = $(GLIBMM_WXXFLAGS)

local_libglibmm = $(top_builddir)/glib/glibmm/libglibmm-$(GLIBMM_API_VERSION).la
local_libgiomm  = $(top_builddir)/gio/giomm/libgiomm-$(GIOMM_API_VERSION).la

LDADD = $(local_libglibmm) $(GLIBMM_LIBS)
giomm_ldadd = $(local_libglibmm) $(local_libgiomm) $(GIOMM_LIBS)

giomm_ioerror_test_SOURCES = giomm_ioerror/main.cc
giomm_ioerror_test_LDADD   = $(giomm_ldadd)
giomm_simple_test_SOURCES  = giomm_simple/main.cc
giomm_simple_test_LDADD    = $(giomm_ldadd)

glibmm_date_test_SOURCES            = glibmm_date/main.cc
glibmm_nodetree_test_SOURCES        = glibmm_nodetree/main.cc
glibmm_ustring_compose_test_SOURCES = glibmm_ustring_compose/main.cc
glibmm_value_test_SOURCES           = glibmm_value/glibmm_value.cc glibmm_value/main.cc
glibmm_valuearray_test_SOURCES      = glibmm_valuearray/main.cc
