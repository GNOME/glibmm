/* Copyright (C) 2011 The glibmm Development Team
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
#include <cstdlib>
#include <ctime>

#include <iostream>

#include <glibmm.h>

// Use this line if you want debug output:
// std::ostream& ostr = std::cout;

// This seems nicer and more useful than putting an ifdef around the use of std::cout:
std::stringstream debug;
std::ostream& ostr = debug;

const unsigned int magic_limit(5);

void
setup_rand()
{
  static bool setup(false);

  if (!setup)
  {
    std::srand(std::time(nullptr));
    setup = true;
  }
}

gboolean*
c_get_bool_array()
{
  gboolean* array(static_cast<gboolean*>(g_malloc((magic_limit + 1) * sizeof(gboolean))));

  setup_rand();
  for (unsigned int iter(0); iter < magic_limit; ++iter)
  {
    array[iter] = std::rand() % 2 ? TRUE : FALSE;
  }
  array[magic_limit] = FALSE;
  return array;
}

void
c_print_bool_array(gboolean* array)
{
  for (unsigned int iter(0); iter < magic_limit; ++iter)
  {
    ostr << iter << ": " << (array[iter] ? "TRUE" : "FALSE") << "\n";
  }
}

Glib::ArrayHandle<bool>
cxx_get_bool_array()
{
  return Glib::ArrayHandle<bool>(c_get_bool_array(), magic_limit, Glib::OWNERSHIP_SHALLOW);
}

void
cxx_print_bool_array(const Glib::ArrayHandle<bool>& array)
{
  c_print_bool_array(const_cast<gboolean*>(array.data()));
}

int
main()
{
  Glib::init();

  std::vector<bool> v(cxx_get_bool_array());
  std::list<bool> l(cxx_get_bool_array());
  std::deque<bool> d(cxx_get_bool_array());

  ostr << "vector:\n";
  cxx_print_bool_array(v);
  ostr << "list:\n";
  cxx_print_bool_array(l);
  ostr << "deque:\n";
  cxx_print_bool_array(d);

  return EXIT_SUCCESS;
}
