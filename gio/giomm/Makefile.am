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

include $(srcdir)/../src/filelist.am

### Separated from $(top_srcdir)/gio/src/filelist.am

if HOST_WINDOWS_NATIVE
giomm_files_arch_hg =
else
if OS_COCOA
giomm_files_arch_hg = $(giomm_files_posix_hg)
else
giomm_files_arch_hg = $(giomm_files_not_mac) $(giomm_files_posix_hg)
endif
endif
giomm_files_used_hg = $(giomm_files_any_hg) $(giomm_files_arch_hg)

giomm_files_hg = \
  $(giomm_files_any_hg) \
  $(giomm_files_posix_hg) \
  $(giomm_files_not_mac)
giomm_files_ccg = $(giomm_files_hg:.hg=.ccg)

### End of separated from $(top_srcdir)/gio/src/filelist.am

include $(srcdir)/filelist.am

# Separated from $(top_srcdir)/gio/giomm/filelist.am
giomm_files_built_ph = $(patsubst %.hg,private/%_p.h,$(giomm_files_used_hg))

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
