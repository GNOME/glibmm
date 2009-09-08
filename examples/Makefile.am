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

check_PROGRAMS =			\
	child_watch/child_watch		\
	compose/example			\
	iochannel_stream/example	\
	keyfile/example			\
	markup/parser			\
	options/example			\
	properties/example		\
	regex/example			\
	thread/dispatcher		\
	thread/dispatcher2		\
	thread/thread			\
	thread/threadpool

glibmm_includes = -I$(top_builddir)/glib $(if $(srcdir:.=),-I$(top_srcdir)/glib)
giomm_includes  = -I$(top_builddir)/gio $(if $(srcdir:.=),-I$(top_srcdir)/gio)
local_cppflags  = -I$(top_builddir) $(glibmm_includes) $(giomm_includes)

AM_CPPFLAGS = $(local_cppflags) $(GTHREAD_CFLAGS) $(GIOMM_CFLAGS)
AM_CXXFLAGS = $(GLIBMM_WXXFLAGS)

local_libglibmm = $(top_builddir)/glib/glibmm/libglibmm-$(GLIBMM_API_VERSION).la
local_libgiomm  = $(top_builddir)/gio/giomm/libgiomm-$(GIOMM_API_VERSION).la

LDADD        = $(GLIBMM_LIBS) $(local_libglibmm)
giomm_ldadd  = $(GIOMM_LIBS) $(local_libglibmm) $(local_libgiomm)
thread_ldadd = $(GTHREAD_LIBS) $(GLIBMM_LIBS) $(local_libglibmm)

child_watch_child_watch_SOURCES  = child_watch/main.cc
iochannel_stream_example_SOURCES =	\
	iochannel_stream/fdstream.cc	\
	iochannel_stream/fdstream.h	\
	iochannel_stream/main.cc

compose_example_SOURCES    = compose/main.cc
keyfile_example_SOURCES    = keyfile/main.cc
markup_parser_SOURCES      = markup/parser.cc
options_example_SOURCES    = options/main.cc
properties_example_SOURCES = properties/properties_example.cc
regex_example_SOURCES      = regex/main.cc

thread_dispatcher_SOURCES  = thread/dispatcher.cc
thread_dispatcher_LDADD    = $(thread_ldadd)
thread_dispatcher2_SOURCES = thread/dispatcher2.cc
thread_dispatcher2_LDADD   = $(thread_ldadd)
thread_thread_SOURCES      = thread/thread.cc
thread_thread_LDADD        = $(thread_ldadd)
thread_threadpool_SOURCES  = thread/threadpool.cc
thread_threadpool_LDADD    = $(thread_ldadd)

network_io_resolve_SOURCES = network_io/resolve.cc
network_io_resolve_LDADD   = $(giomm_ldadd)
