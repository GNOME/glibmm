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
#include <iomanip>
#include <iostream>





int main(int argc, char** argv)
{
  
  typedef std::list<Glib::OptionEntry> type_list_entries;
  type_list_entries list_entries;
  
  Glib::OptionEntry entry1;
  entry1.set_long_name("foo");
  entry1.set_short_name('f');
  
  list_entries.push_back( entry1 );
   
  Glib::OptionContext context;
  //context.add_main_entries(list_entries);
  
  context.parse(argc, argv);


  return 0;
}

