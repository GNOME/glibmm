/* Copyright (C) 2002 The gtkmm Development Team
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

#include <glibmm/utility.h>

void
Glib::append_canonical_typename(std::string& dest, const char* type_name)
{
  const std::string::size_type offset = dest.size();
  dest += type_name;

  std::string::iterator p = dest.begin() + offset;
  const std::string::iterator pend = dest.end();

  for (; p != pend; ++p)
  {
    if (!(g_ascii_isalnum(*p) || *p == '_' || *p == '-'))
      *p = '+';
  }
}
