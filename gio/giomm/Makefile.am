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

lib_LTLIBRARIES = libgiomm-@GIOMM_API_VERSION@.la

include $(srcdir)/../src/filelist.gmake.am
include $(srcdir)/filelist.gmake.am

files_built_cc = $(giomm_files_built_cc)
files_built_h  = $(giomm_files_built_h)
files_built_ph = $(giomm_files_built_ph)
files_extra_cc = $(giomm_files_extra_cc)
files_extra_h  = $(giomm_files_extra_h)
files_extra_ph = $(giomm_files_extra_ph)

include $(top_srcdir)/build/compile-binding.am

local_includes = -I$(top_builddir)/glib $(if $(srcdir:.=),-I$(top_srcdir)/glib)
local_cppflags = $(binding_includes) $(local_includes) $(binding_cppflags) -DGIOMM_BUILD=1

AM_CPPFLAGS = $(local_cppflags) $(GIOMM_CFLAGS)
AM_CXXFLAGS = $(GLIBMM_WXXFLAGS)

local_libadd = $(top_builddir)/glib/glibmm/libglibmm-$(GLIBMM_API_VERSION).la

libgiomm_@GIOMM_API_VERSION@_la_SOURCES = $(binding_sources)
libgiomm_@GIOMM_API_VERSION@_la_LDFLAGS = -no-undefined -version-info $(LIBGLIBMM_SO_VERSION)
libgiomm_@GIOMM_API_VERSION@_la_LIBADD  = $(GIOMM_LIBS) $(local_libadd)
