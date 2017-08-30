/* Copyright (C) 2003 The glibmm Development Team
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

#include <glibmm/init.h>
#include <glibmm/error.h>
#include <locale>
#include <clocale>
#include <stdexcept>

namespace
{
  bool init_to_users_preferred_locale = true;

} // anonymous namespace

namespace Glib
{
void set_init_to_users_preferred_locale(bool state)
{
  init_to_users_preferred_locale = state;
}

bool get_init_to_users_preferred_locale()
{
  return init_to_users_preferred_locale;
}

void init()
{
  static bool is_initialized = false;

  if (is_initialized)
    return;

  if (init_to_users_preferred_locale)
  {
    try
    {
      // Set the global locale for C++ functions and the locale for C functions
      // to the user-preferred locale.
      std::locale::global(std::locale(""));
    }
    catch (const std::runtime_error& ex)
    {
      g_warning("Can't set the global locale to the user's preferred locale.\n"
        "   %s\n   The environment variable LANG may be wrong.\n", ex.what());
    }
  }
  else
  {
    try
    {
      // Make the C++ locale equal to the C locale.
      std::locale::global(std::locale(std::setlocale(LC_ALL, nullptr)));
    }
    catch (const std::runtime_error& ex)
    {
      g_warning("Can't make the global C++ locale equal to the C locale.\n"
        "   %s\n   C locale = %s\n", ex.what(), std::setlocale(LC_ALL, nullptr));
    }
  }

  // Also calls Glib::wrap_register_init() and Glib::wrap_init().
  Glib::Error::register_init();

  is_initialized = true;
}

} // namespace Glib
