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
 * License along with this library.  If not, see <http://www.gnu.org/licenses/>.
 */
#include <cstdlib>
#include <ctime>

#include <iostream>

#include <glibmm.h>

// Use this line if you want debug output:
// std::ostream& ostr = std::cout;

// This seems nicer and more useful than putting an ifdef around the use of ostr:
std::stringstream debug;
std::ostream& ostr = debug;

const unsigned int magic_limit(5);

void
setup_rand()
{
  static bool setup(false);

  if (!setup)
  {
    setup = true;
    std::srand(std::time(nullptr));
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

std::vector<bool>
cxx_get_bool_array()
{
  return Glib::ArrayHandler<bool>::array_to_vector(
    c_get_bool_array(), magic_limit, Glib::OWNERSHIP_SHALLOW);
}

void
cxx_print_bool_array(const std::vector<bool>& v)
{
  c_print_bool_array(const_cast<gboolean*>(Glib::ArrayHandler<bool>::vector_to_array(v).data()));
}

int
main(int, char**)
{
  Glib::init();

  std::vector<bool> va(cxx_get_bool_array());

  cxx_print_bool_array(va);

  return EXIT_SUCCESS;
}
