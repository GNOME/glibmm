/* Copyright (C) 2004 The glibmm Development Team
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the Free
 * Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#include <glibmm.h>
#include <iostream>


int main(int argc, char** argv)
{
  // This example should be executed like so:
  // ./example the_ini_file.ini
  
  Glib::init();
   
  std::string filepath = "./example.ini";

  Glib::KeyFile keyfile;

  // An exception will be thrown if the file is not there, or if the file is incorrectly formatted:
  try
  {
    const bool loaded = keyfile.load_from_file(filepath);
    if(!loaded)
      std::cerr << "Could not load keyfile." << std::endl;
  }
  catch(const Glib::FileError& ex)
  {
    std::cerr << "Exception while loading key file: " << ex.what() << std::endl;
    return -1;
  }
  catch(const Glib::KeyFileError& ex)
  {
    std::cerr << "Exception while loading key file: " << ex.what() << std::endl;
    return -1;
  }

  // Try to get a value that is not in the file:
  // An exception will be thrown if the value is not in the file:
  try
  {
    const Glib::ustring value = keyfile.get_value("somegroup", "somekey");
    std::cout << "somekey value=" << value << std::endl;
  }
  catch(const Glib::KeyFileError& ex)
  {
    std::cerr << "Exception while getting value: " << ex.what() << std::endl;
    //return -1;
  }

  // Try to get a value that is in the file:
  // An exception will be thrown if the value is not in the file:
  try
  {
    const Glib::ustring value = keyfile.get_value("First Group", "Welcome");
    std::cout << "Welcome value=" << value << std::endl;
  }
  catch(const Glib::KeyFileError& ex)
  {
    std::cerr << "Exception while getting value: " << ex.what() << std::endl;
    //return -1;
  }

  // Try to get a list of integers that is in the file:
  // An exception will be thrown if the value is not in the file:
  try
  {
    typedef std::list<int> type_list_integers;
    const type_list_integers value_list = keyfile.get_integer_list("Another Group", "Numbers");
    for(type_list_integers::const_iterator iter = value_list.begin(); iter != value_list.end(); ++iter)
    {
      const int value = *iter;
      std::cout << "Number list value: item=" << value << std::endl;
    }
  }
  catch(const Glib::KeyFileError& ex)
  {
    std::cerr << "Exception while getting list value: " << ex.what() << std::endl;
    //return -1;
  }

  return 0;
}

