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
#include <iomanip>
#include <iostream>

int
main(int, char**)
{
  Glib::init();

  /* Reusing one regex pattern: */
  const auto regex = Glib::Regex::create("(a)?(b)");
  std::cout << "Pattern=" << regex->get_pattern() << ", with string=abcd, result=" << std::boolalpha
            << regex->match("abcd") << std::endl;
  std::cout << "Pattern=" << regex->get_pattern() << ", with string=1234, result=" << std::boolalpha
            << regex->match("1234") << std::endl;
  std::cout << std::endl;

  /* Using the static function without a regex instance: */
  std::cout << "Pattern=b* with string=abcd, result=" << std::boolalpha
            << Glib::Regex::match_simple("b*", "abcd") << std::endl;

  return 0;
}
