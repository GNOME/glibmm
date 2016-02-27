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

ACLOCAL_AMFLAGS	= -I build ${ACLOCAL_FLAGS}
DISTCHECK_CONFIGURE_FLAGS = --enable-warnings=fatal

if MAINTAINER_MODE
src_subdirs = glib/src gio/src
else
src_subdirs =
endif
if ENABLE_DOCUMENTATION
doc_subdirs = docs
else
doc_subdirs =
endif
SUBDIRS = tools $(src_subdirs) glib/glibmm gio/giomm tests examples $(doc_subdirs)

glibmm_includedir = $(includedir)/$(GLIBMM_MODULE_NAME)
glibmm_include_HEADERS = glib/glibmm.h
glibmm_libincludedir = $(libdir)/$(GLIBMM_MODULE_NAME)/include
nodist_glibmm_libinclude_HEADERS = glib/glibmmconfig.h

giomm_includedir = $(includedir)/$(GIOMM_MODULE_NAME)
giomm_include_HEADERS = gio/giomm.h
giomm_libincludedir = $(libdir)/$(GIOMM_MODULE_NAME)/include
nodist_giomm_libinclude_HEADERS = gio/giommconfig.h

pkgconfigdir = $(libdir)/pkgconfig
nodist_pkgconfig_DATA = glib/$(GLIBMM_MODULE_NAME).pc gio/$(GIOMM_MODULE_NAME).pc

include $(srcdir)/MSVC_Net2013/filelist.am

text_files = COPYING.tools README.SUN README.win32
msvc_files = $(addprefix MSVC_Net2013/,$(msvc_net2013_data))

dist_noinst_DATA = $(text_files) $(msvc_files)
dist_noinst_SCRIPTS = autogen.sh

DISTCLEANFILES = $(filter %mmconfig.h,$(msvc_files))

# Auto-generate the ChangeLog file from the git log on make dist
include $(top_srcdir)/build/dist-changelog.am

reformat:
if HAVE_CLANG_FORMAT
	$(CLANG_FORMAT) -i `find . -name "*.h"`
	$(CLANG_FORMAT) -i `find . -name "*.cc"`
else
	$(error clang-format was not not found during configure.)
endif
