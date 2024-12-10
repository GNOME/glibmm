/* Copyright (C) 2007 The glibmm Development Team
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
#include <iomanip>
#include <iostream>

namespace
{

void
show_examples()
{
  using Glib::ustring;

  const double a = 3456.78;
  const double b = 7890.12;
  const int i = int(a / (a + b) * 40.0);

  std::cout << ustring::compose("%1 is lower than %2.", a, b) << std::endl
            << ustring::compose("%2 is greater than %1.", a, b) << std::endl
// ustring::format does only work with std::fixed with MSVC2008 or above.
// See https://bugzilla.gnome.org/show_bug.cgi?id=599340
#if !defined(_MSC_VER) || _MSC_VER >= 1500
            << ustring::compose("%1 € are %3 %% of %2 €.", a, b,
                 ustring::format(std::fixed, std::setprecision(1), a / b * 100.0))
            << std::endl
#endif
            << ustring::compose("a : b = [%1|%2]",
                 ustring::format(std::setfill(L'a'), std::setw(i), ""),
                 ustring::format(std::setfill(L'b'), std::setw(40 - i), ""))
            << std::endl;
}

} // anonymous namespace

int
main(int, char**)
{
  Glib::init();

  show_examples();

  return 0;
}
