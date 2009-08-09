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

lib_LTLIBRARIES = libgiomm-2.4.la

include $(srcdir)/../src/filelist.am
include $(srcdir)/filelist.am
include $(top_srcdir)/build/compile-binding.am

dist_noinst_HEADERS = slot_async.h

local_includes = -I$(top_builddir)/glib $(if $(srcdir:.=),-I$(top_srcdir)/glib)
local_cppflags = $(binding_includes) $(local_includes) $(binding_cppflags)

AM_CPPFLAGS = $(local_cppflags) $(GTHREAD_CFLAGS) $(GIOMM_CFLAGS)
AM_CXXFLAGS = $(GLIBMM_WXXFLAGS)

local_libadd = $(top_builddir)/glib/glibmm/libglibmm-$(GLIBMM_API_VERSION).la

libgiomm_2_4_la_SOURCES = $(binding_sources)
libgiomm_2_4_la_LDFLAGS = -no-undefined -version-info $(LIBGLIBMM_SO_VERSION)
libgiomm_2_4_la_LIBADD  = $(GIOMM_LIBS) $(local_libadd)
