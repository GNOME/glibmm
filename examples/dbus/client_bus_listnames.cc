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
 * License along with this library.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <giomm.h>
#include <glibmm.h>
#include <iostream>

// The main loop.
Glib::RefPtr<Glib::MainLoop> loop;

// A main loop idle callback to quit when the main loop is idle.
bool
on_main_loop_idle()
{
  loop->quit();
  return false;
}

// A callback to finish creating a DBus::Proxy that was asynchronously created
// for the user session's bus and then try to call the well known 'ListNames'
// method.
void
on_dbus_proxy_available(Glib::RefPtr<Gio::AsyncResult>& result)
{
  const auto proxy = Gio::DBus::Proxy::create_finish(result);

  if (!proxy)
  {
    std::cerr << "The proxy to the user's session bus was not successfully "
                 "created."
              << std::endl;
    loop->quit();
    return;
  }

  try
  {
    // The proxy's call method returns a tuple of the value(s) that the method
    // call produces so just get the tuple as a VariantContainerBase.
    const auto call_result = proxy->call_sync("ListNames");

    // Now extract the single item in the variant container which is the
    // array of strings (the names).
    Glib::Variant<std::vector<Glib::ustring>> names_variant;
    call_result.get_child(names_variant);

    // Get the vector of strings.
    auto names = names_variant.get();

    std::cout << "The names on the message bus are:" << std::endl;

    for (const auto& i : names)
      std::cout << i << "." << std::endl;
  }
  catch (const Glib::Error& error)
  {
    std::cerr << "Got an error: '" << error.what() << "'." << std::endl;
  }

  // Connect an idle callback to the main loop to quit when the main loop is
  // idle now that the method call is finished.
  Glib::signal_idle().connect(sigc::ptr_fun(&on_main_loop_idle));
}

int
main(int, char**)
{
  Gio::init();

  loop = Glib::MainLoop::create();

  // Get the user session bus connection.
  auto connection = Gio::DBus::Connection::get_sync(Gio::DBus::BusType::SESSION);

  // Check for an unavailable connection.
  if (!connection)
  {
    std::cerr << "The user's session bus is not available." << std::endl;
    return 1;
  }

  // Create the proxy to the bus asynchronously.
  Gio::DBus::Proxy::create(connection, "org.freedesktop.DBus", "/org/freedesktop/DBus",
    "org.freedesktop.DBus", sigc::ptr_fun(&on_dbus_proxy_available));

  loop->run();

  return 0;
}
