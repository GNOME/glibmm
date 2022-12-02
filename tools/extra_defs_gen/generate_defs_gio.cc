/* generate_defs_gio.cc
 *
 * Copyright (C) 2007 The gtkmm Development Team
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this library.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "generate_extra_defs.h"
#include <iostream>

#define G_SETTINGS_ENABLE_BACKEND 1
#include <gio/gio.h>
#include <gio/gsettingsbackend.h>

#ifndef G_OS_WIN32
#include <gio/gunixconnection.h>
#include <gio/gunixcredentialsmessage.h>
#include <gio/gunixfdmessage.h>
#include <gio/gunixinputstream.h>
#include <gio/gunixoutputstream.h>
#include <gio/gunixsocketaddress.h>
#endif

int
main(int, char**)
{
  // g_type_init() is deprecated as of 2.36.
  // g_type_init();

  // Until the glib bug https://bugzilla.gnome.org/show_bug.cgi?id=465631
  // (https://gitlab.gnome.org/GNOME/glib/issues/100)
  // is fixed, get_defs() must be called for a GObject before it's
  // called for a GInterface.
  (void)get_defs(G_TYPE_APPLICATION);

  std::cout << get_defs(G_TYPE_ASYNC_RESULT) << get_defs(G_TYPE_ACTION)
            << get_defs(G_TYPE_ACTION_GROUP) << get_defs(G_TYPE_APPLICATION)
            << get_defs(G_TYPE_APP_INFO_MONITOR) << get_defs(G_TYPE_CANCELLABLE)
            << get_defs(G_TYPE_BUFFERED_INPUT_STREAM) << get_defs(G_TYPE_BUFFERED_OUTPUT_STREAM)
            << get_defs(G_TYPE_BYTES_ICON)
            << get_defs(G_TYPE_CHARSET_CONVERTER) << get_defs(G_TYPE_CONVERTER_INPUT_STREAM)
            << get_defs(G_TYPE_CONVERTER_OUTPUT_STREAM) << get_defs(G_TYPE_DATA_INPUT_STREAM)
            << get_defs(G_TYPE_DATA_OUTPUT_STREAM) << get_defs(G_TYPE_DRIVE)
            << get_defs(G_TYPE_FILE) << get_defs(G_TYPE_FILE_ENUMERATOR)
            << get_defs(G_TYPE_FILE_INFO) << get_defs(G_TYPE_FILE_ICON)
            << get_defs(G_TYPE_FILE_MONITOR) << get_defs(G_TYPE_FILENAME_COMPLETER)
            //            << get_defs(G_TYPE_FILE_ATTRIBUTE_INFO_LIST)
            //            << get_defs(G_TYPE_FILE_ATTRIBUTE_MATCHER)
            << get_defs(G_TYPE_FILE_INPUT_STREAM) << get_defs(G_TYPE_FILE_OUTPUT_STREAM)
            << get_defs(G_TYPE_FILTER_INPUT_STREAM) << get_defs(G_TYPE_FILTER_OUTPUT_STREAM)

#ifndef G_OS_WIN32
            << get_defs(G_TYPE_UNIX_CREDENTIALS_MESSAGE) << get_defs(G_TYPE_UNIX_FD_MESSAGE)
            << get_defs(G_TYPE_UNIX_INPUT_STREAM) << get_defs(G_TYPE_UNIX_OUTPUT_STREAM)
            << get_defs(G_TYPE_UNIX_SOCKET_ADDRESS)
#endif

            << get_defs(G_TYPE_INPUT_STREAM) << get_defs(G_TYPE_LIST_MODEL)
            << get_defs(G_TYPE_LIST_STORE) << get_defs(G_TYPE_LOADABLE_ICON)
            << get_defs(G_TYPE_MEMORY_INPUT_STREAM) << get_defs(G_TYPE_MEMORY_OUTPUT_STREAM)
            << get_defs(G_TYPE_MENU) << get_defs(G_TYPE_MENU_MODEL) << get_defs(G_TYPE_MOUNT)
            << get_defs(G_TYPE_MOUNT_OPERATION) << get_defs(G_TYPE_NOTIFICATION)
            << get_defs(G_TYPE_PERMISSION) << get_defs(G_TYPE_PROPERTY_ACTION)
            << get_defs(G_TYPE_PROXY) << get_defs(G_TYPE_PROXY_ADDRESS)
            << get_defs(G_TYPE_PROXY_ADDRESS_ENUMERATOR) << get_defs(G_TYPE_PROXY_RESOLVER)
            << get_defs(G_TYPE_SEEKABLE) << get_defs(G_TYPE_SETTINGS)
            << get_defs(G_TYPE_SETTINGS_BACKEND) << get_defs(G_TYPE_SIMPLE_ASYNC_RESULT)
            << get_defs(G_TYPE_SIMPLE_ACTION) << get_defs(G_TYPE_SIMPLE_IO_STREAM)
            << get_defs(G_TYPE_SUBPROCESS) << get_defs(G_TYPE_SUBPROCESS_LAUNCHER)
            << get_defs(G_TYPE_THEMED_ICON)
            << get_defs(G_TYPE_VOLUME)

            << get_defs(G_TYPE_VOLUME_MONITOR) << get_defs(G_TYPE_ZLIB_COMPRESSOR)
            << get_defs(G_TYPE_ZLIB_DECOMPRESSOR)

            // network IO classes
            << get_defs(G_TYPE_INET_ADDRESS) << get_defs(G_TYPE_INET_SOCKET_ADDRESS)
            << get_defs(G_TYPE_SOCKET_ADDRESS) << get_defs(G_TYPE_SOCKET_ADDRESS_ENUMERATOR)
            << get_defs(G_TYPE_SOCKET_CONNECTABLE) << get_defs(G_TYPE_SRV_TARGET)
            << get_defs(G_TYPE_RESOLVER) << get_defs(G_TYPE_NETWORK_ADDRESS)
            << get_defs(G_TYPE_NETWORK_MONITOR) << get_defs(G_TYPE_NETWORK_SERVICE)
            << get_defs(G_TYPE_SETTINGS) << get_defs(G_TYPE_SETTINGS_SCHEMA)
            << get_defs(G_TYPE_SETTINGS_SCHEMA_KEY) << get_defs(G_TYPE_SETTINGS_SCHEMA_SOURCE)
            << get_defs(G_TYPE_SIMPLE_PERMISSION) << get_defs(G_TYPE_SOCKET)
            << get_defs(G_TYPE_SOCKET_CLIENT) << get_defs(G_TYPE_SOCKET_CONNECTION)
            << get_defs(G_TYPE_TCP_CONNECTION) << get_defs(G_TYPE_TCP_WRAPPER_CONNECTION)
            << get_defs(G_TYPE_TLS_BACKEND) << get_defs(G_TYPE_TLS_CERTIFICATE)
            << get_defs(G_TYPE_TLS_CLIENT_CONNECTION) << get_defs(G_TYPE_TLS_CONNECTION)
            << get_defs(G_TYPE_TLS_DATABASE) << get_defs(G_TYPE_TLS_FILE_DATABASE)
            << get_defs(G_TYPE_TLS_INTERACTION) << get_defs(G_TYPE_TLS_PASSWORD)
            << get_defs(G_TYPE_TLS_SERVER_CONNECTION)
#ifndef G_OS_WIN32
            << get_defs(G_TYPE_UNIX_CONNECTION)
#endif
            << get_defs(G_TYPE_SOCKET_LISTENER) << get_defs(G_TYPE_SOCKET_SERVICE)
            << get_defs(G_TYPE_THREADED_SOCKET_SERVICE)

            // DBus types:
            << get_defs(G_TYPE_DBUS_AUTH_OBSERVER) << get_defs(G_TYPE_DBUS_CONNECTION)
            << get_defs(G_TYPE_DBUS_ERROR) << get_defs(G_TYPE_DBUS_ANNOTATION_INFO)
            << get_defs(G_TYPE_DBUS_ARG_INFO) << get_defs(G_TYPE_DBUS_MENU_MODEL)
            << get_defs(G_TYPE_DBUS_METHOD_INFO) << get_defs(G_TYPE_DBUS_SIGNAL_INFO)
            << get_defs(G_TYPE_DBUS_PROPERTY_INFO) << get_defs(G_TYPE_DBUS_INTERFACE_INFO)
            << get_defs(G_TYPE_DBUS_INTERFACE_SKELETON)
            << get_defs(G_TYPE_DBUS_OBJECT)
            << get_defs(G_TYPE_DBUS_OBJECT_MANAGER)
            << get_defs(G_TYPE_DBUS_OBJECT_MANAGER_CLIENT)
            << get_defs(G_TYPE_DBUS_OBJECT_MANAGER_SERVER)
            << get_defs(G_TYPE_DBUS_OBJECT_PROXY)
            << get_defs(G_TYPE_DBUS_OBJECT_SKELETON)
            << get_defs(G_TYPE_DBUS_NODE_INFO) << get_defs(G_TYPE_DBUS_MESSAGE)
            << get_defs(G_TYPE_DBUS_METHOD_INVOCATION) << get_defs(G_TYPE_DBUS_PROXY)
            << get_defs(G_TYPE_DBUS_SERVER)

            << std::endl;

  return 0;
}
