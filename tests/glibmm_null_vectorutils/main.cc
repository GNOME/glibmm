/* Copyright (C) 2011 The gtkmm Development Team
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

#include <glibmm/vectorutils.h>

#include <giomm/credentials.h>
#include <giomm/init.h>

int
main()
{
  Gio::init();
  using CrePtr = Glib::RefPtr<Gio::Credentials>;

  std::vector<CrePtr> v1(
    Glib::ArrayHandler<CrePtr>::array_to_vector(nullptr, Glib::OWNERSHIP_DEEP));
  std::vector<CrePtr> v2(
    Glib::ArrayHandler<CrePtr>::array_to_vector(nullptr, 5, Glib::OWNERSHIP_DEEP));
  std::vector<CrePtr> v3(Glib::ListHandler<CrePtr>::list_to_vector(nullptr, Glib::OWNERSHIP_DEEP));
  std::vector<CrePtr> v4(
    Glib::SListHandler<CrePtr>::slist_to_vector(nullptr, Glib::OWNERSHIP_DEEP));
  std::vector<bool> v5(Glib::ArrayHandler<bool>::array_to_vector(nullptr, Glib::OWNERSHIP_DEEP));
  std::vector<bool> v6(Glib::ArrayHandler<bool>::array_to_vector(nullptr, 5, Glib::OWNERSHIP_DEEP));

  if (v1.empty() && v2.empty() && v3.empty() && v4.empty() && v5.empty() && v6.empty())
  {
    return 0;
  }
  return 1;
}
