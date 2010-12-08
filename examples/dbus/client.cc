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
#include <iostream>

int main(int, char**)
{
  std::locale::global(std::locale(""));
  Gio::init();

  // Get the user session bus connection.
  Glib::RefPtr<Gio::DBusConnection> connection =
    Gio::DBusConnection::get_sync(Gio::BUS_TYPE_SESSION);

  // Print out the unique name of the connection to the user session bus.
  std::cout << connection->get_unique_name() << std::endl;

  return 0;
}
