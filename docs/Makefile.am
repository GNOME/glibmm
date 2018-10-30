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

include $(top_srcdir)/glib/src/filelist.am
include $(top_srcdir)/glib/glibmm/filelist.gmake.am
include $(top_srcdir)/gio/src/filelist.gmake.am
include $(top_srcdir)/gio/giomm/filelist.gmake.am

glibmm_files_h = $(filter-out wrap_init.h,$(glibmm_files_all_h))
giomm_files_h  = $(filter-out wrap_init.h,$(giomm_files_all_h))

book_name = $(GLIBMM_MODULE_NAME)
doc_input = $(addprefix $(top_srcdir)/glib/glibmm/,$(glibmm_files_h)) \
            $(addprefix $(top_srcdir)/gio/giomm/,$(giomm_files_h)) \
            $(top_srcdir)/glib/glibmm.h $(top_srcdir)/gio/giomm.h

docimagesdir = $(libdocdir)/images
dist_docimages_DATA = images/gtkmm_logo.gif images/top.gif

include $(top_srcdir)/build/doc-reference.am

dist_noinst_DATA += \
	internal/documentation_generation.txt	\
	internal/gmmproc_internals.txt		\
	internal/using_gmmproc.txt		\
	internal/gtk_entry.dia
