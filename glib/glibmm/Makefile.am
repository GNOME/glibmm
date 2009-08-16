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

lib_LTLIBRARIES = libglibmm-2.4.la

include $(srcdir)/../src/filelist.am
include $(srcdir)/filelist.am

files_built_cc = $(glibmm_files_built_cc)
files_built_h  = $(glibmm_files_built_h)
files_built_ph = $(glibmm_files_built_ph)
files_extra_cc = $(glibmm_files_extra_cc)
files_extra_h  = $(glibmm_files_extra_h)
files_extra_ph = $(glibmm_files_extra_ph)

include $(top_srcdir)/build/compile-binding.am

local_cppflags = $(binding_includes) $(binding_cppflags) -DGLIBMM_BUILD=1

AM_CPPFLAGS = $(local_cppflags) $(GTHREAD_CFLAGS) $(GLIBMM_CFLAGS)
AM_CXXFLAGS = $(GLIBMM_WXXFLAGS)

libglibmm_2_4_la_SOURCES = $(binding_sources)
libglibmm_2_4_la_LDFLAGS = -no-undefined -version-info $(LIBGLIBMM_SO_VERSION)
libglibmm_2_4_la_LIBADD  = $(GLIBMM_LIBS)
