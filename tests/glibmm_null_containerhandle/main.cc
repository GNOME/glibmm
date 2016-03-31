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
 * License along with this library; if not, write to the Free
 * Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#include <glibmm/arrayhandle.h>
#include <glibmm/listhandle.h>
#include <glibmm/slisthandle.h>

#include <giomm/credentials.h>
#include <giomm/init.h>

int
main()
{
  Gio::init();
  using CrePtr = Glib::RefPtr<Gio::Credentials>;

  std::vector<CrePtr> v1(Glib::ArrayHandle<CrePtr>(nullptr, Glib::OWNERSHIP_DEEP));
  std::vector<CrePtr> v2(Glib::ArrayHandle<CrePtr>(nullptr, 5, Glib::OWNERSHIP_DEEP));
  std::vector<CrePtr> v3(Glib::ListHandle<CrePtr>(nullptr, Glib::OWNERSHIP_DEEP));
  std::vector<CrePtr> v4(Glib::SListHandle<CrePtr>(nullptr, Glib::OWNERSHIP_DEEP));
  std::vector<bool> v5(Glib::ArrayHandle<bool>(nullptr, Glib::OWNERSHIP_DEEP));
  std::vector<bool> v6(Glib::ArrayHandle<bool>(nullptr, 5, Glib::OWNERSHIP_DEEP));

  if (v1.empty() && v2.empty() && v3.empty() && v4.empty() && v5.empty() && v6.empty())
  {
    return 0;
  }
  return 1;
}
