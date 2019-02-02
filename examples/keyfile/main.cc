/* Copyright (C) 2004 The glibmm Development Team
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

#include <glibmm.h>
#include <iostream>

int
main(int, char**)
{
  Glib::init();

  const std::string filepath = "./example.ini";

  auto keyfile = Glib::KeyFile::create();

  // An exception will be thrown if the file is not there, or if the file is incorrectly formatted:
  try
  {
    keyfile->load_from_file(filepath);
  }
  catch (const Glib::Error& ex)
  {
    std::cerr << "Exception while loading key file: " << ex.what() << std::endl;
    return 1;
  }

  // Try to get a value that is not in the file:
  // An exception will be thrown if the value is not in the file:
  try
  {
    const Glib::ustring value = keyfile->get_value("somegroup", "somekey");
    std::cout << "somekey value=" << value << std::endl;
  }
  catch (const Glib::KeyFileError& ex)
  {
    std::cerr << "Exception while getting value: " << ex.what() << std::endl;
  }

  // Try to get a value that is in the file:
  // An exception will be thrown if the value is not in the file:
  try
  {
    const Glib::ustring value = keyfile->get_value("First Group", "Welcome");
    std::cout << "Welcome value=" << value << std::endl;
  }
  catch (const Glib::KeyFileError& ex)
  {
    std::cerr << "Exception while getting value: " << ex.what() << std::endl;
  }

  // Try to get a list of integers that is in the file:
  // An exception will be thrown if the value is not in the file:
  try
  {
    const auto values = keyfile->get_integer_list("Another Group", "Numbers");

    for (const auto& p : values)
      std::cout << "Number list value: item=" << p << std::endl;
  }
  catch (const Glib::KeyFileError& ex)
  {
    std::cerr << "Exception while getting list value: " << ex.what() << std::endl;
  }

  return 0;
}
