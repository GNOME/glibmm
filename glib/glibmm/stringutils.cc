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

#include <glibmmconfig.h>
#include <glibmm/stringutils.h>
#include <glibmm/utility.h>
#include <glib.h>
#include <cerrno>
#include <stdexcept>

bool
Glib::str_has_prefix(const std::string& str, const std::string& prefix)
{
  return g_str_has_prefix(str.c_str(), prefix.c_str());
}

bool
Glib::str_has_suffix(const std::string& str, const std::string& suffix)
{
  return g_str_has_suffix(str.c_str(), suffix.c_str());
}

double
Glib::Ascii::strtod(const std::string& str)
{
  std::string::size_type dummy;
  return Glib::Ascii::strtod(str, dummy, 0);
}

double
Glib::Ascii::strtod(
  const std::string& str, std::string::size_type& end_index, std::string::size_type start_index)
{
  if (start_index >= str.size())
  {
    throw std::out_of_range("out of range (strtod): start_index > str.size()");
  }

  const char* const bufptr = str.c_str();
  char* endptr = nullptr;

  const double result = g_ascii_strtod(bufptr + start_index, &endptr);
  const int err_no = errno;

  if (err_no != 0)
  {
    g_return_val_if_fail(err_no == ERANGE, result);

    // Interpret the result in the event of an error:
    if (result > 0.0)
      throw std::overflow_error("overflow (strtod): positive number too large");

    if (result < 0.0)
      throw std::overflow_error("overflow (strtod): negative number too large");

    throw std::underflow_error("underflow (strtod): number too small");
  }

  if (endptr)
    end_index = endptr - bufptr;
  else
    end_index = str.size();

  return result;
}

std::string
Glib::Ascii::dtostr(double d)
{
  char buf[G_ASCII_DTOSTR_BUF_SIZE];

  return g_ascii_dtostr(buf, sizeof(buf), d);
}

std::string
Glib::strescape(const std::string& source)
{
  const auto buf = make_unique_ptr_gfree(g_strescape(source.c_str(), nullptr));
  return buf.get();
}

std::string
Glib::strescape(const std::string& source, const std::string& exceptions)
{
  const auto buf = make_unique_ptr_gfree(g_strescape(source.c_str(), exceptions.c_str()));
  return buf.get();
}

std::string
Glib::strcompress(const std::string& source)
{
  const auto buf = make_unique_ptr_gfree(g_strcompress(source.c_str()));
  return buf.get();
}

Glib::ustring
Glib::strerror(int errnum)
{
  return g_strerror(errnum);
}

Glib::ustring
Glib::strsignal(int signum)
{
  return g_strsignal(signum);
}
