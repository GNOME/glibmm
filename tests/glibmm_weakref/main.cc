/* Copyright (C) 2015 The glibmm Development Team
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
 * License along with this library. If not, see <http://www.gnu.org/licenses/>.
 */

#include <cstring>
#include <giomm.h> //There is no class derived from Glib::Object in glibmm
#include <glibmm.h>
#include <iostream>
#include <utility> // std::move

int
main(int, char**)
{
  Glib::init();
  bool success = true;

  // A Glib::WeakRef cannot be created from a Glib::RefPtr<Glib::Bytes>,
  // because Glib::Bytes is not derived from Glib::ObjectBase.
  // const int bdata = 1234;
  // Glib::RefPtr<Glib::Bytes> bytes = Glib::Bytes::create(&bdata, sizeof bdata);
  // Glib::WeakRef<Glib::Bytes> weakbytes = bytes; // does not compile

  // Gio::MemoryInputStream
  Glib::RefPtr<Gio::MemoryInputStream> memstream1 = Gio::MemoryInputStream::create();
  const char data[] = "Some arbitrary data";
  memstream1->add_data(data, sizeof data, Gio::MemoryInputStream::SlotDestroyData());

  // Downcast copy, followed by upcast.
  Glib::WeakRef<Gio::MemoryInputStream> weakmemstream1 = memstream1;
  Glib::WeakRef<Gio::InputStream> weakstream1 = weakmemstream1;
  Glib::WeakRef<Gio::MemoryInputStream> weakmemstream2 =
    Glib::WeakRef<Gio::MemoryInputStream>::cast_dynamic(weakstream1);
  Glib::RefPtr<Gio::MemoryInputStream> memstream2 = weakmemstream2.get();
  if (memstream2)
  {
    char buffer[200];
    gsize bytes_read = 0;
    try
    {
      memstream2->read_all(buffer, sizeof buffer, bytes_read);
      std::cout << buffer << std::endl;
      success &= std::strcmp(buffer, data) == 0;
    }
    catch (const Glib::Error& ex)
    {
      std::cout << "Error reading from memory stream: " << ex.what() << std::endl;
      success = false;
    }
  }
  else
  {
    std::cout << "!memstream2" << std::endl;
    success = false;
  }

  // Move construction.
  Glib::WeakRef<Gio::MemoryInputStream> weakmemstream3(std::move(weakmemstream1));
  if (weakmemstream1.get() || !weakmemstream3.get())
  {
    success = false;
    if (weakmemstream1.get())
      std::cout << "weakmemstream1 || !weakmemstream3: weakmemstream1" << std::endl;
    if (!weakmemstream3.get())
      std::cout << "weakmemstream1 || !weakmemstream3: !weakmemstream3" << std::endl;
  }
  else
  {
    // Move assignment.
    weakmemstream2 = std::move(weakmemstream3);
    if (!weakmemstream2 || weakmemstream3)
    {
      success = false;
      if (!weakmemstream2.get())
        std::cout << "!weakmemstream2 || weakmemstream3: !weakmemstream2" << std::endl;
      if (weakmemstream3.get())
        std::cout << "!weakmemstream2 || weakmemstream3: weakmemstream3" << std::endl;
    }
    else
    {
      // Downcast move, followed by upcast.
      weakstream1 = std::move(weakmemstream2);
      weakmemstream1 = Glib::WeakRef<Gio::MemoryInputStream>::cast_dynamic(weakstream1);
      if (weakmemstream2 || !weakmemstream1)
      {
        success = false;
        if (weakmemstream2)
          std::cout << "weakmemstream2 || !weakmemstream1: weakmemstream2" << std::endl;
        if (!weakmemstream1)
          std::cout << "weakmemstream2 || !weakmemstream1: !weakmemstream1" << std::endl;
      }
    }
  }

  // Gio::SimpleAction
  Glib::RefPtr<Gio::SimpleAction> action1 = Gio::SimpleAction::create("Action1");

  Glib::ustring name = action1->get_name();
  std::cout << "The name is '" << name << "'." << std::endl;
  success &= name == "Action1";

  Glib::WeakRef<Gio::SimpleAction> weakaction1 = action1;
  Glib::WeakRef<Gio::SimpleAction> weakaction2 = weakaction1;

  // A second RefPtr
  Glib::RefPtr<Gio::SimpleAction> action2 = weakaction1.get();
  if (action2)
  {
    name = action2->get_name();
    std::cout << "The name is '" << name << "'." << std::endl;
    success &= name == "Action1";
  }
  else
  {
    std::cout << "!action2" << std::endl;
    success = false;
  }

  weakaction1.reset();
  if (weakaction1.get())
  {
    std::cout << "weakaction1" << std::endl;
    success = false;
  }

  action2 = weakaction2.get();
  if (action2)
  {
    name = action2->get_name();
    std::cout << "The name is '" << name << "'." << std::endl;
    success &= name == "Action1";
  }
  else
  {
    std::cout << "!action2" << std::endl;
    success = false;
  }

  // Reset one of the RefPtrs. One remains.
  action1.reset();
  action2 = weakaction2.get();
  if (action2)
  {
    name = action2->get_name();
    std::cout << "The name is '" << name << "'." << std::endl;
    success &= name == "Action1";
  }
  else
  {
    std::cout << "!action2" << std::endl;
    success = false;
  }

  // Reset the other RefPtr as well.
  action2.reset();
  if (weakaction2.get())
  {
    std::cout << "weakaction2" << std::endl;
    success = false;
  }

  return success ? EXIT_SUCCESS : EXIT_FAILURE;
}
