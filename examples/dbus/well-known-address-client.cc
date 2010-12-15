/* Copyright (C) 2010 The giomm Development Team
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free
 * Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#include <giomm.h>
#include <glibmm.h>
#include <iostream>

// The main loop.
Glib::RefPtr<Glib::MainLoop> loop;

// A main loop idle callback to quit when the main loop is idle.
bool main_loop_idle()
{
  loop->quit();
  return false;
}

// A callback to finish creating a DBusProxy that was asynchronously created
// for the user session's bus and then try to call the well known 'ListNames'
// method.
void dbus_proxy_available(Glib::RefPtr<Gio::AsyncResult>& result)
{
  Glib::RefPtr<Gio::DBusProxy> proxy = Gio::DBusProxy::create_finish(result);

  if(!proxy)
  {
    std::cerr << "The proxy to the user's session bus was not successfully "
      "created." << std::endl;
    loop->quit();
    return;
  }

  // Call the 'ListNames' method and print the results.

  // Connect an idle callback to the main loop to quit when the main loop is
  // idle now that the method call is finished.
  Glib::signal_idle().connect(sigc::ptr_fun(&main_loop_idle));
}

int main(int, char**)
{
  std::locale::global(std::locale(""));
  Gio::init();

  loop = Glib::MainLoop::create();

  // Get the user session bus connection.
  Glib::RefPtr<Gio::DBusConnection> connection =
    Gio::DBusConnection::get_sync(Gio::BUS_TYPE_SESSION);

  // Check for an unavailable connection.
  if (!connection)
  {
    std::cerr << "The user's session bus is not available." << std::endl;
    return 1;
  }

  // Print out the unique name of the connection to the user session bus.
  std::cout << connection->get_unique_name() << std::endl;

  // Create the proxy to the bus asynchronously.
  Gio::DBusProxy::create(connection, "org.freedesktop.DBus",
    "/org/freedesktop/DBus", "org.freedesktop.DBus",
    sigc::ptr_fun(&dbus_proxy_available));

  loop->run();

  return 0;
}
