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
	dbus/session_bus_service \
	dbus/server_without_bus			\
	dbus/client_bus_listnames \
	iochannel_stream/example	\
	keyfile/example			\
	markup/parser			\
	network/resolver		\
	network/socket-client		\
	network/socket-server		\
	options/example			\
	properties/example		\
	regex/example			\
	settings/settings \
	subprocess/example \
	thread/dispatcher \
	thread/dispatcher2

glibmm_includes = -I$(top_builddir)/glib $(if $(srcdir:.=),-I$(top_srcdir)/glib)
giomm_includes  = -I$(top_builddir)/gio $(if $(srcdir:.=),-I$(top_srcdir)/gio)
local_cppflags  = -I$(top_builddir) $(glibmm_includes) $(giomm_includes)

AM_CPPFLAGS = $(local_cppflags)
AM_CXXFLAGS = $(GIOMM_CFLAGS) $(GLIBMM_WXXFLAGS) -DGLIBMM_DISABLE_DEPRECATED -DGIOMM_DISABLE_DEPRECATED


local_libglibmm = $(top_builddir)/glib/glibmm/libglibmm-$(GLIBMM_API_VERSION).la
local_libgiomm  = $(top_builddir)/gio/giomm/libgiomm-$(GIOMM_API_VERSION).la

LDADD        = $(GLIBMM_LIBS) $(local_libglibmm)
giomm_ldadd  = $(GIOMM_LIBS) $(local_libglibmm) $(local_libgiomm)

child_watch_child_watch_SOURCES  = child_watch/main.cc
iochannel_stream_example_SOURCES =	\
	iochannel_stream/fdstream.cc	\
	iochannel_stream/fdstream.h	\
	iochannel_stream/main.cc

# glibmm examples
compose_example_SOURCES    = compose/main.cc
keyfile_example_SOURCES    = keyfile/main.cc
markup_parser_SOURCES      = markup/parser.cc
options_example_SOURCES    = options/main.cc
properties_example_SOURCES = properties/properties_example.cc
regex_example_SOURCES      = regex/main.cc

thread_dispatcher_SOURCES  = thread/dispatcher.cc
thread_dispatcher2_SOURCES = thread/dispatcher2.cc

# giomm examples
dbus_session_bus_service_SOURCES = dbus/session_bus_service.cc
dbus_session_bus_service_LDADD   = $(giomm_ldadd)
dbus_server_without_bus_SOURCES = dbus/server_without_bus.cc
dbus_server_without_bus_LDADD   = $(giomm_ldadd)
dbus_client_bus_listnames_SOURCES = dbus/client_bus_listnames.cc
dbus_client_bus_listnames_LDADD   = $(giomm_ldadd)

network_resolver_SOURCES   = network/resolver.cc
network_resolver_LDADD     = $(giomm_ldadd)
network_socket_client_SOURCES = network/socket-client.cc
network_socket_client_LDADD   = $(giomm_ldadd)
network_socket_server_SOURCES = network/socket-server.cc
network_socket_server_LDADD   = $(giomm_ldadd)

settings_settings_SOURCES = settings/settings.cc
settings_settings_LDADD   = $(giomm_ldadd)

subprocess_example_SOURCES = subprocess/main.cc
subprocess_example_LDADD   = $(giomm_ldadd)

dist_noinst_SCRIPTS = dbus/session_bus_client.sh
dist_noinst_DATA = \
  keyfile/example.ini \
  markup/test.xml \
  settings/org.gtkmm.demo.gschema.xml
CLEANFILES = settings/gschemas.compiled

settings/gschemas.compiled: $(srcdir)/settings/org.gtkmm.demo.gschema.xml
	$(AM_V_GEN)$(GLIB_COMPILE_SCHEMAS) --targetdir=settings $(srcdir)/settings

all-local: settings/gschemas.compiled
